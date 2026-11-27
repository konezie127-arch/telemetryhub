import os
import sqlite3
from contextlib import contextmanager


def get_db_path() -> str:
    return os.getenv("DB_PATH", "data/telemetry.db")


@contextmanager
def get_conn():
    path = get_db_path()
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db() -> None:
    with get_conn() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS readings (
                id        INTEGER PRIMARY KEY AUTOINCREMENT,
                sensor_id TEXT NOT NULL,
                type      TEXT NOT NULL,
                value     REAL NOT NULL,
                unit      TEXT NOT NULL,
                timestamp TEXT NOT NULL
            )
            """
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_sensor_ts ON readings(sensor_id, timestamp)"
        )
