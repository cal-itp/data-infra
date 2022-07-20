{{ config(store_failures = true) }}

-- dst_table_name: "payments.invalid_cleaned_principal_customer_ids"
-- Each pricipal_customer_id should only ever have itself as a principal.

WITH principal_customer_ids AS (

    SELECT DISTINCT principal_customer_id
    FROM {{ ref('stg_cleaned_customers') }}

),

principal_customers AS (

    SELECT
        customer_id,
        principal_customer_id
    FROM {{ ref('stg_cleaned_customers') }}
    WHERE
        customer_id IN (
            SELECT principal_customer_id FROM principal_customer_ids
        )
),

validate_cleaned_principal_customer_ids AS (

    SELECT *
    FROM principal_customers
    WHERE customer_id != principal_customer_id
)

SELECT * FROM validate_cleaned_principal_customer_ids
