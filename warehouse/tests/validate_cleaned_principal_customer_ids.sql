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
