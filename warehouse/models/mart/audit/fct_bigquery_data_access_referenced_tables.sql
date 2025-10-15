{{ config(materialized='table') }}

WITH fct_bigquery_data_access_unnested AS (
    SELECT *
      FROM {{ ref('fct_bigquery_data_access') }},
      UNNEST(fct_bigquery_data_access.referenced_tables) AS referenced_table
),

fct_bigquery_data_access_referenced_tables AS (
    SELECT
    * EXCEPT(referenced_tables),
        -- Use principal_email if present, otherwise principal_subject
        COALESCE(NULLIF(principal_email, ''), principal_subject) AS email,
        SPLIT(destination_table, '/')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(destination_table, '/')) - 1)] AS destination_table_name
    FROM fct_bigquery_data_access_unnested
)

SELECT * FROM fct_bigquery_data_access_referenced_tables
