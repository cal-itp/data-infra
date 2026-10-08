import atexit
import functools
import logging
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

# Point Airflow at a throwaway home and SQLite metadata DB before airflow is
# imported, so every test session starts from an empty database regardless of
# whatever is in ~/airflow (stale task instances, or a schema left behind by a
# different Airflow version, make runs non-idempotent).
_AIRFLOW_HOME = tempfile.mkdtemp(prefix="airflow-pytest-")
atexit.register(shutil.rmtree, _AIRFLOW_HOME, ignore_errors=True)
os.environ["AIRFLOW_HOME"] = _AIRFLOW_HOME
os.environ["AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"] = (
    f"sqlite:///{os.path.join(_AIRFLOW_HOME, 'airflow.db')}"
)
os.environ["AIRFLOW__CORE__LOAD_EXAMPLES"] = "False"

import google.auth._refresh_worker  # noqa: E402
import pytest  # noqa: E402
import urllib3  # noqa: E402
from vcr.stubs import VCRConnection, VCRHTTPResponse  # noqa: E402
from vcr.stubs import requests_stubs as vcr_requests_stubs  # noqa: E402
from vcr.stubs import urllib3_stubs as vcr_urllib3_stubs  # noqa: E402

from airflow.models import DagBag, DagRun  # noqa: E402
from airflow.models.connection import Connection  # noqa: E402

# Register the FAB ab_user table in the ORM metadata (TaskInstanceNote has a FK
# to it); otherwise a test module run on its own fails to flush task instances.
from airflow.providers.fab.auth_manager import models as _fab_models  # noqa: E402,F401
from airflow.settings import Session  # noqa: E402

sys.path.append(os.path.join(os.path.dirname(__file__), "../plugins"))


class _VCRUrllib3ResponseMixin:
    """Make vcrpy's urllib3 connection stubs behave like urllib3 2.x connections.

    urllib3 2.x expects ``HTTPConnection.getresponse()`` to return a
    ``urllib3.response.HTTPResponse``, which is what applies ``Content-Encoding``
    (gzip/deflate/...) for callers such as requests and google-resumable-media.
    vcrpy's stub returns its bare ``VCRHTTPResponse`` instead, so compressed
    bodies stored in cassettes are replayed undecoded. Wrap the played response
    the same way urllib3 wraps a real one. When recording, ask urllib3 for the
    raw body so cassettes keep the response verbatim (still compressed), which
    is consistent with the Content-Encoding header that gets recorded with it.
    """

    def request(
        self,
        method,
        url,
        body=None,
        headers=None,
        *,
        chunked=False,
        preload_content=True,
        decode_content=True,
        enforce_content_length=True,
        **kwargs,
    ):
        # bypass VCRConnection.__setattr__, which also sets it on the real conn
        object.__setattr__(
            self,
            "_vcr_response_options",
            {
                "preload_content": preload_content,
                "decode_content": decode_content,
                "enforce_content_length": enforce_content_length,
                "request_method": method,
                "request_url": url,
            },
        )
        return VCRConnection.request(self, method, url, body, headers)

    def getresponse(self, *args, **kwargs):
        real_connection = self.real_connection
        real_request = real_connection.request
        real_connection.request = functools.partial(
            real_request, preload_content=True, decode_content=False
        )
        try:
            response = VCRConnection.getresponse(self, *args, **kwargs)
        finally:
            del real_connection.request
        options = self.__dict__.pop("_vcr_response_options", None)
        if options is None or not isinstance(response, VCRHTTPResponse):
            return response
        return urllib3.response.HTTPResponse(
            body=response,
            headers=urllib3.HTTPHeaderDict(response.msg.items()),
            status=response.status,
            reason=response.reason,
            original_response=response,
            **options,
        )


for _stubs in (vcr_requests_stubs, vcr_urllib3_stubs):
    for _name in ("VCRRequestsHTTPConnection", "VCRRequestsHTTPSConnection"):
        _cls = getattr(_stubs, _name)
        setattr(_stubs, _name, type(_name, (_VCRUrllib3ResponseMixin, _cls), {}))

_real_put_conn = urllib3.connectionpool.HTTPConnectionPool._put_conn


def _put_conn(self, conn):
    # A vcrpy stub connection is bound to the cassette active when it was
    # created. Now that responses are real urllib3 responses, they release their
    # connection back to the pool, where a later test could pick up a stub that
    # still plays/records against the previous test's cassette. Never pool
    # stubs; the next request gets a fresh one bound to the current cassette.
    if isinstance(conn, VCRConnection):
        conn.close()
        conn = None
    return _real_put_conn(self, conn)


urllib3.connectionpool.HTTPConnectionPool._put_conn = _put_conn

# google-auth refreshes "stale" tokens (and, in releases newer than the Composer
# image's, looks up regional access boundaries) on background threads. Those
# requests go to vcr's ignore_hosts, and vcrpy sends ignored requests inside
# force_reset(), which globally un-patches and re-patches the connection
# classes. Done from another thread, that races the test's own requests and can
# leave a previous test's cassette patched in. Use google-auth's synchronous
# code paths instead, on the calling thread.
google.auth._refresh_worker.RefreshThreadManager.start_refresh = (
    lambda self, cred, request: False  # False -> blocking refresh fallback
)
try:
    from google.auth import _regional_access_boundary_utils
