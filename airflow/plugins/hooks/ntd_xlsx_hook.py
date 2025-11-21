from bs4 import BeautifulSoup

from airflow.hooks.base import BaseHook
from airflow.hooks.http_hook import HttpHook

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "sec-ch-ua": '"Not A;Brand"',
    "sec-fetch-dest": "document",
    "sec-fetch-mode": "navigate",
    "sec-fetch-site": "none",
    "sec-fetch-user": "?1",
}


class NTDXLSXHook(BaseHook):
    _http_conn_id: str
    _method: str

    def __init__(self, method: str = "GET", http_conn_id: str = "http_dot"):
        super().__init__()
        self._http_conn_id: str = http_conn_id
        self._method: str = method

    def http_hook(self) -> HttpHook:
        return HttpHook(method=self._method, http_conn_id=self._http_conn_id)

    def run(self, endpoint: str) -> str:
        body = self.http_hook().run(endpoint=endpoint, headers=HEADERS).text
        soup = BeautifulSoup(body, "html.parser")
        link = soup.find(
            "a",
            type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        )
        return link.get("href")
