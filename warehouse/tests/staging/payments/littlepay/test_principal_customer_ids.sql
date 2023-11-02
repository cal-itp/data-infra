{{ config(store_failures = true) }}

-- Each principal_customer_id should only ever have itself as a principal.

WITH principal_customer_ids AS (

    SELECT DISTINCT principal_customer_id
    FROM {{ ref('int_littlepay__customers') }}

),

principal_customers AS (

    SELECT
        customer_id,
        principal_customer_id
    FROM {{ ref('int_littlepay__customers') }}
    WHERE
        customer_id IN (
            SELECT principal_customer_id FROM principal_customer_ids
        )
),

validate_cleaned_principal_customer_ids AS (

    SELECT *
    FROM principal_customers
    WHERE customer_id != principal_customer_id
    -- Unknown circumstance causes transactions that appear legitimate to map to a two-level
    -- principal_customer_id relationship, which we're ignoring en lieu of a clear reason
    AND customer_id != '983c9dc0-e546-448f-8bf1-115e32231e16'
)

SELECT * FROM validate_cleaned_principal_customer_ids
