# `create_external_tables`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the creation of [external tables](https://cloud.google.com/bigquery/docs/external-data-sources), which serve as the interface between our raw / parsed data (stored in Google Cloud Storage) and our data warehouse (BigQuery). Most of our external tables are [hive-partitioned](https://cloud.google.com/bigquery/docs/hive-partitioned-loads-gcs).

Here is an annotated example external table YAML file showing what the fields mean:

```yaml
# throughout this example, <> brackets denote sample content to be filled in based on your use case and should be removed 
operator: operators.ExternalTable   # the name of the operator; this does not change
bucket: "{{ env_var('<BUCKET_VARIABLE>') }}"    # fill in the environment variable pointing to your source data bucket here
post_hook: |    # this is optional; can provide an example query to check that external table was created successfully. this query will run every time the external table DAG runs
  SELECT *
  FROM `{{ get_project_id() }}`.<your dataset as defined below under destination_project_dataset_table>.<your table name as defined below under destination_project_dataset_table>
  LIMIT 1;
source_objects: # this tells the external table which path & file format to look in for the objects that will be queryable through this external table 
  - "<the top level folder name within your bucket that should be used for this external table like my_data>/*.<your file extension, most likely '.jsonl.gz'>"     
destination_project_dataset_table: "<desired dataset name like external_my_data_source>.<desired table name, may be like topic_name__specific_data_name>"   # this defines the external table name (dataset and table name) through which the data will be accessible in BigQuery
source_format: NEWLINE_DELIMITED_JSON   # file format of raw data; generally should not change -- allowable options are specified here: https://cloud.google.com/bigquery/docs/reference/rest/v2/tables#ExternalDataConfiguration.FIELDS.source_format
use_bq_client: true     # this option only exists for backwards compatibility; should always be true for new tables
hive_options:   # this section provides information about how hive-partitioning is used
  mode: CUSTOM  # options are CUSTOM and AUTO. if CUSTOM, you need to define the hive partitions and their datatypes in the source_uri_prefix below; if you use AUTO, you only need to provide the top-level directory in the source_uri_prefix
  require_partition_filter: false   # default is true: if true, users will have to provide a filter to query this data; false is usually fine except for very large data like GTFS-RT
  source_uri_prefix: "<the top level folder name within your bucket that should be used for this external table (should match what's entered in source_objects above)>/{<if CUSTOM under mode above: hive partition name: hive partition data type like 'dt:DATE'>}"    # this tells the hive partitioning where to look. if mode = CUSTOM, should be something like "my_data/{dt:DATE}/{ts:TIMESTAMP}/{some_label:STRING}/" with the entire hive path defined; if mode = AUTO, should be like "my_data/"
schema_fields:  # here you fill in the schema of the actual files, which will become the schema of the external table
# make one list item per column that you want to be available in BigQuery
# if there are columns in the source data that you don't want in BigQuery, you don't have to include them here
# hive partition path elements (like "date", if present) will be added as columns automatically and should not be specified here
# if you don't specify a schema, BigQuery will attempt to auto-detect the schema: https://cloud.google.com/bigquery/docs/schema-detect#schema_auto-detection_for_external_data_sources
  - name: <column_name>     # this should match the key name for this data in the source JSONL file; see https://cloud.google.com/bigquery/docs/schemas#column_names for BQ naming rules
    mode: <column mode>     # see https://cloud.google.com/bigquery/docs/schemas#modes
    type: <column data type>    # see https://cloud.google.com/bigquery/docs/schemas#standard_sql_data_types
  - name: <second_column_name>
    mode: <second column mode>
    type: <second column data type>
```

## Testing

When testing external table creation locally, pay attention to test environment details:
* External tables created by local Airflow will be created in the `cal-itp-data-infra-staging` environment. 
   * If you're trying to test dbt changes that rely on unmerged external tables changes, you can set the `DBT_SOURCE_DATABASE` environment variable to `cal-itp-data-infra-staging`. This will cause the dbt project to use the staging environment's externabl tables. If the staging external tables are pointed at a `test-` buckets (as described in the bullet above), then the dbt project will run on that test data, which may lead to unexpected results. 
   * For this reason, it is often easier to make external tables updates in one pull request, get that approved and merged, and then make dbt changes once the external tables are already updated in production so you can test on the production source data.
