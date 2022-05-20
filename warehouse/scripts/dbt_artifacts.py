"""
Built off the starting point of https://guitton.co/posts/dbt-artifacts
"""
import json
import os
from datetime import datetime
from enum import Enum
from pathlib import Path
from slugify import slugify
from typing import Annotated, Any, ClassVar, Dict, List, Literal, Optional, Tuple, Union

import pendulum
from pydantic import BaseModel, Field, validator
from sqlalchemy import MetaData, Table, select


class FileFormat(str, Enum):
    csv = "csv"
    geojson = "geojson"
    json = "json"
    jsonl = "jsonl"
    mbtiles = "mbtiles"


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
    schema_: str = Field(None, alias="schema")
    materialized: Optional[DbtMaterializationType]


class Column(BaseModel):
    name: str
    description: Optional[str]
    meta: Dict[str, Any]

    @property
    def publish(self):
        return not self.meta.get("publish.ignore", False)


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
    columns: Dict[str, Column]
    meta: Optional[Dict]

    def __init__(self, **kwargs):
        super(Node, self).__init__(**kwargs)
        self._instances[self.unique_id] = self

    @property
    def table_name(self):
        return self.config.alias or self.name

    @property
    def schema_table(self):
        return f"{str(self.schema_)}.{self.table_name}"

    def sqlalchemy_table(self, engine):
        return Table(self.schema_table, MetaData(bind=engine), autoload=True)

    def select(self, engine):
        columns = [
            c
            for c in self.sqlalchemy_table(engine).columns
            if c.name not in self.columns or self.columns[c.name].publish
        ]
        return select(columns=columns)


class ExposureType(str, Enum):
    dashboard = "dashboard"
    notebook = "notebook"
    analysis = "analysis"
    ml = "ml"
    application = "application"


class Owner(BaseModel):
    name: Optional[str]
    email: str


class GcsDestination(BaseModel):
    type: Literal["gcs"]
    bucket: str
    format: FileFormat

    def filename(self, model: str):
        return f"{model}.{self.format.value}"

    def hive_partitions(
        self, model: str, dt: pendulum.DateTime = pendulum.now()
    ) -> Tuple[str, str]:
        return (
            f"dt={dt.to_date_string()}",
            self.filename(model),
        )

    def hive_path(self, exposure: "Exposure", model: str, bucket: str):
        return os.path.join(
            bucket,
            f"{slugify(exposure.name, separator='_')}__{model}",
            *self.hive_partitions(model),
        )


class TileServerDestination(GcsDestination):
    type: Literal["tile_server"]
    url: str
    format: FileFormat


class CkanDestination(GcsDestination):
    _instances: ClassVar[List["CkanDestination"]] = []
    type: Literal["ckan"]
    url: str
    ids: Dict[str, str]

    def __init__(self, **kwargs):
        super(CkanDestination, self).__init__(**kwargs)
        self._instances.append(self)


Destination = Annotated[
    Union[CkanDestination, TileServerDestination, GcsDestination],
    Field(discriminator="type"),
]


class ExposureMeta(BaseModel):
    destinations: List[Destination] = []


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
