import os
from datetime import datetime

from operators.ntd_xlsx_list_tabs_operator import NTDXLSXListTabsOperator
from operators.ntd_xlsx_to_gcs_operator import NTDXLSXToGCSOperator
from operators.ntd_xlsx_to_jsonl_operator import NTDXLSXToJSONLOperator

from airflow import DAG, XComArg
from airflow.decorators import task
from airflow.operators.latest_only import LatestOnlyOperator

NTD_PRODUCTS = [
    {
        "type": "annual_database_agency_information",
        "short_type": "_2022_agency_information",
        "year": 2022,
        "url": "https://www.transit.dot.gov/ntd/data-product/2022-annual-database-agency-information",
    },
]

with DAG(
    dag_id="download_and_parse_ntd_xlsx",
    # Every day at midnight
    schedule="0 0 * * *",
    start_date=datetime(2025, 11, 1),
    catchup=False,
    tags=["ntd"],
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    @task
    def create_download_kwargs(ntd_product):
        return {
            "source_url": ntd_product["url"],
            "destination_path": os.path.join(
                f"{ntd_product['type']}_raw",
                f"{ntd_product['year']}",
                "dt={{ dt }}",
                "execution_ts={{ ts }}",
                f"{ntd_product['year']}__{ntd_product['type']}_raw.xlsx",
            ),
        }

    download_kwargs = create_download_kwargs.expand(ntd_product=NTD_PRODUCTS)

    download_xlsx = NTDXLSXToGCSOperator(
        task_id="download_to_gcs",
        destination_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
    ).expand_kwargs(download_kwargs)

    xlsx_tabs = NTDXLSXListTabsOperator(
        task_id="ntd_xlsx_list_tabs",
        source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
    ).expand_kwargs(
        download_xlsx.map(lambda dl: {"source_path": dl["destination_path"]})
    )

    @task
    def create_parse_kwargs(xlsx_tab_ntd_products) -> dict:
        xlsx_tab, ntd_products = xlsx_tab_ntd_products
        tab_name = (
            xlsx_tab["tab"]
            .lower()
            .replace(" ", "_")
            .replace("(", "_")
            .replace(")", "_")
            .replace(":", "_")
            .replace("-", "_")
        )
        result = []
        for ntd_product in ntd_products:
            result.append(
                {
                    "tab": xlsx_tab["tab"],
                    "source_path": xlsx_tab["source_path"],
                    "destination_path": os.path.join(
                        ntd_product["type"],
                        ntd_product["year"],
                        xlsx_tab["tab"],
                        "dt={{ dt }}",
                        "execution_ts={{ ts }}",
                        f"{ntd_product['year']}__{ntd_product['type']}__{tab_name}.jsonl.gz",
                    ),
                }
            )
        return result

    parse_kwargs = create_parse_kwargs.expand(
        xlsx_tab=XComArg(xlsx_tabs).zip(fillvalue=NTD_PRODUCTS)
    )

    parse_xlsx = NTDXLSXToJSONLOperator.partial(
        task_id="xlsx_to_jsonl",
        source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
        destination_bucket=os.environ.get(
            "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"
        ),
    ).expand_kwargs(parse_kwargs)

    latest_only >> download_kwargs
