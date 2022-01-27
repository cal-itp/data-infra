import pathlib
import threading
import logging
import urllib.request
import urllib.error
import urllib.parse
from . import BaseWriter


class FSWriter(BaseWriter):

    name = "filewriter"

    def __init__(self, logger, wq, desturl, secret=None):

        super().__init__(logger, wq, desturl, secret)

        url = urllib.parse.urlparse(desturl)
        self.basepath = pathlib.Path(url.path)

    def write(self, name, txn):

        dest = pathlib.Path(self.basepath, name)

        if self.basepath == pathlib.Path("/dev/null"):
            dest = self.basepath

        try:
            dest.parent.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            self.logger.critical("{}: mkdir: {}: {}".format(self.name, dest.parent, e))
            return

        try:
            with dest.open(mode="wb") as f:
                f.write(txn["input_stream"].read())
                self.logger.debug("[txn {}] completed write".format(txn["id"]))
        except OSError as e:
            self.logger.critical(
                "[txn {}] write error: {}: {}".format(txn["id"], dest, e)
            )
            return


class GCPBucketWriter(BaseWriter):

    name = "gswriter"
    baseurl = "https://storage.googleapis.com/upload/storage/v1/b"

    def __init__(self, logger, wq, desturl, secret=None):

        super().__init__(logger, wq, desturl, secret)

        self.session = None

        if self.secret is not None:
            from google.oauth2 import service_account
            from google.auth.transport.requests import AuthorizedSession
            from google.auth.exceptions import TransportError

            scopes = ["https://www.googleapis.com/auth/devstorage.read_write"]
            credentials = service_account.Credentials.from_service_account_file(
                secret, scopes=scopes
            )
            self.session = AuthorizedSession(credentials)
            self.GoogleAuthTransportError = TransportError

        url = urllib.parse.urlparse(desturl)

        self.uploadurl = "{}/{}/o".format(self.baseurl, url.netloc)
        self.basepath = url.path

        while self.basepath.startswith("/"):
            self.basepath = self.basepath[1:]

        if self.basepath and not self.basepath.endswith("/"):
            self.basepath += "/"

        logging.getLogger("urllib3.connectionpool").setLevel(logging.ERROR)

    def _get_requester(self, name, txn):

        logger = self.logger
        GoogleAuthTransportError = self.GoogleAuthTransportError
        session = self.session

        def _urllib_requester(rq):
            try:
                urllib.request.urlopen(rq)
                logger.debug("[txn {}] completed write".format(txn["id"]))
            except (urllib.error.URLError, urllib.error.HTTPError) as e:
                logger.critical(
                    "[txn {}] error uploading to bucket {}: {}".format(
                        txn["id"], rq.full_url, e
                    )
                )

        def _googleauth_requester(url, headers):
            try:
                session.request("POST", url, data=txn["input_stream"], headers=headers)
                logger.debug("[txn {}] completed write".format(txn["id"]))
            except GoogleAuthTransportError as e:
                logger.critical(
                    "[txn {}] error uploading to bucket {}: {}".format(
                        txn["id"], url, e
                    )
                )

        if name == "urllib":
            return _urllib_requester
        elif name == "googleauth":
            return _googleauth_requester
        else:
            raise ValueError(name)

    def write(self, name, txn):

        rqurl = "{}?uploadType=media&name={}{}".format(
            self.uploadurl, self.basepath, name
        )
        rqheaders = {"Content-Type": "application/octet-stream"}

        if self.session is None:

            rq = urllib.request.Request(
                rqurl, method="POST", headers=rqheaders, data=txn["input_stream"]
            )
            rqer = self._get_requester("urllib", txn)
            threading.Thread(target=rqer, args=(rq,)).start()

        else:

            rqer = self._get_requester("googleauth", txn)
            threading.Thread(target=rqer, args=(rqurl, rqheaders)).start()
