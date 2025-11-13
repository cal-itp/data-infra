WITH source AS (
    SELECT *
    FROM {{ source('external_ntd__funding_and_expenses', 'historical__operating_and_capital_funding_time_series__summary_total') }}
),

get_latest_extract AS(
    SELECT *
    FROM source
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__operating_and_capital_funding_time_series__summary_total AS (
    SELECT
        {{ trim_make_empty_string_null('local') }} AS local,
        {{ trim_make_empty_string_null('state') }} AS state,
        {{ trim_make_empty_string_null('federal') }} AS federal,
        {{ trim_make_empty_string_null('other') }} AS other,
        {{ trim_make_empty_string_null('national_total') }} AS national_total,
        {{ trim_make_empty_string_null('unnamed__0') }} AS unnamed__0,
        {{ trim_make_empty_string_null('unnamed__2') }} AS unnamed__2,
        {{ trim_make_empty_string_null('unnamed__3') }} AS unnamed__3,
        {{ trim_make_empty_string_null('unnamed__5') }} AS unnamed__5,
        {{ trim_make_empty_string_null('unnamed__6') }} AS unnamed__6,
        {{ trim_make_empty_string_null('unnamed__8') }} AS unnamed__8,
        {{ trim_make_empty_string_null('unnamed__9') }} AS unnamed__9,
        {{ trim_make_empty_string_null('unnamed__11') }} AS unnamed__11,
        {{ trim_make_empty_string_null('unnamed__12') }} AS unnamed__12,
        {{ trim_make_empty_string_null('unnamed__14') }} AS unnamed__14,
        {{ trim_make_empty_string_null('unnamed__15') }} AS unnamed__15,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__operating_and_capital_funding_time_series__summary_total
