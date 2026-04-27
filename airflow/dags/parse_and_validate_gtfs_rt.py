import os
from base64 import urlsafe_b64encode, urlsafe_b64decode
from datetime import datetime, timedelta

from dags import log_failure_to_slack

from airflow.decorators import dag, task, task_group
from airflow.operators.dummy import DummyOperator
from airflow.operators.latest_only import LatestOnlyOperator

from airflow.providers.google.cloud.operators.gcs import GCSListObjectsOperator
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from airflow.utils.trigger_rule import TriggerRule

from operators.gtfs_rt_feed_to_jsonl_operator import GTFSRTFeedToJSONLOperator

GTFS_RT_FEED_TYPES = ["service_alerts", "trip_updates", "vehicle_positions"]

@dag(
    # Every hour at 15 minutes past the hour
    schedule="15 * * * *",
    start_date=datetime(2026, 4, 27),
    catchup=False,
    tags=["gtfs", "gtfs-rt"],
    user_defined_macros={"urlsafe_b64encode": urlsafe_b64encode, "urlsafe_b64decode": urlsafe_b64decode},
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": True,
        "email_on_retry": False,
        "on_failure_callback": log_failure_to_slack,
    },
)
def parse_and_validate_gtfs_rt():
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    task_groups = []
    for feed_type in GTFS_RT_FEED_TYPES:
        @task_group(group_id=feed_type)
        def process_feed_type_hour():
            list_feeds = GCSListObjectsOperator(
                task_id=f"list_{feed_type}",
                bucket=os.environ["CALITP_BUCKET__GTFS_RT_RAW"].removeprefix("gs://"),
                prefix=os.path.join(
                    feed_type,
                    "dt={{ data_interval_end | ds }}",
                    "hour={{ data_interval_end.replace(minute=0, second=0, microsecond=0) | ts }}",
                ),
            )

            def make_feed_paths(feed_path):
                base64_url = os.path.basename(os.path.dirname(feed_path)).removeprefix("base64_url=")
                return {
                    "source_path": feed_path,
                    "destination_path": os.path.join(
                        "{{ feed_type }}",
                        "dt={{ data_interval_end | ds }}"
                        "hour={{ data_interval_end.replace(minutes=0) | ts }}",
                        "base64_url={{ base64_url }}",
                        f"{{ feed_type }}_{base64_url}.jsonl"
                    ),
                    "report_path": os.path.join(
                        "{{ feed_type }}",
                        "dt={{ data_interval_end | ds }}"
                        "hour={{ data_interval_end.replace(minutes=0) | ts }}",
                        f"{{ feed_type }}_{base64_url}.jsonl"
                    ),
                }

            parse_feeds = GTFSRTFeedToJSONLOperator.partial(
                task_id=f"parse_{feed_type}",
                source_bucket=os.environ["CALITP_BUCKET__GTFS_RT_RAW"],
                destination_bucket=os.environ["CALITP_BUCKET__GTFS_RT_PARSED"],
            ).expand_kwargs(list_feeds.map(make_feed_paths))

            @task
            def unique_decoded_urls(prefixes) -> list[str]:
                urls = []
                for prefix in prefixes:
                    url = urlsafe_b64decode(os.path.basename(os.path.dirname(prefix)).removeprefix("base64_url=")).decode()
                    if url not in urls:
                        urls.append(url)
                return urls

            urls = unique_decoded_urls(list_feeds.output)

            def make_url_feed_globs(url):
                return {
                    "match_glob": f"**/base64_url={urlsafe_b64encode(url.encode()).decode()}/*",
                    "map_index_template": url,
                }

            url_feeds = GCSListObjectsOperator.partial(
                task_id=f"list_url_{feed_type}",
                bucket=os.environ["CALITP_BUCKET__GTFS_RT_RAW"].removeprefix("gs://"),
                prefix=os.path.join(
                    feed_type,
                    "dt={{ data_interval_end | ds }}",
                    "hour={{ data_interval_end.replace(minute=0, second=0, microsecond=0) | ts }}",
                ),
            ).expand_kwargs(urls.map(make_url_feed_globs))

            @task
            def get_schedule_path(url_feeds):
                return GCSHook().get_metadata(
                    bucket_name=os.environ["CALITP_BUCKET__GTFS_RT_RAW"].removeprefix("gs://"),
                    object_name=url_feeds[0]
                )

            schedule_path = get_schedule_path(url_feeds)

            # def make_validate_paths(feed_path):
            #     return {

            #     }

            # validate_feeds = ValidateGTFSToGCSOperator.partial(
            #     task_id=f"validate_{feed_type}",
            #     source_bucket=os.getenv("CALITP_BUCKET__GTFS_RT_RAW"),
            #     schedule_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            #     destination_bucket=os.getenv("CALITP_BUCKET__GTFS_RT_VALIDATION"),
            # ).expand_kwargs(url_feeds.map(make_validate_paths))

            list_feeds >> (
                parse_feeds,
                list_url_feeds >> validate_feeds
            )
        task_groups.append(process_feed_type_hour())

    latest_only >> task_groups

parse_and_validate_gtfs_rt = parse_and_validate_gtfs_rt()
