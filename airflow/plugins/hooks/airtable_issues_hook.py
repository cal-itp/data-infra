from __future__ import annotations

from typing import Any

from pyairtable import Api

from airflow.hooks.base import BaseHook
from airflow.models.connection import Connection


class AirtableIssuesHook(BaseHook):
    connection: Connection
    _api: Api | None

    def __init__(self, airtable_conn_id: str = "airtable_issue_management") -> None:
        super().__init__()
        self.connection = BaseHook.get_connection(airtable_conn_id)
        self._api = None

    def api(self) -> Api:
        if self._api is None:
            self._api = Api(self.connection.password)
        return self._api

    def table(self, air_base_id: str, air_table_name: str):
        return self.api().table(air_base_id, air_table_name)

    def read(self, air_base_id: str, air_table_name: str) -> list[dict[str, Any]]:
        return self.table(air_base_id, air_table_name).all()

    def batch_update(
        self,
        air_base_id: str,
        air_table_name: str,
        records: list[dict[str, Any]],
    ) -> Any:
        return self.table(air_base_id, air_table_name).batch_update(records)

    def batch_create(
        self,
        *,
        air_base_id: str,
        air_table_name: str,
        records: list[dict[str, Any]],
    ) -> list[dict[str, Any]]:
        return self.table(
            air_base_id=air_base_id,
            air_table_name=air_table_name,
        ).batch_create(records)
