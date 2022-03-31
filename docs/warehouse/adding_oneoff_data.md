# Adding One-Off Datasets
When looking to add one-off datasets to the warehouse, for use in applications like our BI tool Metabase, we can make use of the `uploaded_data` schema in Big Query. To write data here, we will first add the data to a Google Cloud Storage bucket, and then input the command below in the BigQuery terminal.

1. First, upload the data to a Google Cloud Storage bucket and make note of the path.

2. Next, navigate to the Bigquery console in the GCP platform. From here you will select the terminal (image below).

![Collection Matrix](assets/open_bq_terminal.png)

3. Once in the terminal, you will input the following command:
```{code-cell}
bq --location=us-west2 load <source_format> --autodetect --allow_quoted_newlines <destination_table> <source>
```

* The `<source_format>` specifies the type of file you would like to use. An example of this flag's use is `--source-format=CSV`. Other options include `PARQUET` and `NEWLINE_DELIMITED_JSON`

* The `<destination_table>` is the table you would like to create, or append to if the table already exists. These tables should always be in the `uploaded_data` schema in BiGquery, and begin with `uploaded_data.`

* The `<source>` argument is the path to the Google Cloud Storage bucket you are sourcing from.

Ex.
```{code-cell}
bq --location=us-west2 load --source_format=CSV --autodetect --allow_quoted_newlines uploaded_data.tircp_with_temporary_expenditure_sol_copy gs://calitp-analytics-data/data-analyses/tircp/tircp.csv
```

More information on the BQ CLI [can be found here](https://cloud.google.com/bigquery/docs/reference/bq-cli-reference)
