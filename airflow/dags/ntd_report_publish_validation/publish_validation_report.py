# ---
# python_callable: publish_report
# provide_context: true
# ---
from google.cloud import bigquery
import pandas as pd
import datetime
import re

import google.auth
import google.auth.transport.requests

import pendulum
from calitp_data_infra.storage import (
    fetch_all_in_partition,
    get_fs,
)


def publish_report():
    client = bigquery.Client()
    print("Got BG client!")
    project = "cal-itp-data-infra-staging"
    dataset_id = "staging_staging"

    dataset_ref = bigquery.DatasetReference(project, dataset_id)
    table_ref = dataset_ref.table("fct_ntd_rr20_service_checks")
    table = client.get_table(table_ref)
    print("Got table!")

    df = client.list_rows(table).to_dataframe()
    print("Got df from BQ!")
    print(df.head())


    # this_year=datetime.datetime.now().year
    # ## Part 1: save Excel file to GCS (for emailing to subrecipients)
    # GCS_FILE_PATH_VALIDATED = f"gs://calitp-ntd-report-validation/validation_reports_{this_year}" 
    # with pd.ExcelWriter(f"{GCS_FILE_PATH_VALIDATED}/rr20_service_check_report_{this_date}.xlsx") as writer:
    #     rr20_checks.to_excel(writer, sheet_name="rr20_checks_full", index=False, startrow=2)

    #     workbook = writer.book
    #     worksheet = writer.sheets["rr20_checks_full"]
    #     cell_highlight = workbook.add_format({
    #         'fg_color': 'yellow',
    #         'bold': True,
    #         'border': 1
    #     })
    #     report_title = "NTD Data Validation Report"
    #     title_format = workbook.add_format({
    #             'bold': True,
    #             'valign': 'center',
    #             'align': 'left',
    #             'font_color': '#1c639e',
    #             'font_size': 15
    #             })
    #     subtitle = "Reduced Reporting RR-20: Validation Warnings"
    #     subtitle_format = workbook.add_format({
    #         'bold': True,
    #         'align': 'left',
    #         'font_color': 'black',
    #         'font_size': 19
    #         })
        
    #     worksheet.write('A1', report_title, title_format)
    #     worksheet.merge_range('A2:C2', subtitle, subtitle_format)
    #     worksheet.write('G3', 'Agency Response', cell_highlight)
    #     worksheet.write('H3', 'Response Date', cell_highlight)
    #     worksheet.set_column(0, 0, 35) #col A width
    #     worksheet.set_column(1, 3, 22) #cols B-D width
    #     worksheet.set_column(4, 4, 11) #col D width
    #     worksheet.set_column(5, 6, 53) #col E-G width
    #     worksheet.freeze_panes('B4')
    

