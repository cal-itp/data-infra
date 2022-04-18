{{ config(materialized='table') }}

WITH validation_notices_clean AS (
    SELECT *
    FROM {{ ref('validation_notices_clean') }}
),
validation_dim_codes AS (
  -- TODO: if a future version of the validator changes a codes severity
  -- we will end up with multiple entries for code (our primary key)
  -- we either need to change track this table, or use only the most recent
  -- levels of code x severity
  SELECT DISTINCT code, severity
  FROM validation_notices_clean
)

SELECT * FROM validation_dim_codes
