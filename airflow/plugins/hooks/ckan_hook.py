from io import StringIO

from ckanapi import RemoteCKAN

from airflow.hooks.base import BaseHook
from airflow.models.connection import Connection


class CKANHook(BaseHook):
    _remote_ckan: RemoteCKAN
    connection: Connection
    user_agent: str

    def __init__(self, ckan_conn_id: str = "ckan_default"):
        super().__init__()
        self._remote_ckan = None
        self.connection: Connection = BaseHook.get_connection(ckan_conn_id)
        self.user_agent: str = "ckanapi/1.0 (+https://dds.dot.ca.gov)"

    def remote_ckan(self) -> RemoteCKAN:
        if not self._remote_ckan:
            self._remote_ckan = RemoteCKAN(
                f"{self.connection.conn_type}://{self.connection.host}",
                apikey=self.connection.password,
                user_agent=self.user_agent,
            )
        return self._remote_ckan

    def find_resource_id(self, dataset_id: str, resource_name: str):
        dataset = self.remote_ckan().call_action("package_show", {"id": dataset_id})
        resources = {
            resource["name"]: resource["id"]
            for resource in dataset.get("resources", [])
        }
        return resources[resource_name]

    def upload(self, resource_id: str, file: StringIO):
        return self.remote_ckan().call_action(
            "resource_patch", {"id": resource_id}, files={"upload": file}
        )
