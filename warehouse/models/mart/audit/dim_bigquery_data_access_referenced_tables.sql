{{ config(materialized='table') }}

WITH fct_bigquery_data_access_unnested AS (
    SELECT * FROM {{ ref('fct_bigquery_data_access') }}
    LEFT JOIN UNNEST(fct_bigquery_data_access.referenced_tables) AS referenced_table
),

fct_bigquery_data_access_referenced_tables AS (
    SELECT * EXCEPT(referenced_tables)
    FROM fct_bigquery_data_access_unnested
)

SELECT * FROM fct_bigquery_data_access_referenced_tables
