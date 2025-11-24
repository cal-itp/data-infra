from airflow.hooks.base import BaseHook
from airflow.providers.http.hooks.http import HttpHook


class KubaHook(BaseHook):
    _http_conn_id: str
    _method: str
    _session_id: str

    def __init__(self, method: str = "GET", http_conn_id: str = "kuba_default"):
        super().__init__()
        self._http_conn_id: str = http_conn_id
        self._method: str = method
        self._session_id: str = None
        self._get_connection()

    def _get_connection(self):
        conn = self.get_connection(self._http_conn_id)
        data = {
            "UserName": conn.login,
            "Password": conn.password,
            "OperatorIdentifier": int(conn.schema),
        }
        headers = {"Content-Type": "application/json"}
        kuba_api = HttpHook(method="POST", http_conn_id=self._http_conn_id)
        authenticate_path = "monitoring/authenticate/v1"
        result = kuba_api.run(
            endpoint=authenticate_path, headers=headers, json=data
        ).json()
        assert result["Error"] is None
        self._session_id = result["SessionId"]

    def get_headers(self):
        return {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Cookie": f"session-id={self._session_id}",
        }

    def run(self, endpoint, data=None, headers=None):
        if headers is None:
            headers = self.get_headers()

        kuba_api = HttpHook(method=self._method, http_conn_id=self._http_conn_id)
        response = kuba_api.run(endpoint=endpoint, headers=headers, data=data)
        return response.json()
