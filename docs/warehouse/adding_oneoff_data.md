# Adding One-Off Datasets
To work with data in our BI tool ([Metabase](https://dashboards.calitp.org/)) we first have to add the data to our warehouse ([BigQuery](https://console.cloud.google.com/bigquery)). To add data to BigQuery for use in Metabase follow the instructions below.

*Not sure if you have the appropriate permissions to write tables in BigQuery?* Reach out to Charlie <a href="https://cal-itp.slack.com/team/U027GAVHFST" target="_blank">on Cal-ITP Slack using this link</a>.

When uploading data to the warehouse we will make use of the `uploaded_data` dataset in Big Query as our destination. To write data here we will first add the data to a Google Cloud Storage bucket and then input the command below in the BigQuery terminal.

1. First, upload your data to a [Google Cloud Storage](https://console.cloud.google.com/storage/browser/calitp-analytics-data) bucket and make note of the path.

2. Next, navigate to a JupyterLab terminal window.

3. Once in the terminal, input the following command with the appropriate structure:
```
bq --location=us-west2 load <source_format> --autodetect <destination_table> <source>
```

* The `<source_format>` specifies the type of file you would like to use. An example of this flag's use is `--source-format=CSV`. Other options include `PARQUET` and `NEWLINE_DELIMITED_JSON`

* The `<destination_table>` is the table you would like to create, or append to if the table already exists. These tables should always be in the `uploaded_data` schema in BiGquery, and begin with `uploaded_data.`

* The `<source>` argument is the path to the Google Cloud Storage bucket you are sourcing from.

* If you run into upload errors related to the source format, you may need to include the flag `--allow_quoted_newlines`. This may be helpful in resolving errors related to file conversions from Excel to CSV.

Ex.
```
bq --location=us-west2 load --source_format=CSV --autodetect --allow_quoted_newlines uploaded_data.tircp_with_temporary_expenditure_sol_copy gs://calitp-analytics-data/data-analyses/tircp/tircp.csv
```

If you are looking to **create a new table**: use a new table name for `<destination_table>`

If you are looking to **append to existing data**: use the table name of the existing `<destination_table>`

If you are looking to **replace an existing table**: the existing table will need to be deleted in BigQuery and re-uploaded with the previous `<destination_table>` name

```{admonition} Looking for more information?
More information on the BigQuery Command Line Interface (CLI) [can be found here](https://cloud.google.com/bigquery/docs/reference/bq-cli-reference)
```
