import gzip
from typing import ClassVar, List, Optional

import clickhouse_connect
import pandas as pd
import pendulum
import typer
from calitp_data_infra.storage import (  # , make_name_bq_safe
    PartitionedGCSArtifact,
    get_fs,
)

CALITP_BUCKET__SENTRY_EVENTS = "test"  # os.environ["CALITP_BUCKET__SENTRY_EVENTS"]


def process_arrays_for_nulls(arr):
    """
    BigQuery doesn't allow arrays that contain null values --
    see: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#array_nulls
    Therefore we need to manually replace nulls with falsy values according
    to the type of data in the array.
    """
    types = set(type(entry) for entry in arr if entry is not None)

    if not types:
        return []
    # use empty string for all non-numeric types
    # may need to expand this over time
    filler = -1 if types <= {int, float} else ""
    return [x if x is not None else filler for x in arr]


def make_arrays_bq_safe(raw_data):
    safe_data = {}
    for k, v in raw_data.items():
        if isinstance(v, dict):
            v = make_arrays_bq_safe(v)
        elif isinstance(v, list):
            v = process_arrays_for_nulls(v)
        safe_data[k] = v
    return safe_data


'''
def fetch_events_for_issue(issue_id, headers):
    response_data = []
    next_url = f"{SENTRY_API_BASE_URL}/issues/{issue_id}/events/"

    while next_url:
        response = requests.get(next_url, headers=headers)
        response_data.extend(response.json())
        if "next" in response.links:
            if response.links["next"]["results"] == "true":
                next_url = response.links["next"]["url"]
            else:
                next_url = None
        else:
            next_url = None

    print(f"Retrieved {len(response_data)} events for issue {issue_id}")
    return response_data


def get_issues_list_from_sentry(project_slug, headers, target_date_string):
    """
    Paginate over Sentry issues for a project and create a list of issues matching our
    criteria for examination (RTFetchExceptions).
    """
    next_url = f"{SENTRY_API_BASE_URL}/projects/sentry/{project_slug}/issues/?query=lastSeen:>{target_date_string}T00:00:00-00:00"
    response_data = []

    while next_url:
        response = requests.get(next_url, headers=headers)
        response_data.extend(response.json())
        if "next" in response.links:
            if response.links["next"]["results"] == "true":
                next_url = response.links["next"]["url"]
            else:
                next_url = None
        else:
            next_url = None

    issues_list = [x["id"] for x in response_data if "RTFetchException" in x["title"]]
    return issues_list


def iterate_over_sentry_records(project_slug, target_date_string, auth_token):
    """
    Paginate over API responses for each targeted issue and create a combined list of dicts.
    """
    headers = {"Authorization": "Bearer " + auth_token}
    issues_list = get_issues_list_from_sentry(project_slug, headers, target_date_string)

    print(f"Issues list includes {len(issues_list)} issues")
    combined_response_data = []

    with ThreadPoolExecutor(max_workers=4) as pool:
        futures: Dict[Future, List[Dict]] = {
            pool.submit(
                fetch_events_for_issue, headers=headers, issue_id=issue_id
            ): issue_id
            for issue_id in issues_list
        }

        for future in as_completed(futures):
            combined_response_data.extend(future.result())

    combined_response_data = [
        x
        for x in combined_response_data
        if pendulum.from_format(
            x["dateCreated"][:-1], "YYYY-MM-DDTHH:mm:ss"
        ).to_date_string()
        == target_date_string
    ]
    return combined_response_data
'''


def fetch_and_clean_from_clickhouse(project_slug, target_date):
    """
    Download Sentry event records as a DataFrame.
    """

    # print(f"Downloading Sentry event data for project {project_slug}")
    # target_date_string = target_date.to_date_string()
    client = clickhouse_connect.get_client(host="localhost", port=8123)
    all_rows = client.query_df(
        f"""SELECT * FROM errors_dist
                                   WHERE message like '%RTFetchException%'
                                   and toDate(timestamp) == '{target_date}'"""
    )

    extract = SentryExtract(
        project_slug=project_slug,
        dt=target_date,
        execution_ts=pendulum.now(),
        filename="events.jsonl.gz",
        data=all_rows,
    )

    return extract


class SentryExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CALITP_BUCKET__SENTRY_EVENTS
    table: ClassVar[str] = "events"
    dt: pendulum.Date
    execution_ts: pendulum.DateTime
    partition_names: ClassVar[List[str]] = ["project_slug", "dt", "execution_ts"]
    project_slug: str
    data: Optional[pd.DataFrame]

    class Config:
        arbitrary_types_allowed = True

    def save_to_gcs(self, fs):
        """
        raw_df = pd.DataFrame([{**make_arrays_bq_safe(row)} for row in self.data])
        cleaned_df = raw_df.rename(make_name_bq_safe, axis="columns")
        """

        self.save_content(
            fs=fs,
            content=gzip.compress(
                self.data.to_json(
                    orient="records", lines=True, default_handler=str
                ).encode()
            ),
            exclude={"data"},
        )


'''
class SentryToGCSOperator(BaseOperator):
    template_fields = ("bucket",)

    def __init__(
        self,
        bucket,
        project_slug,
        auth_token=None,
        **kwargs,
    ):
        """
        An operator that downloads data from a specific issue within a Sentry instance
        and saves it as a JSON file hive-partitioned by date and time in Google Cloud
        Storage (GCS).

        Args:
            bucket (str): GCS bucket where the scraped Sentry issue will be saved.
            project_slug (str): The identifier for the Sentry project being examined.
            auth_token (str, optional): The auth token to use when downloading from Sentry.
                This can be someone's personal auth token. If not provided, the environment
                variable of `CALITP_SENTRY_AUTH_TOKEN` is used.
        """
        self.bucket = bucket
        self.project_slug = project_slug
        self.auth_token = auth_token

        super().__init__(**kwargs)
'''


def main(
    project_slug: str,
    logical_date: str,
):
    target_date = pendulum.from_format(logical_date, "YYYY-MM-DDTHH:mm:ssZ").date()
    extract = fetch_and_clean_from_clickhouse(project_slug, target_date)
    fs = get_fs()
    return extract.save_to_gcs(fs=fs)


if __name__ == "__main__":
    typer.run(main)
