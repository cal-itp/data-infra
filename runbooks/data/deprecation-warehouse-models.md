# Deleting / deprecating warehouse models

When a warehouse table becomes obsolete, we want to intentionally deprecate and delete it to avoid the risk that someone continues using outdated or incorrect data. Please follow the steps outlined here when performing a deletion or deprecation.

1. Check whether the model(s) you are deprecating has been accessed within the last two weeks:
```
SELECT date, timestamp, principal_email, job_type, query, referenced_table, destination_table,
FROM `cal-itp-data-infra.mart_audit.fct_bigquery_data_access_referenced_tables`
WHERE
  -- referenced table has format like 'projects/cal-itp-data-infra/datasets/staging/tables/<table name>'
  referenced_table LIKE "%<YOUR TABLE NAME HERE>%"
  -- use 2 weeks as recency interval
  AND date >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 WEEK)
  -- omit automated Metabase queries that are used for autocomplete functionality
  AND query NOT LIKE "-- Metabase%LIMIT 1000"
ORDER BY timestamp DESC
```

2. Post a warning in `#data-warehouse-devs` and any other relevant channels in Slack (this may vary by domain; for example, if deprecating a model related to GTFS quality, you may post in `#gtfs-quality`). Add the model to the deprecation tracking spreadsheet (link TK).
    * If the model had been recently accessed according to the query in step 1, give a 2-week warning and post suggestions for alternative similar models.
    * If the model had not been recently accessed, a 1-week warning, without suggested alternatives, is sufficient.

3. After the warning period is up, soft-delete the model(s):
    * Double check whether anyone has been accessing it. If so, perform additional outreach to the relevant users and only proceed once those users have confirmed a migration plan.
    * Delete the associated dbt code (SQL *and* YAML).
    * [Copy the model(s)](https://cloud.google.com/bigquery/docs/managing-tables#copying_a_single_source_table) to `<original model name>_deprecated`. You can leave the `_deprecated` copy in its current location (same dataset.) [Delete the original (non-`_deprecated`) model](https://cloud.google.com/bigquery/docs/managing-tables#deleting_a_table).
    * If you are deprecating an entire dataset/schema, remove it from Metabase at this point.

4. Wait again. If the model(s) had been recently accessed according to the query in step 1, wait 2 weeks; otherwise wait only 1 week. If during this second waiting period someone objects or identifies a problem, revert the soft deletion from step 3 and stop the deprecation process until that need is resolved.

5. [Hard delete the `_deprecated` copy of the model(s)](https://cloud.google.com/bigquery/docs/managing-tables#deleting_a_table).
