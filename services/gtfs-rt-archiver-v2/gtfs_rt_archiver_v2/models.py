import pendulum
from pydantic import BaseModel, AnyHttpUrl


class FetchTask(BaseModel):
    tick: pendulum.DateTime
    n: int
    url: AnyHttpUrl
