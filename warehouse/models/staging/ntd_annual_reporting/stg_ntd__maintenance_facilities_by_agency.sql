WITH external_maintenance_facilities_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__maintenance_facilities_by_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_maintenance_facilities_by_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__maintenance_facilities_by_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    {{ trim_make_empty_string_null('max_agency') }} AS agency,
    SAFE_CAST(max_agency_voms AS NUMERIC) AS max_agency_voms,
    {{ trim_make_empty_string_null('max_city') }} AS city,
    {{ trim_make_empty_string_null('max_organization_type') }} AS max_organization_type,
    SAFE_CAST(max_primary_uza_population AS NUMERIC) AS max_primary_uza_population,
    {{ trim_make_empty_string_null('max_reporter_type') }} AS max_reporter_type,
    {{ trim_make_empty_string_null('max_state') }} AS state,
    {{ trim_make_empty_string_null('max_uace_code') }} AS max_uace_code,
    {{ trim_make_empty_string_null('max_uza_name') }} AS max_uza_name,
    {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
    SAFE_CAST(report_year AS INT64) AS report_year,
    SAFE_CAST(sum_200_to_300_vehicles AS NUMERIC) AS sum_200_to_300_vehicles,
    SAFE_CAST(sum_heavy_maintenance_facilities AS NUMERIC) AS sum_heavy_maintenance_facilities,
    SAFE_CAST(sum_leased_by_pt_provider AS NUMERIC) AS sum_leased_by_pt_provider,
    SAFE_CAST(sum_leased_by_public_agency AS NUMERIC) AS sum_leased_by_public_agency,
    SAFE_CAST(sum_leased_from_a_private_entity AS NUMERIC) AS sum_leased_from_a_private_entity,
    SAFE_CAST(sum_leased_from_a_public_entity AS NUMERIC) AS sum_leased_from_a_public_entity,
    SAFE_CAST(sum_over_300_vehicles AS NUMERIC) AS sum_over_300_vehicles,
    SAFE_CAST(sum_owned AS NUMERIC) AS sum_owned,
    SAFE_CAST(sum_owned_by_pt_provider AS NUMERIC) AS sum_owned_by_pt_provider,
    SAFE_CAST(sum_owned_by_public_agency AS NUMERIC) AS sum_owned_by_public_agency,
    SAFE_CAST(sum_total_facilities AS NUMERIC) AS sum_total_facilities,
    SAFE_CAST(sum_under_200_vehicles AS NUMERIC) AS sum_under_200_vehicles,
    dt,
    execution_ts
FROM stg_ntd__maintenance_facilities_by_agency
