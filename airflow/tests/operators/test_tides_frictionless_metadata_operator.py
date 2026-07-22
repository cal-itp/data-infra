import os

import pytest
from operators.tides_frictionless_metadata_operator import (
    TIDESFrictionlessMetadataOperator,
)


class TestTIDESFrictionlessMetadataOperator:
    @pytest.fixture
    def manifest(self) -> dict:
        return {
            "nodes": {
                "model.calitp_warehouse.tides_organizations_latest": {
                    "resource_type": "model",
                    "name": "tides_organizations_latest",
                    "schema": "mart_tides",
                    "description": "Current-version cut of tides_organizations.",
                    "columns": {
                        "source_record_id": {
                            "name": "source_record_id",
                            "description": "Airtable source record ID.",
                        },
                        "name": {"name": "name", "description": "Organization name."},
                    },
                }
            }
        }

    @pytest.fixture
    def catalog(self) -> dict:
        return {
            "nodes": {
                "model.calitp_warehouse.tides_organizations_latest": {
                    "columns": {
                        "name": {"name": "name", "type": "STRING", "index": 2},
                        "source_record_id": {
                            "name": "source_record_id",
                            "type": "STRING",
                            "index": 1,
                        },
                        "_valid_from": {
                            "name": "_valid_from",
                            "type": "TIMESTAMP",
                            "index": 3,
                        },
                        "is_public_entity": {
                            "name": "is_public_entity",
                            "type": "BOOL",
                            "index": 4,
                        },
                    }
                }
            }
        }

    @pytest.fixture
    def operator(self, manifest: dict, catalog: dict, monkeypatch):
        operator = TIDESFrictionlessMetadataOperator(
            task_id="write_datapackages",
            bucket_name=os.environ.get("CALITP_BUCKET__DBT_DOCS"),
            model_name="tides_organizations_latest",
            destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
            destination_path_prefix="reference/tides_organizations_latest/",
            user_project=os.environ.get("GOOGLE_CLOUD_PROJECT"),
        )
        monkeypatch.setattr(
            operator,
            "read_json",
            lambda object_name: (
                manifest if object_name == "manifest.json" else catalog
            ),
        )
        return operator

    def test_fields_merge_catalog_types_and_manifest_descriptions(
        self, operator: TIDESFrictionlessMetadataOperator
    ):
        assert operator.fields() == [
            {
                "name": "source_record_id",
                "type": "string",
                "description": "Airtable source record ID.",
            },
            {"name": "name", "type": "string", "description": "Organization name."},
            {"name": "_valid_from", "type": "datetime"},
            {"name": "is_public_entity", "type": "boolean"},
        ]

    def test_datapackage(self, operator: TIDESFrictionlessMetadataOperator):
        datapackage = operator.datapackage(
            file_names=["data_000000000000.csv", "data_000000000000.parquet"],
            fields=operator.fields(),
        )

        assert datapackage["profile"] == "tabular-data-package"
        assert datapackage["name"] == "tides_organizations_latest"
        assert (
            datapackage["description"] == "Current-version cut of tides_organizations."
        )
        assert datapackage["licenses"][0]["name"] == "CC-BY-4.0"
        assert datapackage["contributors"][0]["email"] == "hello@calitp.org"

        assert [r["path"] for r in datapackage["resources"]] == [
            "data_000000000000.csv",
            "data_000000000000.parquet",
        ]
        assert [r["format"] for r in datapackage["resources"]] == ["csv", "parquet"]
        for resource in datapackage["resources"]:
            assert resource["schema"]["fields"] == operator.fields()
