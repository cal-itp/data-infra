import json
import os
from typing import Sequence

from operators.tides_reference_export_operator import reference_destination_prefix

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook

MEDIA_TYPES = {
    "parquet": "application/vnd.apache.parquet",
    "csv": "text/csv",
}


class TIDESDCATMetadataOperator(BaseOperator):
    """Writes a DCAT-US data.json catalog for the published TIDES datasets.

    One dcat:Dataset entry per published table -- the tides_reference models
    passed in via XCom plus the fact tables passed as extra_datasets --
    matching the machine-readable metadata format data.ca.gov publishes
    (Project Open Data v1.1 / SAM 5160.1). Titles and descriptions come from
    manifest.json.
    """

    template_fields: Sequence[str] = (
        "bucket_name",
        "manifest_object_name",
        "models",
        "extra_datasets",
        "destination_bucket",
        "destination_object_name",
        "modified",
        "user_project",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket_name: str,
        models: list[dict],
        destination_bucket: str,
        user_project: str,
        extra_datasets: list[dict] = None,
        destination_object_name: str = "metadata/data.json",
        manifest_object_name: str = "manifest.json",
        modified: str = "{{ ds }}",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ):
        super().__init__(**kwargs)

        self._gcs_hook: GCSHook = None
        self.bucket_name = bucket_name
        self.models = models
        self.destination_bucket = destination_bucket
        self.user_project = user_project
        self.extra_datasets = extra_datasets or []
        self.destination_object_name = destination_object_name
        self.manifest_object_name = manifest_object_name
        self.modified = modified
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        if self._gcs_hook is None:
            self._gcs_hook = GCSHook(gcp_conn_id=self.gcp_conn_id)
        return self._gcs_hook

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def read_manifest(self) -> dict:
        return json.loads(
            self.gcs_hook().download(
                bucket_name=self.bucket_name.replace("gs://", ""),
                object_name=self.manifest_object_name,
            )
        )

    def dataset_specs(self) -> list[dict]:
        specs = [
            {
                "model_name": model["name"],
                "prefix": reference_destination_prefix(model["name"], "*"),
                "formats": ["parquet", "csv"],
            }
            for model in self.models
        ]
        specs.extend(self.extra_datasets)
        return specs

    def dataset_entry(self, spec: dict, manifest_nodes: dict) -> dict:
        node = manifest_nodes.get(f"model.calitp_warehouse.{spec['model_name']}", {})
        access_url = os.path.join(self.destination_bucket, spec["prefix"])
        return {
            "@type": "dcat:Dataset",
            "identifier": access_url,
            "title": spec["model_name"],
            "description": node.get("description", ""),
            "keyword": ["transit", "TIDES", "GTFS", "California"],
            "modified": self.modified,
            "publisher": {"@type": "org:Organization", "name": "Caltrans"},
            "contactPoint": {
                "@type": "vcard:Contact",
                "fn": "Cal-ITP / Caltrans Data & Digital Services",
                "hasEmail": "mailto:hello@calitp.org",
            },
            "accessLevel": "public",
            "license": "https://creativecommons.org/licenses/by/4.0/",
            "rights": (
                "Requester-pays Google Cloud Storage bucket; downloads are "
                "billed to the requester's GCP project."
            ),
            "distribution": [
                {
                    "@type": "dcat:Distribution",
                    "format": extension,
                    "mediaType": MEDIA_TYPES[extension],
                    "accessURL": access_url,
                }
                for extension in spec["formats"]
            ],
        }

    def catalog(self) -> dict:
        manifest_nodes = self.read_manifest().get("nodes", {})
        return {
            "@context": "https://project-open-data.cio.gov/v1.1/schema/catalog.jsonld",
            "@type": "dcat:Catalog",
            "conformsTo": "https://project-open-data.cio.gov/v1.1/schema",
            "describedBy": "https://project-open-data.cio.gov/v1.1/schema/catalog.json",
            "dataset": [
                self.dataset_entry(spec, manifest_nodes)
                for spec in self.dataset_specs()
            ],
        }

    def execute(self, context: Context) -> dict:
        catalog = self.catalog()

        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_object_name,
            data=json.dumps(catalog, indent=2),
            mime_type="application/json",
            gzip=False,
            user_project=self.user_project,
        )

        return {
            "destination_path": self.destination_object_name,
            "dataset_count": len(catalog["dataset"]),
        }
