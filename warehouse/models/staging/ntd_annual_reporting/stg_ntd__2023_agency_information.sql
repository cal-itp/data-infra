WITH external_agency_information AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2023__annual_database_agency_information') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_agency_information
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__2023_agency_information AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    SAFE_CAST({{ trim_make_empty_string_null('number_of_state_counties') }} AS FLOAT) AS number_of_state_counties,
    {{ trim_make_empty_string_null('tam_tier') }} AS tam_tier,
    SAFE_CAST({{ trim_make_empty_string_null('personal_vehicles') }} AS FLOAT) AS personal_vehicles,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    {{ trim_make_empty_string_null('tribal_area_name') }} AS tribal_area_name,
    SAFE_CAST({{ trim_make_empty_string_null('service_area_sq_miles') }} AS FLOAT) AS service_area_sq_miles,
    SAFE_CAST({{ trim_make_empty_string_null('voms_do') }} AS FLOAT) AS voms_do,
    {{ trim_make_empty_string_null('url') }} AS url,
    SAFE_CAST({{ trim_make_empty_string_null('region') }} AS INTEGER) AS region,
    SAFE_CAST({{ trim_make_empty_string_null('state_admin_funds_expended') }} AS FLOAT) AS state_admin_funds_expended,
    SAFE_CAST({{ trim_make_empty_string_null('zip_code_ext') }} AS FLOAT) AS zip_code_ext,
    SAFE_CAST({{ trim_make_empty_string_null('zip_code') }} AS FLOAT) AS zip_code,
    {{ trim_make_empty_string_null('ueid') }} AS ueid,
    {{ trim_make_empty_string_null('address_line_2') }} AS address_line_2,
    SAFE_CAST({{ trim_make_empty_string_null('number_of_counties_with_service') }} AS FLOAT) AS number_of_counties_with_service,
    {{ trim_make_empty_string_null('reporter_acronym') }} AS reporter_acronym,
    SAFE_CAST({{ trim_make_empty_string_null('original_due_date') }} AS INTEGER) AS original_due_date,
    SAFE_CAST({{ trim_make_empty_string_null('sq_miles') }} AS FLOAT) AS sq_miles,
    {{ trim_make_empty_string_null('address_line_1') }} AS address_line_1,
    {{ trim_make_empty_string_null('p_o__box') }} AS p_o__box,
    {{ trim_make_empty_string_null('division_department') }} AS division_department,
    SAFE_CAST({{ trim_make_empty_string_null('fy_end_date') }} AS INTEGER) AS fy_end_date,
    SAFE_CAST({{ trim_make_empty_string_null('service_area_pop') }} AS FLOAT) AS service_area_pop,
    {{ trim_make_empty_string_null('state') }} AS state,
    {{ trim_make_empty_string_null('subrecipient_type') }} AS subrecipient_type,
    SAFE_CAST({{ trim_make_empty_string_null('primary_uza_uace_code') }} AS FLOAT) AS primary_uza_uace_code,
    {{ trim_make_empty_string_null('reported_by_name') }} AS reported_by_name,
    SAFE_CAST({{ trim_make_empty_string_null('population') }} AS FLOAT) AS population,
    {{ trim_make_empty_string_null('reporting_module') }} AS reporting_module,
    SAFE_CAST({{ trim_make_empty_string_null('volunteer_drivers') }} AS FLOAT) AS volunteer_drivers,
    {{ trim_make_empty_string_null('doing_business_as') }} AS doing_business_as,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    {{ trim_make_empty_string_null('legacy_ntd_id') }} AS legacy_ntd_id,
    SAFE_CAST({{ trim_make_empty_string_null('total_voms') }} AS INTEGER) AS total_voms,
    SAFE_CAST({{ trim_make_empty_string_null('fta_recipient_id') }} AS FLOAT) AS fta_recipient_id,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST({{ trim_make_empty_string_null('voms_pt') }} AS FLOAT) AS voms_pt,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    {{ trim_make_empty_string_null('agency_name') }} AS agency_name,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('reported_by_ntd_id') }} AS reported_by_ntd_id,
    SAFE_CAST({{ trim_make_empty_string_null('density') }} AS FLOAT) AS density,
    {{ trim_make_empty_string_null('state_parent_ntd_id') }} AS state_parent_ntd_id,
    dt,
    execution_ts
FROM stg_ntd__2023_agency_information
