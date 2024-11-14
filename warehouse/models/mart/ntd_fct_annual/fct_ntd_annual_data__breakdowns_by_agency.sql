WITH staging_breakdowns_by_agency AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__breakdowns_by_agency') }}
),
-- test
fct_ntd_annual_data__breakdowns_by_agency AS (
    SELECT *
    FROM staging_breakdowns_by_agency
)

SELECT * FROM fct_ntd_annual_data__breakdowns_by_agency
