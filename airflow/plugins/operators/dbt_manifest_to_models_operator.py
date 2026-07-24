import json
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class DBTManifestToModelsOperator(BaseOperator):
    """Lists the dbt models carrying a given tag, straight from manifest.json.

    Returns one dict per tagged model: {"name": ..., "schema": ...}. Used by
    export DAGs that are tag-driven (e.g. tides_reference) instead of parsing
    a dbt exposure.
    """

    template_fields: Sequence[str] = (
        "bucket_name",
        "object_name",
        "tag",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket_name: str,
        object_name: str,
        tag: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ):
        super().__init__(**kwargs)

        self.bucket_name = bucket_name
        self.object_name = object_name
        self.tag = tag
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def read_manifest(self) -> dict:
        manifest = self.gcs_hook().download(
            bucket_name=self.bucket_name.replace("gs://", ""),
            object_name=self.object_name,
        )
        return json.loads(manifest)

    def models(self) -> list[dict]:
        return sorted(
            (
                {"name": node["name"], "schema": node["schema"]}
                for node in self.read_manifest().get("nodes", {}).values()
                if node.get("resource_type") == "model"
                and self.tag in (node.get("tags") or [])
            ),
            key=lambda model: model["name"],
        )

    def execute(self, context: Context) -> list[dict]:
        models = self.models()
        self.log.info("found %d models tagged %s", len(models), self.tag)
        return models
