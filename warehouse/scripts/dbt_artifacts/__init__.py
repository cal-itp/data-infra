"""
Built off the starting point of https://guitton.co/posts/dbt-artifacts
"""

import abc
import os
from enum import Enum
from typing import Annotated, Any, ClassVar, Dict, List, Literal, Optional, Union

import humanize
import pendulum
from pydantic import BaseModel, Field, constr, root_validator
from slugify import slugify
from sqlalchemy import MetaData, Table, create_engine, select
from sqlalchemy.sql import Select

from .catalog import CatalogTable
from .catalog import Model as Catalog
from .manifest import AnalysisNode as BaseAnalysisNode
from .manifest import ColumnInfo, DependsOn
from .manifest import Exposure as BaseExposure
from .manifest import GenericTestNode as BaseGenericTestNode
from .manifest import HookNode as BaseHookNode
from .manifest import Model as BaseManifest
from .manifest import ModelNode as BaseModelNode
from .manifest import RPCNode as BaseRPCNode
from .manifest import SeedNode as BaseSeedNode
from .manifest import SingularTestNode as BaseSingularTestNode
from .manifest import SnapshotNode as BaseSnapshotNode
from .manifest import SourceDefinition as BaseSourceDefinition
from .manifest import SqlNode as BaseSqlNode
from .run_results import Model as BaseRunResults
from .run_results import RunResultOutput as BaseRunResultOutput
from .sources import Model as Sources


# Taken from the calitp repo which we can't install because of deps issue
def get_engine(project, max_bytes=None):
    max_bytes = 5_000_000_000 if max_bytes is None else max_bytes

    # Note that we should be able to add location as a uri parameter, but
    # it is not being picked up, so passing as a separate argument for now.
    return create_engine(
        f"bigquery://{project}/?maximum_bytes_billed={max_bytes}",  # noqa: E231
        location="us-west2",
        credentials_path=os.environ.get("BIGQUERY_KEYFILE_LOCATION"),
    )


# Monkey patches


def num_bytes(self) -> Optional[int]:
    if "num_bytes" in self.stats:
        value = self.stats["num_bytes"].value
        # for some reason, 0 gets parsed as bool by pydantic
        # maybe because it's first in the union?
        if isinstance(value, bool):
            return 0
        assert isinstance(value, (float, str))
        return int(float(value))
    return None


CatalogTable.num_bytes = property(num_bytes)  # type: ignore[attr-defined]

DependsOn.resolved_nodes = property(  # type: ignore[attr-defined]
    lambda self: (
        [NodeModelMixin._instances[node] for node in self.nodes] if self.nodes else []
    )
)
ColumnInfo.publish = property(lambda self: self.meta.get("publish.include", False))  # type: ignore[attr-defined]


# End monkey patches


class NodeModelMixin(BaseModel):
    _instances: ClassVar[Dict[str, "NodeModelMixin"]] = {}
    catalog_entry: Optional[CatalogTable]

    # TODO: can we avoid re-defining these here?
    unique_id: str
    fqn: List[str]
    name: str
    schema_: str
    database: Optional[str]
    columns: Optional[Dict[str, ColumnInfo]] = {}

    def __init__(self, **kwargs):
        super(NodeModelMixin, self).__init__(**kwargs)
        self._instances[self.unique_id] = self

    @property
    def strfqn(self) -> str:
        return ".".join(self.fqn)

    @property
    def table_name(self):
        return self.config.alias or self.name  # type: ignore[attr-defined]

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
            if self.columns
            and c.name in self.columns
            and self.columns[c.name].publish  # type: ignore[attr-defined]
        ]
        return select(columns=columns)

    @property
    def gvrepr(self) -> str:
        """
        Returns a string representation intended for graphviz labels
        """
        return self.unique_id

    @property
    def gvattrs(self) -> Dict[str, Any]:
        """
        Return a dictionary of graphviz attrs for DAG visualization
        """
        return {
            "fillcolor": "white",  # this is already the default but make explicit
            "label": "\n".join(
                [
                    self.config.materialized or self.resource_type.value,  # type: ignore[attr-defined]
                    self.name,
                ]
            ),
        }


class AnalysisNode(BaseAnalysisNode, NodeModelMixin):
    pass


class SingularTestNode(BaseSingularTestNode, NodeModelMixin):
    pass


class HookNode(BaseHookNode, NodeModelMixin):
    pass


