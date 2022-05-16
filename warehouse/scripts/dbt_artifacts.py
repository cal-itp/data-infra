"""
Built off the starting point of https://guitton.co/posts/dbt-artifacts
"""
import json
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Annotated, ClassVar, Dict, List, Literal, Optional, Union

from pydantic import BaseModel, Field, validator


class DbtResourceType(str, Enum):
    model = "model"
    analysis = "analysis"
    test = "test"
    operation = "operation"
    seed = "seed"
    source = "source"


class DbtMaterializationType(str, Enum):
    table = "table"
    view = "view"
    incremental = "incremental"
    ephemeral = "ephemeral"
    seed = "seed"
    test = "test"


class NodeDeps(BaseModel):
    nodes: List[str]


class NodeConfig(BaseModel):
    alias: Optional[str]
    _schema: str = Field(None, alias="schema")
    materialized: Optional[DbtMaterializationType]


class Node(BaseModel):
    _instances: ClassVar[Dict[str, "Node"]] = {}
    unique_id: str
    path: Path
    database: str
    schema_: str = Field(None, alias="schema")
    name: str
    resource_type: DbtResourceType
    description: str
    depends_on: Optional[NodeDeps]
    config: NodeConfig

    def __init__(self, **kwargs):
        super(Node, self).__init__(**kwargs)
        self._instances[(self.resource_type, self.name)] = self

    @property
    def schema_table(self):
        return f"{str(self.schema_)}.{self.config.alias or self.name}"


class ExposureType(str, Enum):
    dashboard = "dashboard"
    notebook = "notebook"
    analysis = "analysis"
    ml = "ml"
    application = "application"


class Owner(BaseModel):
    name: Optional[str]
    email: str


class GCSConfig(BaseModel):
    type: Literal["gcs_bucket"]
    path: str


class TileServerConfig(BaseModel):
    type: Literal["tile_server"]
    url: str


class CkanConfig(BaseModel):
    _instances: ClassVar[List["CkanConfig"]] = []
    type: Literal["ckan"]
    url: str
    ids: Dict[str, str]

    def __init__(self, **kwargs):
        super(CkanConfig, self).__init__(**kwargs)
        self._instances.append(self)


Destination = Annotated[
    Union[CkanConfig, TileServerConfig, GCSConfig], Field(discriminator="type")
]


class ExposureMeta(BaseModel):
    destinations: Optional[List[Destination]]


class Exposure(BaseModel):
    fqn: List[str]
    unique_id: str
    package_name: str
    path: Path
    name: str
    type: ExposureType
    url: Optional[str]
    depends_on: NodeDeps
    meta: Optional[ExposureMeta]


class Manifest(BaseModel):
    nodes: Dict[str, Node]
    sources: Dict[str, Node]
    macros: Dict
    docs: Dict
    exposures: Dict[str, Exposure]

    @validator("nodes", "sources")
    def filter(cls, val):
        return {
            k: v
            for k, v in val.items()
            if v.resource_type.value in ("model", "seed", "source")
        }


class TimingInfo(BaseModel):
    name: str
    started_at: Optional[datetime]
    completed_at: Optional[datetime]


class RunResult(BaseModel):
    status: str
    timing: List[TimingInfo]
    thread_id: str
    execution_time: int  # seconds
    adapter_response: Dict


class RunResults(BaseModel):
    metadata: Dict
    results: List[RunResult]


# mainly just to test that these models work
if __name__ == "__main__":
    paths = [
        ("./target/manifest.json", Manifest),
        ("./target/run_results.json", RunResults),
    ]

    for path, model in paths:
        with open(path) as f:
            model(**json.load(f))
            print(f"{path} is a valid {model.__name__}!", flush=True)
