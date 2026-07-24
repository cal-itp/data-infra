import os

import pytest
from operators.tides_dcat_metadata_operator import TIDESDCATMetadataOperator


class TestTIDESDCATMetadataOperator:
    @pytest.fixture
    def manifest(self) -> dict:
        return {
            "nodes": {
                "model.calitp_warehouse.tides_organizations": {
                    "name": "tides_organizations",
                    "description": "Organization reference, all versions.",
                },
                "model.calitp_warehouse.tides_organizations_latest": {
                    "name": "tides_organizations_latest",
                    "description": "Current-version cut of tides_organizations.",
                },
                "model.calitp_warehouse.fct_tides_vehicle_locations": {
                    "name": "fct_tides_vehicle_locations",
                    "description": "TIDES vehicle_locations.",
                },
            }
        }

    @pytest.fixture
    def operator(self, manifest: dict, monkeypatch) -> TIDESDCATMetadataOperator:
        operator = TIDESDCATMetadataOperator(
            task_id="write_dcat_catalog",
            bucket_name=os.environ.get("CALITP_BUCKET__DBT_DOCS"),
            models=[
                {"name": "tides_organizations", "schema": "mart_tides"},
                {"name": "tides_organizations_latest", "schema": "mart_tides"},
            ],
            extra_datasets=[
                {
                    "model_name": "fct_tides_vehicle_locations",
                    "prefix": "vehicle_locations/",
                    "formats": ["parquet"],
                },
            ],
            destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
            user_project=os.environ.get("GOOGLE_CLOUD_PROJECT"),
            modified="2026-07-16",
        )
        monkeypatch.setattr(operator, "read_manifest", lambda: manifest)
        return operator

    def test_catalog(self, operator: TIDESDCATMetadataOperator):
        catalog = operator.catalog()

        assert catalog["@type"] == "dcat:Catalog"
        assert catalog["conformsTo"] == "https://project-open-data.cio.gov/v1.1/schema"
        assert [d["title"] for d in catalog["dataset"]] == [
            "tides_organizations",
            "tides_organizations_latest",
            "fct_tides_vehicle_locations",
        ]

    def test_dataset_entries(self, operator: TIDESDCATMetadataOperator):
        bucket = os.environ.get("CALITP_BUCKET__TIDES")
        history, latest, fact = operator.catalog()["dataset"]

        # history models are dt-stamped, latest models live at a stable path
        assert history["identifier"] == f"{bucket}/reference/tides_organizations/dt=*/"
        assert latest["identifier"] == f"{bucket}/reference/tides_organizations_latest/"
        assert fact["identifier"] == f"{bucket}/vehicle_locations/"

        assert latest["description"] == "Current-version cut of tides_organizations."
        assert latest["accessLevel"] == "public"
        assert latest["modified"] == "2026-07-16"
        assert latest["contactPoint"]["hasEmail"] == "mailto:hello@calitp.org"
        assert latest["publisher"]["name"] == "Caltrans"

        assert [d["format"] for d in latest["distribution"]] == ["parquet", "csv"]
        assert [d["format"] for d in fact["distribution"]] == ["parquet"]
        assert (
            latest["distribution"][0]["mediaType"] == "application/vnd.apache.parquet"
        )
