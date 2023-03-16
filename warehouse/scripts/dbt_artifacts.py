"""
Built off the starting point of https://guitton.co/posts/dbt-artifacts
"""
import abc
import json
import os
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Annotated, Any, ClassVar, Dict, List, Literal, Optional, Union

import humanize
import pendulum
import yaml
from catalog import Catalog, CatalogTable
from pydantic import BaseModel, Field, constr, validator
from slugify import slugify
from sqlalchemy import MetaData, Table, create_engine, select
from sqlalchemy.sql import Select


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
    nodes: Optional[List[str]]  # does not exist on seeds

    @property
    def resolved_nodes(self) -> List["BaseNode"]:
        return [BaseNode._instances[node] for node in self.nodes] if self.nodes else []


class NodeConfig(BaseModel):
    alias: Optional[str]
    schema_: str = Field(None, alias="schema")
    materialized: Optional[DbtMaterializationType]


class Column(BaseModel):
    name: str
    description: Optional[str]
    meta: Dict[str, Any] = {}
    parent: Optional[
        "BaseNode"
    ] = None  # this is set after the fact; it's Optional to make mypy happy

    @property
    def publish(self) -> bool:
        return not self.meta.get("publish.ignore", False)

    @property
    def tests(self) -> List[str]:
        # this has a lot of stuff to make mypy happy
        return [
            node.name
            for name, node in BaseNode._instances.items()
            if node.resource_type == DbtResourceType.test
            and isinstance(node, Test)
            and node.depends_on
            and node.depends_on.nodes is not None
            and self.parent
            and self.parent.unique_id in node.depends_on.nodes
            and node.test_metadata
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
            include.add("description")
        return yaml.dump([{**self.dict(include=include), **extras}], sort_keys=False)


class BaseNode(BaseModel):
    _instances: ClassVar[Dict[str, "BaseNode"]] = {}
    unique_id: str
    fqn: List[str]
    path: Path
    database: str
    schema_: str = Field(None, alias="schema")
    name: str
    resource_type: DbtResourceType
    description: str
    depends_on: Optional[NodeDeps]
    config: NodeConfig
    columns: Dict[str, Column]
    meta: Dict = {}
    catalog_entry: Optional[CatalogTable]

    def __init__(self, **kwargs):
        super(BaseNode, self).__init__(**kwargs)
        self._instances[self.unique_id] = self
        for column in self.columns.values():
            column.parent = self

    @property
    def strfqn(self) -> str:
        return ".".join(self.fqn)

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

    @property
    def gvrepr(self) -> str:
        """
        Returns a string representation intended for graphviz labels
        """
        return "\n".join(
            [
                self.config.materialized or self.resource_type.value,
                self.name,
            ]
        )

    @property
    def gvattrs(self) -> Dict[str, Any]:
        """
        Return a dictionary of graphviz attrs for DAG visualization
        """
        return {
            "fillcolor": "black",
        }


class Seed(BaseNode):
    resource_type: Literal[DbtResourceType.seed]

    @property
    def gvattrs(self) -> Dict[str, Any]:
        return {
            "fillcolor": "green",
        }


class Source(BaseNode):
    resource_type: Literal[DbtResourceType.source]

    @property
    def gvattrs(self) -> Dict[str, Any]:
        return {
            "fillcolor": "blue",
        }


# TODO: this should be a discriminated type based on materialization
class Model(BaseNode):
    resource_type: Literal[DbtResourceType.model]
    depends_on: NodeDeps

    @property
    def children(self) -> List["Model"]:
        children = []
        for unique_id, node in BaseNode._instances.items():
            if (
                isinstance(node, Model)
                and node.depends_on.nodes
                and self.unique_id in node.depends_on.nodes
            ):
                children.append(node)
        return children

    @property
    def gvrepr(self) -> str:
        if (
            self.config.materialized
            in (DbtMaterializationType.table, DbtMaterializationType.incremental)
            and self.catalog_entry
            and self.catalog_entry.num_bytes
        ):
            return "\n".join(
                [
                    super(Model, self).gvrepr,
                    f"Storage: {humanize.naturalsize(self.catalog_entry.num_bytes)}",
                ]
            )
        return super(Model, self).gvrepr

    @property
    def gvattrs(self) -> Dict[str, Any]:
        fillcolor = "white"

        if self.config.materialized in (
            DbtMaterializationType.table,
            DbtMaterializationType.incremental,
        ):
            fillcolor = "aquamarine"

        if (
            self.catalog_entry
            and self.catalog_entry.num_bytes
            and self.catalog_entry.num_bytes > 100_000_000_000
            and "clustering_fields" not in self.catalog_entry.stats
            and "partitioning_type" not in self.catalog_entry.stats
        ):
            fillcolor = "red"

        if (
            self.config.materialized == DbtMaterializationType.view
            and len(self.children) > 1
        ):
            fillcolor = "pink"

        return {
            "fillcolor": fillcolor,
        }


class TestMetadata(BaseModel):
    name: str
    kwargs: Dict[str, Union[str, List, Dict]]


class Test(BaseNode):
    resource_type: Literal[DbtResourceType.test]
    # test_metadata is optional because singular tests (custom defined) do not have test_metadata attribute
    # for example: https://github.com/dbt-labs/dbt-docs/blob/main/src/app/services/graph.service.js#L355
    # ^ singular test is specifically identified by not having the test_metadata attribute
    test_metadata: Optional[TestMetadata]


Node = Annotated[
    Union[Seed, Source, Model, Test],
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


class BaseDestination(BaseModel, abc.ABC):
    format: FileFormat

    def filename(self, model: str):
        return f"{model}.{self.format.value}"

    def hive_path(
        self,
        exposure: "Exposure",
        model: str,
        bucket: str,
        dt: pendulum.DateTime,
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


# mypy will not let subclasses override literals, so we have to have the ABC rather than inheriting from GcsDestination
class GcsDestination(BaseDestination):
    type: Literal["gcs"]


class TilesDestination(BaseDestination):
    """
    For tile server destinations, each depends_on becomes
    a tile layer.
    """

    type: Literal["tiles"]
    bucket: str
    tile_format: TileFormat
    geo_column: str
    metadata_columns: Optional[List[str]]
    layer_names: List[str]

    def tile_filename(self, model):
        return f"{model}.{self.tile_format.value}"

    def tiles_hive_path(
        self,
        exposure: "Exposure",
        model: str,
        bucket: str,
        dt: pendulum.DateTime,
    ):
        return os.path.join(
            bucket,
            f'{slugify(exposure.name, separator="_")}__{self.tile_format.value}',
            f"dt={dt.in_tz('utc').to_date_string()}",
            f"ts={dt.in_tz('utc').to_iso8601_string()}",
            self.tile_filename(model),
        )


class CkanResourceMeta(BaseModel):
    id: str
    description: Optional[str]


class CkanDestination(BaseDestination):
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
    coordinate_system_epsg: Optional[constr(regex=r"\d+")]  # type: ignore # noqa: F722
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
    metrics: Dict
    exposures: Dict[str, Exposure]
    macros: Dict
    docs: Dict
    parent_map: Dict[str, List[str]]
    child_map: Dict[str, List[str]]
    selectors: Dict
    disabled: Dict  # should be Dict[str, Node] but they lack the resource_type

    # https://github.com/pydantic/pydantic/issues/1577#issuecomment-803171322
    def set_catalog(self, c: Catalog):
        for node in self.nodes.values():
            node.catalog_entry = c.nodes.get(
                node.unique_id, c.sources.get(node.unique_id)
            )


class TimingInfo(BaseModel):
    name: str
    started_at: Optional[datetime]
    completed_at: Optional[datetime]


# TODO: it'd be nice to be able to distinguish between models, tests, and freshness checks
class RunResultStatus(str, Enum):
    _pass = "pass"
    success = "success"
    error = "error"
    fail = "fail"
    warn = "warn"
    skipped = "skipped"
    runtime_error = "runtime error"


class RunResult(BaseModel):
    status: RunResultStatus
    timing: List[TimingInfo]
    thread_id: str
    execution_time: int  # seconds
    adapter_response: Dict
    message: Optional[str]
    failures: Optional[int]
    unique_id: str
    manifest: Optional[Manifest]

    @property
    def node(self) -> Node:
        if not self.manifest:
            raise ValueError("must set manifest before calling node")
        return self.manifest.nodes[self.unique_id]

    @property
    def bytes_processed(self):
        return self.adapter_response.get(
            "bytes_processed", 0
        )  # tests do bill bytes but set to 0

    @property
    def gvrepr(self) -> str:
        return self.node.gvrepr

    @property
    def gvattrs(self) -> Dict[str, Any]:
        """
        Returns a string representation intended for graphviz labels
        """
        if self.bytes_processed > 300_000_000_000:
            color = "red"
        elif self.bytes_processed > 100_000_000_000:
            color = "yellow"
        else:
            color = "white"

        return {
            **self.node.gvattrs,
            "fillcolor": color,
            "label": "\n".join(
                [
                    self.node.gvrepr,
                    f"Billed: {humanize.naturalsize(self.bytes_processed)}",
                ]
            ),
        }


class RunResults(BaseModel):
    metadata: Dict
    results: List[RunResult]
    manifest: Optional[Manifest]

    # https://github.com/pydantic/pydantic/issues/1577#issuecomment-803171322
    def set_manifest(self, m: Manifest):
        self.manifest = m
        for result in self.results:
            result.manifest = m


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
