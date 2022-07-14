{{ config(materialized='table') }}

WITH stg_cleaned_customers AS (
    SELECT DISTINCT
        customer_id,
        principal_customer_id
    FROM {{ ref('stg_enriched_customer_funding_source') }}
    WHERE calitp_dupe_number = 1
        AND calitp_customer_id_rank = 1
)

SELECT * FROM stg_cleaned_customers