except ImportError:  # google-auth in the Composer image predates it
    pass
else:

    def _blocking_rab_refresh(self, credentials, request, rab_manager):
        rab_manager.start_blocking_refresh(credentials, request)

    _regional_access_boundary_utils._RegionalAccessBoundaryRefreshManager.start_refresh = (
        _blocking_rab_refresh
    )

# vcrpy logs every request/response it plays back at INFO, which dumps large
# (often base64-encoded) bodies into captured logs; only surface its warnings.
logging.getLogger("vcr").setLevel(logging.WARNING)


def pytest_sessionstart(session):
    subprocess.run([sys.executable, "-m", "airflow", "db", "init"], check=True)


def get_most_recent_dag_run(dag_id: str):
    dag_runs = DagRun.find(dag_id=dag_id)
    dag_runs.sort(key=lambda x: x.execution_date, reverse=True)
    return dag_runs[0] if dag_runs else None


def get_dag(dag_bag: DagBag, file_name: str, dag_id: str):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    filepath = os.path.join(current_directory, "fixture_dags", file_name)
    dag_bag.process_file(filepath=filepath)
    assert dag_bag.import_errors == {}
    return dag_bag.get_dag(dag_id)


@pytest.fixture(scope="session")
def dag_bag() -> DagBag:
    current_directory = os.path.dirname(os.path.realpath(__file__))
    dag_folder = pathlib.Path(current_directory) / "fixture_dags"
    dag_bag = DagBag(include_examples=False, dag_folder=dag_folder, collect_dags=False)
    assert dag_bag.import_errors == {}
    return dag_bag


FILTER_BODY_STRINGS: list = [
    (os.environ.get("KUBA_PASSWORD"), "FILTERED"),
]


def scrub_request(request):
    for body_string, replacement in FILTER_BODY_STRINGS:
        if request.body and body_string and replacement:
            request.body = request.body.replace(
                str.encode(body_string), str.encode(replacement)
            )
    return request


@pytest.fixture(scope="module")
def vcr_config():
    return {
        "allow_playback_repeats": True,
        "before_record_request": scrub_request,
        "filter_headers": [
            ("cookie", "FILTERED"),
            ("Authorization", "FILTERED"),
            ("apikey", "FILTERED"),
            ("X-CKAN-API-Key", "FILTERED"),
            ("Granicus-Auth", "FILTERED"),
        ],
        "filter_query_parameters": [
            ("api_key", "FILTERED"),
        ],
        "ignore_hosts": [
            "run-actions-1-azure-eastus.actions.githubusercontent.com",
            "run-actions-2-azure-eastus.actions.githubusercontent.com",
            "run-actions-3-azure-eastus.actions.githubusercontent.com",
            "sts.googleapis.com",
            "iamcredentials.googleapis.com",
            "oauth2.googleapis.com",
        ],
    }


def add_connection(session, **kwargs):
    session.add(Connection(**kwargs))
    session.commit()


def clean_connections(session, conn_id: str):
    existing_connections = (
        session.query(Connection).filter(Connection.conn_id == conn_id).all()
    )
    for connection in existing_connections:
        session.delete(connection)
    session.commit()


@pytest.fixture(scope="session", autouse=True)
def setup_module():
    session = Session()
    clean_connections(session, "http_kuba")
    add_connection(
        session,
        conn_id="http_kuba",
        conn_type="http",
        host="https://proxima-demo.pptexcellence.com/",
        login="monitoringAPI",
        password=os.environ.get("KUBA_PASSWORD"),
        schema="66",
    )
    clean_connections(session, "airtable_default")
    add_connection(
        session,
        conn_id="airtable_default",
        conn_type="generic",
        password=os.environ.get("CALITP_AIRTABLE_PERSONAL_ACCESS_TOKEN"),
    )
    clean_connections(session, "airtable_issue_management")
    add_connection(
        session,
        conn_id="airtable_issue_management",
        conn_type="generic",
        password=os.environ.get("CALITP_AIRTABLE_ISSUE_MANAGEMENT_TOKEN"),
    )
    clean_connections(session, "http_ntd")
    add_connection(
        session,
        conn_id="http_ntd",
        conn_type="http",
        host="https://data.transportation.gov",
    )
    clean_connections(session, "http_blackcat")
    add_connection(
        session,
        conn_id="http_blackcat",
        conn_type="http",
        host="https://services.blackcattransit.com",
    )
    clean_connections(session, "http_mobility_database")
    add_connection(
        session,
        conn_id="http_mobility_database",
        conn_type="http",
        host="https://bit.ly/catalogs-csv",
    )
    clean_connections(session, "http_transitland")
    add_connection(
        session,
        conn_id="http_transitland",
        conn_type="http",
        host="https://transit.land/api/v2/rest/feeds",
        extra={"apikey": os.environ.get("TRANSITLAND_API_KEY")},
    )
    clean_connections(session, "http_ckan")
    add_connection(
        session,
        conn_id="http_ckan",
        conn_type="https",
        host="test-data.technology.ca.gov",
        password=os.environ.get("CKAN_API_KEY"),
    )
    clean_connections(session, "http_dot")
    add_connection(
        session,
        conn_id="http_dot",
        conn_type="https",
        host="https://www.transit.dot.gov",
    )
