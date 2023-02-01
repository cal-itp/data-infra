import pendulum
from pydantic import AnyHttpUrl, BaseModel


class FetchTask(BaseModel):
    tick: pendulum.DateTime
    n: int
    url: AnyHttpUrl
