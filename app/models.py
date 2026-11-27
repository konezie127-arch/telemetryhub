from datetime import datetime

from pydantic import BaseModel, Field


class ReadingIn(BaseModel):
    sensor_id: str = Field(min_length=1, max_length=64)
    type: str = Field(min_length=1, max_length=32)
    value: float
    unit: str = Field(min_length=1, max_length=16)
    timestamp: datetime | None = None


class ReadingOut(ReadingIn):
    id: int
    timestamp: datetime


class Stats(BaseModel):
    sensor_id: str
    count: int
    min: float
    max: float
    avg: float
