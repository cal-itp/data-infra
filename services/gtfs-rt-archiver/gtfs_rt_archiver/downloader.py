import os

from gtfs_rt_archiver.configuration import Configuration
from requests import Request, Response, Session

cert_ca_path = os.path.join(
    os.path.dirname(os.path.dirname(os.path.realpath(__file__))), "cert.ca"
)
request_connect_timeout = int(
    os.environ.get("REQUEST_CONNECT_TIMEOUT", os.environ.get("REQUEST_TIMEOUT", "5"))
)
request_read_timeout = int(
    os.environ.get("REQUEST_READ_TIMEOUT", os.environ.get("REQUEST_TIMEOUT", "5"))
)


class Result:
    def __init__(
        self,
        configuration: Configuration,
        response: Response = None,
        exception: str = None,
    ) -> None:
        self.configuration: Configuration = configuration
        self.response: Response = response
        self.exception: str = exception

    def code(self) -> int | None:
        if self.response is not None:
            return self.response.status_code

    def headers(self) -> dict:
        if self.response is not None:
            return dict(self.response.headers)

    def content(self) -> str:
        if self.response is not None:
            return self.response.content

    def mime_type(self) -> str:
        if self.response is not None:
            return self.response.headers.get("Content-Type", "application/octet-stream")

    def metadata(self) -> dict:
        return {
            "filename": "feed",
            "ts": self.configuration.ts(),
            "config": self.configuration.json(),
            "response_code": self.code(),
            "response_headers": self.headers(),
        }


class Downloader:
    def __init__(self, configuration: Configuration) -> None:
        self.configuration: Configuration = configuration

    def request(self) -> Request:
        return Request(
            "GET",
            self.configuration.url,
            params=self.configuration.params(),
            headers=self.configuration.headers(),
        )

    def get(self) -> None:
        session: Session = Session()
        prepped_request = session.prepare_request(self.request())
        response = session.send(
            prepped_request,
            allow_redirects=True,
            timeout=(request_connect_timeout, request_read_timeout),
            verify=cert_ca_path,
        )
        try:
            response.raise_for_status()
        except Exception as e:
            return Result(configuration=self.configuration, exception=e)
        return Result(configuration=self.configuration, response=response)
