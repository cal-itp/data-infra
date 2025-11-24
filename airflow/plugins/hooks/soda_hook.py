from math import ceil

from airflow.hooks.base import BaseHook
from airflow.providers.http.hooks.http import HttpHook


class SODAHook(BaseHook):
    _http_conn_id: str
    _method: str

    def __init__(self, method: str = "GET", http_conn_id: str = "soda_default"):
        super().__init__()
        self._http_conn_id: str = http_conn_id
        self._method: str = method

    def http_hook(self) -> HttpHook:
        return HttpHook(method=self._method, http_conn_id=self._http_conn_id)

    def total_pages(self, resource: str, limit: int = 1000) -> int:
        response_json = (
            self.http_hook()
            .run(endpoint=f"resource/{resource}.json", data={"$select": "count(*)"})
            .json()
        )
        return ceil(int(response_json[0]["count"]) / (limit * 1.0))

    def page(self, resource: str, page: int, limit: int = 1000) -> list[dict[str, str]]:
        offset = max(page - 1, 0) * limit
        response_json = (
            self.http_hook()
            .run(
                endpoint=f"resource/{resource}.json",
                data={"$limit": limit, "$offset": offset},
            )
            .json()
        )
        return response_json
