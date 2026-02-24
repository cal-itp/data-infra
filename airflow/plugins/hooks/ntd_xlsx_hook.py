from bs4 import BeautifulSoup

from airflow.hooks.base import BaseHook
from airflow.hooks.http_hook import HttpHook

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Language": "en-US,en;q=0.9",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "Sec-Ch-Ua": '"Not:A-Brand";v="99", "Google Chrome";v="145", "Chromium";v="145',
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "cross-site",
    "Sec-Fetch-User": "?1",
    "Cache-Control": "max-age=0",
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
        href = link.get("href")
        return self.http_hook().run(endpoint=href, headers=HEADERS)
