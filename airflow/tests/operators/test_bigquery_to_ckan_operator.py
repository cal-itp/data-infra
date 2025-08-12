import os

from ckanapi import RemoteCKAN


class TestBigqueryToCKANOperator:
    def test_execute(self):
        user_agent = "ckanapi/1.0 (+https://dds.dot.ca.gov)"
        apikey = os.environ.get("CKAN_API_KEY")
        ckan = RemoteCKAN("https://data.ca.gov", apikey=apikey, user_agent=user_agent)
        package_info = ckan.call_action(
            "package_show", {"id": "cal-itp-gtfs-ingest-pipeline-dataset"}
        )
        assert "resources" in package_info

        resource = ckan.call_action(
            "resource_show", {"id": "c3828596-e796-4b3b-a146-ebeb09b3a4d2"}
        )
        assert resource == {
            "cache_last_updated": None,
            "cache_url": None,
            "created": "2023-07-05T20:08:39.731815",
            "datastore_active": True,
            "datastore_contains_all_records_of_source_file": True,
            "format": "CSV",
            "hash": "0c0700cb7ad3c40980ce5a476ae27dc3",
            "id": "c3828596-e796-4b3b-a146-ebeb09b3a4d2",
            "last_modified": "2025-07-14T00:22:18.044402",
            "metadata_modified": "2025-07-14T00:22:23.389548",
            "mimetype": None,
            "mimetype_inner": None,
            "name": "agency",
            "package_id": "de6f1544-b162-4d16-997b-c183912c8e62",
            "position": 2,
            "resource_id": "c3828596-e796-4b3b-a146-ebeb09b3a4d2",
            "resource_type": None,
            "size": None,
            "state": "active",
            "url": "https://data.ca.gov/dataset/de6f1544-b162-4d16-997b-c183912c8e62/resource/c3828596-e796-4b3b-a146-ebeb09b3a4d2/download/agency.csv",
            "url_type": "upload",
        }
