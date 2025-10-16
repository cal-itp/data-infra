{{ config(
    materialized='incremental',
    partition_by={
        'field': 'date',
        'data_type': 'date',
        'granularity': 'day',
    },
    on_schema_change='append_new_columns'
) }}

WITH fct_bigquery_data_access_unnested AS (
    SELECT *
      FROM {{ ref('fct_bigquery_data_access') }},
      UNNEST(fct_bigquery_data_access.referenced_tables) AS referenced_table
),

fct_bigquery_data_access_referenced_tables AS (
    SELECT
    * EXCEPT(referenced_tables)
    FROM fct_bigquery_data_access_unnested
)

SELECT * FROM fct_bigquery_data_access_referenced_tables
