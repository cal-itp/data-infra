"""
Built off the starting point of https://guitton.co/posts/dbt-artifacts
"""
import json
import os
import yaml
from datetime import datetime
from enum import Enum
from pathlib import Path
from slugify import slugify
from typing import Annotated, Any, ClassVar, Dict, List, Literal, Optional, Tuple, Union

import pendulum
from pydantic import BaseModel, Field
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
    macros: List[str]
    nodes: List[str]

    @property
    def resolved_nodes(self) -> List["BaseNode"]:
        return [BaseNode._instances[node] for node in self.nodes]


class NodeConfig(BaseModel):
    alias: Optional[str]
    schema_: str = Field(None, alias="schema")
    materialized: Optional[DbtMaterializationType]


class Column(BaseModel):
    name: str
    description: Optional[str]
    meta: Optional[Dict[str, Any]]
    parent: "BaseNode" = None  # this is set after the fact

    @property
    def publish(self) -> bool:
        return not self.meta.get("publish.ignore", False)

    @property
    def tests(self) -> List[str]:
        return [
            node.name
            for name, node in BaseNode._instances.items()
            if node.resource_type == DbtResourceType.test
            and self.parent.unique_id in node.depends_on.nodes
            and self.name == node.test_metadata.kwargs.get("column_name")
        ]

    def docblock(self, prefix="") -> str:
        return f"""
{{% docs {prefix}{self.name} %}}
{self.description}
{{% enddocs %}}
"""

    def yaml(self, include_description=True, extras={}) -> str:
        include = {
            "name",
        }
        if include_description:
            include += "description"
        return yaml.dump([{**self.dict(include=include), **extras}], sort_keys=False)


class BaseNode(BaseModel):
    _instances: ClassVar[Dict[str, "BaseNode"]] = {}
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
        super(BaseNode, self).__init__(**kwargs)
        self._instances[self.unique_id] = self
        for column in self.columns.values():
            column.parent = self

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


class Model(BaseNode):
    resource_type: Literal[DbtResourceType.model]


class Source(BaseNode):
    resource_type: Literal[DbtResourceType.source]


class TestMetadata(BaseModel):
    name: str
    kwargs: Dict[str, Union[str, List, Dict]]


class Test(BaseNode):
    resource_type: Literal[DbtResourceType.test]
    test_metadata: TestMetadata


Node = Annotated[
    Union[Model, Test],
    Field(discriminator="resource_type"),
]


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
    methodology: Optional[str]
    destinations: List[Destination] = []


class Exposure(BaseModel):
    fqn: List[str]
    unique_id: str
    package_name: str
    path: Path
    name: str
    description: str
    type: ExposureType
    url: Optional[str]
    depends_on: NodeDeps
    meta: Optional[ExposureMeta]


class Manifest(BaseModel):
    nodes: Dict[str, Node]
    sources: Dict[str, Source]
    macros: Dict
    docs: Dict
    exposures: Dict[str, Exposure]


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
