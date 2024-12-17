WITH external_funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__funding_sources_taxes_levied_by_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_funding_sources_taxes_levied_by_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    agency,
    agency_voms,
    city,
    fuel_tax,
    income_tax,
    ntd_id,
    organization_type,
    other_funds,
    other_tax,
    primary_uza_population,
    property_tax,
    report_year,
    reporter_type,
    sales_tax,
    state,
    tolls,
    total,
    uace_code,
    uza_name,
    dt,
    execution_ts
FROM stg_ntd__funding_sources_taxes_levied_by_agency