class ModelNode(BaseModelNode, NodeModelMixin):
    @property
    def children(self) -> List["ModelNode"]:
        children = []
        for unique_id, node in NodeModelMixin._instances.items():
            if (
                isinstance(node, ModelNode)
                and node.depends_on
                and node.depends_on.nodes
                and self.unique_id in node.depends_on.nodes
            ):
                children.append(node)

        return children

    @property
    def gvattrs(self) -> Dict[str, Any]:
        assert self.config is not None, self.unique_id
        fillcolor = super(ModelNode, self).gvattrs["fillcolor"]

        more_than_100gb = (
            self.catalog_entry
            and self.catalog_entry.num_bytes  # type: ignore[attr-defined]
            and self.catalog_entry.num_bytes > 100_000_000_000  # type: ignore[attr-defined]
        )

        if self.config.materialized == "table":
            fillcolor = "darkseagreen"
        elif self.config.materialized == "incremental":
            fillcolor = "darkseagreen1"

        if (
            more_than_100gb
            and self.catalog_entry
            and "clustering_fields" not in self.catalog_entry.stats
            and "partitioning_type" not in self.catalog_entry.stats
        ):
            fillcolor = "orange"

        if self.config.materialized == "view" and len(self.children) > 1:
            fillcolor = "yellow"

        label = super(ModelNode, self).gvattrs["label"]
        if self.catalog_entry and self.catalog_entry.num_bytes:  # type: ignore[attr-defined]
            label += f"\nStorage: {humanize.naturalsize(self.catalog_entry.num_bytes)}"  # type: ignore[attr-defined]

        return {
            "fillcolor": fillcolor,
            "label": label,
        }


class RPCNode(BaseRPCNode, NodeModelMixin):
    pass


class SqlNode(BaseSqlNode, NodeModelMixin):
    pass


class GenericTestNode(BaseGenericTestNode, NodeModelMixin):
    pass


class SnapshotNode(BaseSnapshotNode, NodeModelMixin):
    pass


class SeedNode(BaseSeedNode, NodeModelMixin):
    @property
    def gvattrs(self):
        return {
            "style": "dashed",
        }


DbtNode = Union[
    AnalysisNode,
    SingularTestNode,
    HookNode,
    ModelNode,
    RPCNode,
    SqlNode,
    GenericTestNode,
    SnapshotNode,
    SeedNode,
]


class SourceDefinition(BaseSourceDefinition, NodeModelMixin):
    @property
    def gvattrs(self) -> Dict:
        return {
            "fillcolor": "blue",
        }

    pass


class FileFormat(str, Enum):
    csv = "csv"
    geojson = "geojson"
    geojsonl = "geojsonl"
    json = "json"
    jsonl = "jsonl"


class TileFormat(str, Enum):
    mbtiles = "mbtiles"
    pbf = "pbf"


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


class Exposure(BaseExposure):
    # TODO: we should validate that model names do not conflict with
    #  file format names since they are used as entity names in hive partitions
    meta: Optional[ExposureMeta]

    @root_validator
    def must_provide_layer_names_if_tiles(cls, values):
        if values["meta"]:
            for dest in values["meta"].destinations:
                if isinstance(dest, TilesDestination):
                    assert len(dest.layer_names) == len(
                        values["depends_on"].nodes
                    ), "must provide one layer name per depends_on"
        return values


class Manifest(BaseManifest):
    nodes: Dict[
        str,
        DbtNode,
    ] = Field(
        ..., description="The nodes defined in the dbt project and its dependencies"
    )
    exposures: Dict[str, Exposure] = Field(
        ..., description="The exposures defined in the dbt project and its dependencies"
    )
    sources: Dict[str, SourceDefinition] = Field(
        ..., description="The sources defined in the dbt project and its dependencies"
    )

    # https://github.com/pydantic/pydantic/issues/1577#issuecomment-803171322
    def set_catalog(self, c: Catalog):
        for node in self.nodes.values():
            node.catalog_entry = c.nodes.get(
                node.unique_id, c.sources.get(node.unique_id)
            )


class RunResultStatus(Enum):
    success = "success"
    error = "error"
    skipped = "skipped"
    pass_ = "pass"
    fail = "fail"
    warn = "warn"
    runtime_error = "runtime error"


class RunResultOutput(BaseRunResultOutput):
    status: RunResultStatus
    manifest: Optional[Manifest]

    # TODO: bring me back
    @property
    def node(self) -> DbtNode:
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
        color = "white"
        assert self.node is not None
        # TODO: use palettable
        if self.bytes_processed > 500_000_000_000:
            color = "red"
        elif self.bytes_processed > 300_000_000_000:
            color = "orange"
        elif self.bytes_processed > 100_000_000_000:
            color = "yellow"

        return {
            "fillcolor": color,
            "label": "\n".join(
                [
                    self.node.gvrepr,
                    f"Billed: {humanize.naturalsize(self.bytes_processed)}",
                ]
            ),
        }


class RunResults(BaseRunResults):
    results: List[RunResultOutput]  # type: ignore[assignment]
    manifest: Optional[Manifest]

    # https://github.com/pydantic/pydantic/issues/1577#issuecomment-803171322
    def set_manifest(self, m: Manifest):
        self.manifest = m
        for result in self.results:
            result.manifest = m


__all__ = [
    "Catalog",
    "DbtNode",
    "GenericTestNode",
    "Manifest",
    "RunResultOutput",
    "RunResults",
    "SeedNode",
    "SourceDefinition",
    "Sources",
    "Exposure",
    "CkanDestination",
    "NodeModelMixin",
    "TilesDestination",
    "TileFormat",
]
