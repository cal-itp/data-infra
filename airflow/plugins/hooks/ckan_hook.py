import logging
from io import StringIO
from typing import Optional

from ckanapi import RemoteCKAN

from airflow.hooks.base import BaseHook
from airflow.models.connection import Connection


class CKANHook(BaseHook):
    _remote_ckan: RemoteCKAN
    connection: Connection
    user_agent: str

    def __init__(
        self,
        ckan_conn_id: str = "ckan_default",
        resource_id: Optional[str] = None,
        file_name: Optional[str] = None,
    ):
        super().__init__()
        self._remote_ckan = None
        self.connection: Connection = BaseHook.get_connection(ckan_conn_id)
        self.user_agent: str = "ckanapi/1.0 (+https://dds.dot.ca.gov)"
        self.resource_id = resource_id
        self.file_name = file_name
        self.upload_id = None
        self.part_number = 0

    def __enter__(self):
        multipart = self.remote_ckan().call_action(
            "cloudstorage_initiate_multipart",
            {"id": self.resource_id, "name": self.file_name, "size": "1"},
        )

        self.upload_id = multipart.get("id")
        logging.info(f"Initiated multipart: {self.upload_id}")
        return self  # Return the resource to be used in the 'with' block

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            logging.error(
                f"AN EXCEPTION OF TYPE {exc_type.__name__} OCCURRED: {exc_val}"
            )
            logging.error(exc_tb)
            self.remote_ckan().call_action(
                "cloudstorage_abort_multipart",
                {
                    "id": self.resource_id,
                    "uploadId": self.upload_id,
                },
            )
        else:
            logging.info("Completed upload")
            logging.info(f"RELEASING RESOURCE: {self.file_name}")
            self.remote_ckan().call_action(
                "cloudstorage_finish_multipart",
                {
                    "id": self.resource_id,
                    "uploadId": self.upload_id,
                    "save_action": "go-metadata",
                },
            )
            self.remote_ckan().call_action(
                "resource_patch",
                {
                    "id": self.resource_id,
                    "multipart_name": self.file_name,
                    "url": self.file_name,
                    "url_type": "upload",
                },
            )
        return False  # Returning False (or None) propagates the exception, True suppresses it

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
        return resources.get(resource_name)

    def upload(self, resource_id: str, file: StringIO):
        return self.remote_ckan().call_action(
            "resource_update", {"id": resource_id}, files={"upload": file}
        )

    def multi_upload(self, file: StringIO):
        assert self.upload_id is not None
        self.part_number += 1
        return self.remote_ckan().call_action(
            "cloudstorage_upload_multipart",
            {
                "id": self.resource_id,
                "uploadId": self.upload_id,
                "partNumber": str(self.part_number),
            },
            files={"upload": file},
        )
