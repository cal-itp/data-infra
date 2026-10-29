import os
import ssl
from email.message import Message
from urllib.parse import urlparse

from gtfs_rt_archiver.configuration import Configuration
from requests import Request, Response, Session
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.poolmanager import PoolManager

CERTIFICATE_PATH = os.path.join(
    os.path.dirname(os.path.dirname(__file__)), "certificates"
)


class HostnameIgnoringHTTPSAdapter(HTTPAdapter):
    def __init__(self, cafile: str, *args, **kwargs) -> None:
        self.cafile: str = cafile
        super().__init__(*args, **kwargs)

    def init_poolmanager(self, *args, **kwargs) -> None:
        if os.path.isfile(self.cafile):
            context = ssl.create_default_context(cafile=self.cafile)
            kwargs["assert_hostname"] = False
            kwargs["ssl_context"] = context
        self.poolmanager = PoolManager(*args, **kwargs)


class Result:
    def __init__(
        self,
        configuration: Configuration,
        response: Response = None,
    ) -> None:
        self.configuration: Configuration = configuration
        self.response: Response = response

    def code(self) -> int | None:
        return self.response.status_code

    def headers(self) -> dict:
        return dict(self.response.headers)

    def content(self) -> str:
        return self.response.content

    def mime_type(self) -> str:
        return self.response.headers.get("Content-Type", "application/octet-stream")

    def attachment_filename(self) -> str:
        msg = Message()
        msg["content-disposition"] = self.headers().get(
            "Content-Disposition", "attachment"
        )
        return msg.get_filename()

    def filename(self) -> str:
        filename = self.attachment_filename()
        if not filename:
            filename = "feed"
        return filename

    def metadata(self) -> dict:
        return {
            "filename": self.filename(),
            "ts": self.configuration.ts(),
            "config": self.configuration.json(),
            "response_code": self.code(),
            "response_headers": self.headers(),
        }


class Downloader:
    def __init__(
        self, configuration: Configuration, certificate_path: str = CERTIFICATE_PATH
    ) -> None:
        self.configuration: Configuration = configuration
        self.certificate_path: str = certificate_path

    def request(self) -> Request:
        return Request(
            "GET",
            self.configuration.url,
            params=self.configuration.params(),
            headers=self.configuration.headers(),
        )

    def hostname(self) -> str:
        return urlparse(self.configuration.url).netloc

    def cafile(self) -> str:
        return os.path.join(self.certificate_path, f"{self.hostname()}.pem")

    def options(self) -> dict:
        return {
            "allow_redirects": True,
            "timeout": (
                int(
                    os.environ.get(
                        "REQUEST_CONNECT_TIMEOUT",
                        os.environ.get("REQUEST_TIMEOUT", "5"),
                    )
                ),
                int(
                    os.environ.get(
                        "REQUEST_READ_TIMEOUT", os.environ.get("REQUEST_TIMEOUT", "5")
                    )
                ),
            ),
        }

    def get(self) -> None:
        session: Session = Session()
        adapter: HTTPAdapter = HostnameIgnoringHTTPSAdapter(cafile=self.cafile())
        session.mount("https://", adapter)
        prepped_request = session.prepare_request(self.request())
        response = session.send(prepped_request, **self.options())
        response.raise_for_status()
        return Result(configuration=self.configuration, response=response)
