{{ config(materialized='table') }}

WITH audit_fct_bigquery_data_access AS (
    SELECT * 
    FROM {{ ref('stg_audit__cloudaudit_googleapis_com_data_access') }}
)

SELECT * FROM audit_fct_bigquery_data_access
