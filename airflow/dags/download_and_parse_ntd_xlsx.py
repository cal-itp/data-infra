import os
from datetime import datetime

from operators.ntd_xlsx_to_gcs_operator import NTDXLSXToGCSOperator
from operators.ntd_xlsx_to_jsonl_operator import NTDXLSXToJSONLOperator

from airflow import DAG
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

    for ntd_product in NTD_PRODUCTS:
        download_xlsx = NTDXLSXToGCSOperator(
            task_id=f"{ntd_product['type']}_{ntd_product['year']}_to_gcs",
            source_url=ntd_product["url"],
            source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
            source_path=os.path.join(
                f"{ntd_product['type']}_raw",
                f"{ntd_product['year']}",
                "dt={{ dt }}",
                "execution_ts={{ ts }}",
                f"{ntd_product['year']}__{ntd_product['type']}_raw.xlsx",
            ),
        )

        xlsx_tabs = NTDXLSXListTabsOperator(
            task_id=f"{ntd_product['type']}_{ntd_product['year']}_tabs",
            source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
            source_path=os.path.join(
                f"{ntd_product['type']}_raw",
                f"{ntd_product['year']}",
                "dt={{ dt }}",
                "execution_ts={{ ts }}",
                f"{ntd_product['year']}__{ntd_product['type']}_raw.xlsx",
            ),
        )

        def parse_xlsx_kwargs(xlsx_tab) -> dict:
            return {
                "destination_path": os.path.join(
                    f"{xlsx_tab['type']}",
                    f"{xlsx_tab['year']}",
                    f"{xlsx_tab['tab']}",
                    "dt={{ dt }}",
                    "execution_ts={{ ts }}",
                    f"{xlsx_tab['year']}__{xlsx_tab['type']}__{xlsx_tab['tab']}.jsonl.gz",
                ),
            }

        parse_xlsx = NTDXLSXToJSONLOperator.partial(
            task_id=f"{ntd_product['type']}_{ntd_product['year']}_to_jsonl",
            source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
            source_path=os.path.join(
                f"{ntd_product['type']}_raw",
                f"{ntd_product['year']}",
                "dt={{ dt }}",
                "execution_ts={{ ts }}",
                f"{ntd_product['year']}__{ntd_product['type']}_raw.xlsx",
            ),
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"
            ),
        ).expand_kwargs(XComArg(xlsx_tabs).map(parse_xlsx_kwargs))

        latest_only >> download_xlsx >> xlsx_tabs
