import pendulum
from pydantic import BaseModel, validator, AnyHttpUrl


class Tick(BaseModel):
    dt: pendulum.DateTime

    @validator("dt")
    def must_tick_every_20_seconds(cls, v):
        assert v.second % 20 == 0
        return v


class FetchTask(BaseModel):
    tick: Tick
    n: int
    url: AnyHttpUrl
