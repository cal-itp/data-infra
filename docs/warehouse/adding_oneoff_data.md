(adding-data-to-warehouse)=
# Adding Ad-Hoc Data to the Warehouse
To work with data in our BI tool ([Metabase](https://dashboards.calitp.org/)) we first have to add the data to our warehouse ([BigQuery](https://console.cloud.google.com/bigquery)). This page describes how to do an ad-hoc, one-time import of a dataset (for example, an individual extract from some other system that you want to access in the warehouse or in Metabase.)

```{admonition} Warning
If you are looking to create a new data pipeline for a data source that needs to be updated regularly (for example, a new data source to be ingested daily or weekly), you should follow the [general data pipeline architecture](architecture-data)
```


To add data to BigQuery for use in Metabase follow the instructions below. You may need additional Google Cloud or BigQuery permissions; if so, post in the `#services-team` channel in Slack to ask for assistance. The general process involves uploading data to Google Cloud Storage and then making that data available in the `uploaded_data` dataset in BigQuery.

1. First, upload your data to a [Google Cloud Storage](https://console.cloud.google.com/storage/browser/calitp-analytics-data) bucket in the `gs://calitp-analytics-data/data-analyses/` directory and make note of the `gsutil URI` (file path).

2. Next, navigate to a [JupyterLab](https://notebooks.calitp.org/) terminal window.

3. Once in the terminal, input the following command with the appropriate structure:
```
bq --location=us-west2 load <source_format> --autodetect <destination_table> <source>
```

* The **`<source_format>`** specifies the type of file you would like to use. An example of this flag's use is `--source_format=CSV`. Other options include `PARQUET` and `NEWLINE_DELIMITED_JSON`

* The **`<destination_table>`** is the table you would like to create, or append to if the table already exists. Your uploaded table destination should always be the `uploaded_data` dataset in BigQuery (e.g. the `destination_table` name should always have the format `uploaded_data.your_new_table_name`).
  * If you are looking to **create a new table**: use a new table name
  * If you are looking to **append to existing data**: re-use the name of the existing table
  * If you are looking to **replace an existing table**: use the `--replace` flag after the `load` command

* The **`<source>`** argument is the `gsutil URI` (the path to the Google Cloud Storage bucket you are sourcing from).

* If you run into upload errors related to the source file format, you may need to include the flag `--allow_quoted_newlines`. This may be helpful in resolving errors related to newline-delimited text, which may be present in file conversions from Excel to CSV.

Ex.
```
bq --location=us-west2 load --source_format=CSV --autodetect --allow_quoted_newlines uploaded_data.tircp_with_temporary_expenditure_sol_copy gs://calitp-analytics-data/data-analyses/tircp/tircp.csv
```

```{admonition} Looking for more information?
More information on the BigQuery Command Line Interface (CLI) [can be found here](https://cloud.google.com/bigquery/docs/reference/bq-cli-reference)
```
