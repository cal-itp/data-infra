WITH staging_breakdowns_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__breakdowns_by_agency') }}
),

fct_breakdowns_by_agency AS (
    SELECT *
    FROM staging_breakdowns_by_agency
)

SELECT * FROM fct_breakdowns_by_agency
