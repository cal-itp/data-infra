WITH external_complete_monthly_ridership_with_adjustments_and_estimates AS (
    SELECT *
    FROM {{ source('external_ntd__ridership', 'historical__complete_monthly_ridership_with_adjustments_and_estimates') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_complete_monthly_ridership_with_adjustments_and_estimates
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates AS (
    SELECT
        {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
        {{ trim_make_empty_string_null('agency') }} AS agency,
        {{ trim_make_empty_string_null('tos') }} AS tos,
        {{ trim_make_empty_string_null('mode') }} AS mode,
        {{ trim_make_empty_string_null('agency_mode_tos_date') }} AS agency_mode_tos_date,
        SAFE_CAST(voms AS NUMERIC) AS voms,
        SAFE_CAST(upt AS NUMERIC) AS upt,
        {{ trim_make_empty_string_null('_3_mode') }} AS _3_mode,
        SAFE_CAST(vrm AS NUMERIC) AS vrm,
        {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
        SAFE_CAST(uace_cd AS NUMERIC) AS uace_cd,
        {{ trim_make_empty_string_null('fta_region') }} AS fta_region,
        {{ trim_make_empty_string_null('state') }} AS state,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        {{ trim_make_empty_string_null('mode_type_of_service_status') }} AS mode_type_of_service_status,
        SAFE_CAST(vrh AS NUMERIC) AS vrh,
        {{ trim_make_empty_string_null('legacy_ntd_id') }} AS legacy_ntd_id,
        SAFE_CAST(date AS DATETIME) AS date,
        dt,
        execution_ts,
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates
