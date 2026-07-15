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
        -- Excel merged cells created unnamed columns, use visual inspection to match columns
        -- columns are operating total, capital total, grand total within each funding type
        {{ trim_make_empty_string_null('local') }} AS local_operating,
        {{ trim_make_empty_string_null('state') }} AS state_operating,
        {{ trim_make_empty_string_null('federal') }} AS federal_operating,
        {{ trim_make_empty_string_null('other') }} AS other_operating,
        {{ trim_make_empty_string_null('national_total') }} AS national_operating,
        {{ trim_make_empty_string_null('unnamed__0') }} AS year,
        {{ trim_make_empty_string_null('unnamed__2') }} AS national_capital,
        {{ trim_make_empty_string_null('unnamed__3') }} AS national_total,
        {{ trim_make_empty_string_null('unnamed__5') }} AS federal_capital,
        {{ trim_make_empty_string_null('unnamed__6') }} AS federal_total,
        {{ trim_make_empty_string_null('unnamed__8') }} AS state_capital,
        {{ trim_make_empty_string_null('unnamed__9') }} AS state_total,
        {{ trim_make_empty_string_null('unnamed__11') }} AS local_capital,
        {{ trim_make_empty_string_null('unnamed__12') }} AS local_total,
        {{ trim_make_empty_string_null('unnamed__14') }} AS other_capital,
        {{ trim_make_empty_string_null('unnamed__15') }} AS other_total,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__operating_and_capital_funding_time_series__summary_total
