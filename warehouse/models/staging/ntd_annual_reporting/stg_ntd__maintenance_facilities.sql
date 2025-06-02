WITH external_maintenance_facilities AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__maintenance_facilities') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_maintenance_facilities
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__maintenance_facilities AS (
    SELECT
        SAFE_CAST(_200_to_300_vehicles AS NUMERIC) AS _200_to_300_vehicles,
        {{ trim_make_empty_string_null('_200_to_300_vehicles_1') }} AS _200_to_300_vehicles_1,
        {{ trim_make_empty_string_null('agency') }} AS agency,
        SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
        {{ trim_make_empty_string_null('city') }} AS city,
        SAFE_CAST(heavy_maintenance_facilities AS NUMERIC) AS heavy_maintenance_facilities,
        {{ trim_make_empty_string_null('heavy_maintenance_facilities_1') }} AS heavy_maintenance_facilities_1,
        SAFE_CAST(leased_by_pt_provider AS NUMERIC) AS leased_by_pt_provider,
        {{ trim_make_empty_string_null('leased_by_pt_provider_1') }} AS leased_by_pt_provider_1,
        SAFE_CAST(leased_by_public_agency AS NUMERIC) AS leased_by_public_agency,
        {{ trim_make_empty_string_null('leased_by_public_agency_1') }} AS leased_by_public_agency_1,
        SAFE_CAST(leased_from_a_private_entity AS NUMERIC) AS leased_from_a_private_entity,
        {{ trim_make_empty_string_null('leased_from_a_private_entity_1') }} AS leased_from_a_private_entity_1,
        SAFE_CAST(leased_from_a_public_entity AS NUMERIC) AS leased_from_a_public_entity,
        {{ trim_make_empty_string_null('leased_from_a_public_entity_1') }} AS leased_from_a_public_entity_1,
        {{ trim_make_empty_string_null('mode') }} AS mode,
        {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
        SAFE_CAST(mode_voms AS NUMERIC) AS mode_voms,
        {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
        {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
        SAFE_CAST(over_300_vehicles AS NUMERIC) AS over_300_vehicles,
        {{ trim_make_empty_string_null('over_300_vehicles_questionable') }} AS over_300_vehicles_questionable,
        SAFE_CAST(owned AS NUMERIC) AS owned,
        {{ trim_make_empty_string_null('owned_questionable') }} AS owned_questionable,
        SAFE_CAST(owned_by_pt_provider AS NUMERIC) AS owned_by_pt_provider,
        {{ trim_make_empty_string_null('owned_by_pt_provider_1') }} AS owned_by_pt_provider_1,
        SAFE_CAST(owned_by_public_agency AS NUMERIC) AS owned_by_public_agency,
        {{ trim_make_empty_string_null('owned_by_public_agency_1') }} AS owned_by_public_agency_1,
        SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
        SAFE_CAST(report_year AS INT64) AS report_year,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        {{ trim_make_empty_string_null('state') }} AS state,
        SAFE_CAST(total_facilities AS NUMERIC) AS total_facilities,
        {{ trim_make_empty_string_null('total_maintenance_facilities') }} AS total_maintenance_facilities,
        {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
        {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
        SAFE_CAST(under_200_vehicles AS NUMERIC) AS under_200_vehicles,
        {{ trim_make_empty_string_null('under_200_vehicles_1') }} AS under_200_vehicles_1,
        {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__maintenance_facilities
