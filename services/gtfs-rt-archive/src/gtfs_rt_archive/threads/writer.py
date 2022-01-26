import pathlib
import urllib.request
import urllib.error
import urllib.parse
from . import BaseWriter

class FSWriter(BaseWriter):

    name = "filewriter"

    def __init__(self, logger, wq, urlstr, secret=None):

        super().__init__(logger, wq, urlstr, secret)

        url = urllib.parse.urlparse(urlstr)
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
                f.write(txn["input_stream"]).read())
        except OSError as e:
            self.logger.critical("[txn {}] write: {}: {}".format(txn["id"], dest, e))
            return


class GCPBucketWriter(BaseWriter):

    name = "gswriter"
    baseurl = "https://storage.googleapis.com/upload/storage/v1/b"

    def __init__(self, logger, wq, urlstr, secret=None):

        super().__init__(logger, wq, urlstr, secret)

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

        url = urllib.parse.urlparse(urlstr)

        self.uploadurl = "{}/{}/o".format(self.baseurl, url.netloc)
        self.basepath = url.path

        while self.basepath.startswith("/"):
            self.basepath = self.basepath[1:]

        if self.basepath and not self.basepath.endswith("/"):
            self.basepath += "/"

    def write(self, name, txn):

        rqurl = "{}?uploadType=media&name={}{}".format(
            self.uploadurl, self.basepath, name
        )
        rqheaders = {"Content-Type": "application/octet-stream"}

        if self.session is None:

            rq = urllib.request.Request(
                rqurl, method="POST", headers=rqheaders, data=txn["input_stream"]
            )
            try:
                urllib.request.urlopen(rq)
            except (urllib.error.URLError, urllib.error.HTTPError) as e:
                self.logger.critical(
                    "[txn {}] error uploading to bucket {}: {}".format(
                        txn["id"], self.urlstr, e
                    )
                )

        else:

            try:
                self.session.request("POST", rqurl, data=txn["input_stream"], headers=rqheaders)
            except self.GoogleAuthTransportError as e:
                self.logger.critical(
                    "[txn {}] error uploading to bucket {}: {}".format(
                        txn["id"], self.urlstr, e
                    )
                )


if __name__ == "__main__":
    main(sys.argv)
