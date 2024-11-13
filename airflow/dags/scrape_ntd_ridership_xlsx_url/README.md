# `scrape_ntd_ridership_xlsx_url`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

Because the URL changes everytime the monthly NTD ridership data is published to DOT portal in the form of an XLSX file download link, this dag scrapes the web page for the current URL before ingestion and saves it as an environment variable in the composer environment.
