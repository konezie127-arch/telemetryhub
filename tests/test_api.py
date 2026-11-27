import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.setenv("DB_PATH", str(tmp_path / "test.db"))
    with TestClient(app) as c:  # le "with" déclenche le lifespan (création de la table)
        yield c


def reading(**overrides):
    data = {"sensor_id": "temp-01", "type": "temperature", "value": 21.5, "unit": "C"}
    data.update(overrides)
    return data


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ko"}


def test_version(client):
    r = client.get("/version")
    assert r.status_code == 200
    assert "version" in r.json() and "git_sha" in r.json()


def test_create_reading_ok(client):
    r = client.post("/readings", json=reading())
    assert r.status_code == 201
    assert r.json()["sensor_id"] == "temp-01"


def test_create_reading_invalid(client):
    r = client.post("/readings", json=reading(value="abc"))
    assert r.status_code == 422


def test_latest_unknown_sensor(client):
    assert client.get("/sensors/nope/latest").status_code == 404


def test_stats(client):
    for v in (10.0, 20.0, 30.0):
        client.post("/readings", json=reading(value=v))
    s = client.get("/sensors/temp-01/stats").json()
    assert s["count"] == 3
    assert s["min"] == 10.0 and s["max"] == 30.0 and s["avg"] == 20.0
