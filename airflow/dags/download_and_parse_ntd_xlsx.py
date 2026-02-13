import os
from datetime import datetime

from dags import log_failure_to_slack
from operators.ntd_xlsx_list_tabs_operator import NTDXLSXListTabsOperator
from operators.ntd_xlsx_to_gcs_operator import NTDXLSXToGCSOperator
from operators.ntd_xlsx_to_jsonl_operator import NTDXLSXToJSONLOperator

from airflow import DAG
from airflow.decorators import task
from airflow.operators.latest_only import LatestOnlyOperator

NTD_PRODUCTS = [
    {
        "type": "annual_database_agency_information",
        "url": "/ntd/data-product/2022-annual-database-agency-information",
        "year": "2022",
    },
    {
        "type": "annual_database_agency_information",
        "url": "/ntd/data-product/2023-annual-database-agency-information",
        "year": "2023",
    },
    {
        "type": "annual_database_agency_information",
        "url": "/ntd/data-product/2024-annual-database-agency-information",
        "year": "2024",
    },
    {
        "type": "asset_inventory_time_series",
        "url": "/ntd/data-product/ts41-asset-inventory-time-series-4",
        "year": "historical",
    },
    {
        "type": "annual_database_contractual_relationship",
        "url": "/ntd/data-product/2022-annual-database-contractual-relationship",
        "year": "2022",
    },
    {
        "type": "annual_database_contractual_relationship",
        "url": "/ntd/data-product/2023-annual-database-contractual-relationship",
        "year": "2023",
    },
    {
        "type": "annual_database_contractual_relationship",
        "url": "/ntd/data-product/2024-annual-database-contractual-relationship",
        "year": "2024",
    },
    {
        "type": "capital_expenditures_time_series",
        "url": "/ntd/data-product/ts31-capital-expenditures-time-series-2",
        "year": "historical",
    },
    {
        "type": "operating_and_capital_funding_time_series",
        "url": "/ntd/data-product/ts12-operating-funding-time-series-3",
        "year": "historical",
    },
    {
        "type": "service_data_and_operating_expenses_time_series_by_mode",
        "url": "/ntd/data-product/ts21-service-data-and-operating-expenses-time-series-mode-2",
        "year": "historical",
    },
]

with DAG(
    dag_id="download_and_parse_ntd_xlsx",
    # Every day at midnight
    schedule="0 0 * * *",
    start_date=datetime(2025, 11, 1),
    catchup=False,
    tags=["ntd"],
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": True,
        "email_on_retry": False,
        "on_failure_callback": log_failure_to_slack,
    },
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    @task
    def create_download_kwargs(ntd_product):
        return {
            "type": ntd_product["type"],
            "year": ntd_product["year"],
            "source_url": ntd_product["url"],
            "destination_path": os.path.join(
                f"{ntd_product['type']}_raw",
                f"{ntd_product['year']}",
                "dt={{ dag_run.start_date | ds }}",
                "execution_ts={{ dag_run.start_date | ts }}",
                f"{ntd_product['year']}__{ntd_product['type']}_raw.xlsx",
            ),
        }

    download_kwargs = create_download_kwargs.expand(ntd_product=NTD_PRODUCTS)

    download_xlsx = NTDXLSXToGCSOperator(
        task_id="download_to_gcs",
        dt="{{ dag_run.start_date | ds }}",
        execution_ts="{{ dag_run.start_date | ts }}",
        destination_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
    ).expand_kwargs(download_kwargs)

    def create_xlsx_tabs_kwargs(download) -> dict:
        return {
            "type": download["type"],
            "year": download["year"],
            "dt": download["dt"],
            "execution_ts": download["execution_ts"],
            "source_path": download["destination_path"],
        }

    xlsx_tabs = NTDXLSXListTabsOperator(
        task_id="ntd_xlsx_list_tabs",
        source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
    ).expand_kwargs(download_xlsx.output.map(create_xlsx_tabs_kwargs))

    def create_parse_kwargs(tab) -> dict:
        return {
            "tab": tab["tab_name"],
            "source_path": tab["source_path"],
            "destination_path": os.path.join(
                tab["type"],
                tab["year"],
                tab["tab_path"],
                f"dt={tab['dt']}",
                f"execution_ts={tab['execution_ts']}",
                f"{tab['year']}__{tab['type']}__{tab['tab_path']}.jsonl.gz",
            ),
        }

    parse_xlsx = NTDXLSXToJSONLOperator.partial(
        task_id="xlsx_to_jsonl",
        source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
        destination_bucket=os.environ.get(
            "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"
        ),
    ).expand_kwargs(xlsx_tabs.output.map(create_parse_kwargs))

    latest_only >> download_kwargs >> xlsx_tabs >> parse_xlsx
