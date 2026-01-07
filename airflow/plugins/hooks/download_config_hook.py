from typing import Any

from requests import PreparedRequest, Request, Response, Session
from requests.exceptions import ConnectionError, HTTPError

from airflow.exceptions import AirflowException
from airflow.hooks.base import BaseHook
from airflow.providers.google.cloud.hooks.secret_manager import (
    GoogleCloudSecretManagerHook,
)

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


class DownloadConfigHook(BaseHook):
    download_config: dict
    method: str

    def __init__(self, download_config: dict, method: str = "GET"):
        super().__init__()
        self.download_config: str = download_config
        self.method: str = method

    def secret_hook(self) -> GoogleCloudSecretManagerHook:
        return GoogleCloudSecretManagerHook()

    def data(self) -> dict[str, str]:
        return {
            param: self.secret_hook().access_secret(secret_id=secret_id).payload.data
            for param, secret_id in self.download_config["auth_query_params"].items()
        }

    def headers(self) -> dict[str, str]:
        return HEADERS | {
            param: self.secret_hook().access_secret(secret_id=secret_id).payload.data
            for param, secret_id in self.download_config["auth_headers"].items()
        }

    def url(self) -> str:
        return self.download_config["url"]

    def run(self, **options) -> int:
        session = Session()

        if self.method == "GET":
            # GET uses params
            req = Request(
                self.method, self.url(), params=self.data(), headers=self.headers()
            )
        elif self.method == "HEAD":
            # HEAD doesn't use params
            req = Request(self.method, self.url(), headers=self.headers())
        else:
            # Others use data
            req = Request(
                self.method, self.url(), data=self.data(), headers=self.headers()
            )

        prepped_request = session.prepare_request(req)
        self.log.debug("Sending '%s' to url: %s", self.method, self.url())

        return self.run_and_check(session, prepped_request, extra_options=options)

    def check_response(self, response: Response) -> None:
        try:
            response.raise_for_status()
        except HTTPError:
            self.log.error("HTTP error: %s", response.reason)
            self.log.error(response.text)
            raise AirflowException(str(response.status_code) + ":" + response.reason)

    def run_and_check(
        self,
        session: Session,
        prepped_request: PreparedRequest,
        extra_options: dict[Any, Any],
    ) -> Any:
        settings = session.merge_environment_settings(
            prepped_request.url,
            proxies=session.proxies,
            stream=session.stream,
            verify=session.verify,
            cert=session.cert,
        )

        # Send the request.
        send_kwargs: dict[str, Any] = {
            "timeout": extra_options.get("timeout"),
            "allow_redirects": extra_options.get("allow_redirects", True),
        }
        send_kwargs.update(settings)

        try:
            response = session.send(prepped_request, **send_kwargs)

            if extra_options.get("check_response", True):
                self.check_response(response)
            return response

        except ConnectionError as ex:
            self.log.warning("%s Tenacity will retry to execute the operation", ex)
            raise ex
