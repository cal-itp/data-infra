"""
Download the state of CA GTFS files, async version
"""
import requests
import logging
import zipfile
import io
import pathlib
import datetime
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
import gcsfs
from airflow.operators.email_operator import EmailOperator
import pandas as pd


def make_gtfs_list():
    """
    Read in a list of GTFS urls
    from the main db
    plus metadata
    kwargs:
     catalog = a intake catalog containing an "official_list" item.
    """
    df = pd.read_csv(
        (
            "https://docs.google.com/spreadsheets/d/"
            "1qr49azk6p30mp96_7myKoO-Bb_bXMMn5ZzgbL-uPiPw/gviz/"
            "tq?tqx=out:csv&sheet=Data"
        ),
        usecols=["ITP_ID", "GTFS", "Agency Name"],
        dtype={"ITP_ID": "float64"},
    )
    # TODO: Figure out what to do with Metro
    # For now, we just take the bus.

    # TODO: Replace URLs with Zip ones.
    # For now we filter, and then remove ones that don't contain
    # zip filters
    df = df[(df.GTFS.str.contains("zip")) & (df.GTFS.notnull())]
    return df


def clean_url(url):
    """
    take the list of urls, clean as needed.
    used as a pd.apply, so singleton.
    """
    # LA Metro split requires lstrip
    return url


def download_url(url, itp_id, gcs_project, **kwargs):
    """
    Download a URL as a task item
    using airflow. **kwargs are airflow
    """
    run_time = kwargs["execution_date"]
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4)"
            "AppleWebKit/537.36 (KHTML, like Gecko)"
            "Chrome/83.0.4103.97 Safari/537.36"
        )
    }
    try:
        r = requests.get(url, headers=headers)
        r.raise_for_status()
    except requests.exceptions.HTTPError as err:
        logging.warning(f"No feed found for {url}, {err}")
    try:
        z = zipfile.ZipFile(io.BytesIO(r.content))
        # replace here with s3fs
        fs = gcsfs.GCSFileSystem(project=gcs_project, token="cloud")
        path = f"/tmp/gtfs-data/{run_time}/{int(itp_id)}"
        pathlib.Path(path).mkdir(parents=True, exist_ok=True)
        z.extractall(path)
        fs.put(
            path, f"gs://gtfs-data/schedule/{run_time}/{int(itp_id)}", recursive=True
        )
    except zipfile.BadZipFile:
        logging.warning(f"failed to zipfile {url}")


default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": datetime.datetime(2021, 2, 15),
    "email": ["hunter.owens@dot.ca.gov"],
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": datetime.timedelta(minutes=2),
    "concurrency": 50
    # 'queue': 'bash_queue',
    # 'pool': 'backfill',
    # 'priority_weight': 10,
    # 'end_date': datetime(2016, 1, 1),
}


dag = DAG(
    dag_id="gtfs-downloader", default_args=default_args, schedule_interval="@daily"
)


def gen_list(**kwargs):
    """
    task callable to generate the list and push into
    xcom
    """
    provider_set = make_gtfs_list().apply(clean_url)
    return provider_set.to_dict("records")


generate_provider_list_task = PythonOperator(
    task_id="generating_provider_list", python_callable=gen_list, dag=dag
)


def downloader(**kwargs):
    provider_set = kwargs["task_instance"].xcom_pull(
        task_ids="generating_provider_list"
    )
    error_agencies = []
    for row in provider_set:
        print(row)
        try:
            download_url(row["GTFS"], row["ITP_ID"], "cal-itp-data-infra", **kwargs)
        except Exception as e:
            logging.warn(f"error downloading agency {row['Agency Name']}")
            logging.info(e)
            error_agencies.append(row["Agency Name"])
            continue
    logging.info(f"error agencies: {error_agencies}")
    kwargs["ti"].xcom_push(key="error_agencies", value=error_agencies)
    return error_agencies


download_to_gcs_task = PythonOperator(
    task_id="downloading_data",
    python_callable=downloader,
    dag=dag,
    provide_context=True,
)

email_error_agencies_task = EmailOperator(
    to=["ruth.miller@dot.ca.gov", "hunter.owens@dot.ca.gov"],
    html_content=(
        "The follow agencies failed to have GTFS at the url:"
        "{{ ti.xcom_pull(task_ids='download_to_gcs_task') }}"
        "{{ ds }}"
    ),
    subject="Operator GTFS Failure Update for",
    task_id="email_error",
    dag=dag,
    provide_context=True,
)
generate_provider_list_task >> download_to_gcs_task >> email_error_agencies_task
