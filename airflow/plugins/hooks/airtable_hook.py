from pyairtable import Api

from airflow.hooks.base import BaseHook
from airflow.models.connection import Connection


class AirtableHook(BaseHook):
    _api: Api
    connection: Connection

    def __init__(self, airtable_conn_id: str = "airtable_default"):
        super().__init__()
        self._api = None
        self.connection: Connection = BaseHook.get_connection(airtable_conn_id)

    def api(self) -> Api:
        if not self._api:
            self._api = Api(self.connection.password)
        return self._api

    def read(self, air_base_id, air_table_name, data=None):
        return self.api().table(air_base_id, air_table_name).all()
