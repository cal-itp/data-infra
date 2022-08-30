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
from sqlalchemy.sql import Select
from typing import Annotated, Any, ClassVar, Dict, List, Literal, Optional, Union

import pendulum
from pydantic import BaseModel, Field, validator
from sqlalchemy import create_engine, MetaData, Table, select


# Taken from the calitp repo which we can't install because of deps issue
def get_engine(project, max_bytes=None):
    max_bytes = 5_000_000_000 if max_bytes is None else max_bytes

    # Note that we should be able to add location as a uri parameter, but
    # it is not being picked up, so passing as a separate argument for now.
    return create_engine(
        f"bigquery://{project}/?maximum_bytes_billed={max_bytes}",
        location="us-west2",
        credentials_path=os.environ.get("BIGQUERY_KEYFILE_LOCATION"),
    )


class FileFormat(str, Enum):
    csv = "csv"
    geojson = "geojson"
    geojsonl = "geojsonl"
    json = "json"
    jsonl = "jsonl"


class TileFormat(str, Enum):
    mbtiles = "mbtiles"
    pbf = "pbf"


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

    @property
    def select(self) -> Select:
        engine = get_engine(self.database)
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
    # test_metadata is optional because singular tests (custom defined) do not have test_metadata attribute
    # for example: https://github.com/dbt-labs/dbt-docs/blob/main/src/app/services/graph.service.js#L340
    # ^ singular test is specifically identified by not having the test_metadata attribute
    test_metadata: Optional[TestMetadata]


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

    def hive_path(
        self, exposure: "Exposure", model: str, bucket: str, dt: pendulum.DateTime
    ):
        entity_name_parts = [
            slugify(exposure.name, separator="_"),
            model,
        ]
        return os.path.join(
            bucket,
            "__".join(entity_name_parts),
            f"dt={dt.in_tz('utc').to_date_string()}",
            f"ts={dt.in_tz('utc').to_iso8601_string()}",
            self.filename(model),
        )


class TilesDestination(GcsDestination):
    """
    For tile server destinations, each depends_on becomes
    a tile layer.
    """

    type: Literal["tiles"]
    tile_format: TileFormat
    geo_column: str
    metadata_columns: Optional[List[str]]
    layer_names: List[str]

    def tile_filename(self, model):
        return f"{model}.{self.tile_format.value}"

    def tiles_hive_path(self, exposure: "Exposure", model: str, bucket: str):
        table_name = (
            f'{slugify(exposure.name, separator="_")}__{self.tile_format.value}'
        )
        return os.path.join(
            bucket,
            table_name,
            *self.hive_partitions,
            self.tile_filename(model),
        )


class CkanResourceMeta(BaseModel):
    id: str
    description: Optional[str]


class CkanDestination(GcsDestination):
    _instances: ClassVar[List["CkanDestination"]] = []
    type: Literal["ckan"]
    url: str
    resources: Dict[str, CkanResourceMeta]

    def __init__(self, **kwargs):
        super(CkanDestination, self).__init__(**kwargs)
        self._instances.append(self)


Destination = Annotated[
    Union[CkanDestination, TilesDestination, GcsDestination],
    Field(discriminator="type"),
]


class ExposureMeta(BaseModel):
    methodology: Optional[str]
    coordinate_system_espg: Optional[str]
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
    # TODO: we should validate that model names do not conflict with
    #  file format names since they are used as entity names in hive partitions
    depends_on: NodeDeps
    meta: Optional[ExposureMeta]

    @validator("meta")
    def must_provide_layer_names_if_tiles(cls, v, values):
        if v:
            for dest in v.destinations:
                if isinstance(dest, TilesDestination):
                    assert len(dest.layer_names) == len(
                        values["depends_on"].nodes
                    ), "must provide one layer name per depends_on"
        return v


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
