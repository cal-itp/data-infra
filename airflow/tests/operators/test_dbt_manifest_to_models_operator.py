import os

import pytest
from operators.dbt_manifest_to_models_operator import DBTManifestToModelsOperator


class TestDBTManifestToModelsOperator:
    @pytest.fixture
    def manifest(self) -> dict:
        return {
            "nodes": {
                "model.calitp_warehouse.tides_organizations": {
                    "resource_type": "model",
                    "name": "tides_organizations",
                    "schema": "mart_tides",
                    "tags": ["tides_reference"],
                },
                "model.calitp_warehouse.tides_organizations_latest": {
                    "resource_type": "model",
                    "name": "tides_organizations_latest",
                    "schema": "mart_tides",
                    "tags": ["tides_reference"],
                },
                "model.calitp_warehouse.fct_tides_vehicle_locations": {
                    "resource_type": "model",
                    "name": "fct_tides_vehicle_locations",
                    "schema": "mart_tides",
                    "tags": ["tides_product"],
                },
                "model.calitp_warehouse.dim_agency": {
                    "resource_type": "model",
                    "name": "dim_agency",
                    "schema": "mart_gtfs",
                    "tags": [],
                },
                "test.calitp_warehouse.not_null_tides_organizations_key": {
                    "resource_type": "test",
                    "name": "not_null_tides_organizations_key",
                    "schema": "mart_tides",
                    "tags": ["tides_reference"],
                },
            }
        }

    @pytest.fixture
    def operator(self) -> DBTManifestToModelsOperator:
        return DBTManifestToModelsOperator(
            task_id="list_reference_models",
            bucket_name=os.environ.get("CALITP_BUCKET__DBT_DOCS"),
            object_name="manifest.json",
            tag="tides_reference",
        )

    def test_models_filters_by_tag_and_resource_type(
        self, operator: DBTManifestToModelsOperator, manifest: dict, monkeypatch
    ):
        monkeypatch.setattr(operator, "read_manifest", lambda: manifest)

        assert operator.models() == [
            {"name": "tides_organizations", "schema": "mart_tides"},
            {"name": "tides_organizations_latest", "schema": "mart_tides"},
        ]

    def test_models_handles_missing_tags(
        self, operator: DBTManifestToModelsOperator, monkeypatch
    ):
        manifest = {
            "nodes": {
                "model.calitp_warehouse.some_model": {
                    "resource_type": "model",
                    "name": "some_model",
                    "schema": "mart_tides",
                },
            }
        }
        monkeypatch.setattr(operator, "read_manifest", lambda: manifest)

        assert operator.models() == []
