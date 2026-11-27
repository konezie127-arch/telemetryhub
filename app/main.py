import os
from contextlib import asynccontextmanager
from datetime import UTC, datetime

from fastapi import FastAPI, HTTPException, Query

from app import db
from app.models import ReadingIn, ReadingOut, Stats


@asynccontextmanager
async def lifespan(app: FastAPI):
    db.init_db()  # crée la table au démarrage
    yield


app = FastAPI(title="TelemetryHub", lifespan=lifespan)


def row_to_reading(row) -> ReadingOut:
    return ReadingOut(
        id=row["id"],
        sensor_id=row["sensor_id"],
        type=row["type"],
        value=row["value"],
        unit=row["unit"],
        timestamp=datetime.fromisoformat(row["timestamp"]),
    )


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/version")
def version():
    # Injectées au build de l'image : visibles en démo de mise à jour / rollback
    return {
        "version": os.getenv("APP_VERSION", "dev"),
        "git_sha": os.getenv("GIT_SHA", "local"),
    }


@app.post("/readings", response_model=ReadingOut, status_code=201)
def create_reading(reading: ReadingIn):
    #ts = reading.timestamp or datetime.now(timezone.utc)
    ts = reading.timestamp or datetime.now(UTC)
    with db.get_conn() as conn:
        cur = conn.execute(
            "INSERT INTO readings (sensor_id, type, value, unit, timestamp) "
            "VALUES (?, ?, ?, ?, ?)",
            (reading.sensor_id, reading.type, reading.value, reading.unit, ts.isoformat()),
        )
        row = conn.execute("SELECT * FROM readings WHERE id = ?", (cur.lastrowid,)).fetchone()
    return row_to_reading(row)


@app.get("/readings", response_model=list[ReadingOut])
def list_readings(sensor_id: str | None = None, limit: int = Query(50, ge=1, le=500)):
    query, params = "SELECT * FROM readings", []
    if sensor_id:
        query += " WHERE sensor_id = ?"
        params.append(sensor_id)
    query += " ORDER BY timestamp DESC LIMIT ?"
    params.append(limit)
    with db.get_conn() as conn:
        rows = conn.execute(query, params).fetchall()
    return [row_to_reading(r) for r in rows]


@app.get("/sensors/{sensor_id}/latest", response_model=ReadingOut)
def latest(sensor_id: str):
    with db.get_conn() as conn:
        row = conn.execute(
            "SELECT * FROM readings WHERE sensor_id = ? ORDER BY timestamp DESC LIMIT 1",
            (sensor_id,),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Capteur inconnu")
    return row_to_reading(row)


@app.get("/sensors/{sensor_id}/stats", response_model=Stats)
def stats(sensor_id: str):
    with db.get_conn() as conn:
        row = conn.execute(
            "SELECT COUNT(*) c, MIN(value) mn, MAX(value) mx, AVG(value) av "
            "FROM readings WHERE sensor_id = ?",
            (sensor_id,),
        ).fetchone()
    if row["c"] == 0:
        raise HTTPException(status_code=404, detail="Capteur inconnu")
    return Stats(sensor_id=sensor_id, count=row["c"], min=row["mn"], max=row["mx"], avg=row["av"])
