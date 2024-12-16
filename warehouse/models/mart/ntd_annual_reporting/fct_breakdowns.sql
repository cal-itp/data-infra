WITH staging_breakdowns AS (
    SELECT *
    FROM {{ ref('stg_ntd__breakdowns') }}
),

fct_breakdowns AS (
    SELECT *
    FROM staging_breakdowns
)

SELECT * FROM fct_breakdowns
