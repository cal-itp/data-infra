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
        -- consistent columns names as fct_operating_and_capital_funding_time_series

        SAFE_CAST({{ trim_make_empty_string_null('unnamed__0') }} AS INT64) AS year,
        SAFE_CAST({{ trim_make_empty_string_null('national_total') }} AS INT64) AS operating_national,
        SAFE_CAST({{ trim_make_empty_string_null('unnamed__2') }} AS INT64) AS capital_national,
        SAFE_CAST({{ trim_make_empty_string_null('unnamed__3') }} AS INT64) AS total_national,

        SAFE_CAST({{ trim_make_empty_string_null('federal') }} AS INT64) AS operating_federal,
        SAFE_CAST({{ trim_make_empty_string_null('unnamed__5') }} AS INT64) AS capital_federal,
        SAFE_CAST({{ trim_make_empty_string_null('unnamed__6') }} AS INT64) AS total_federal,

        SAFE_CAST({{ trim_make_empty_string_null('state') }} AS INT64) AS operating_state,
        SAFE_CAST({{ trim_make_empty_string_null('unnamed__8') }} AS INT64) AS capital_state,
        SAFE_CAST({{ trim_make_empty_string_null('unnamed__9') }} AS INT64) AS total_state,

        SAFE_CAST({{ trim_make_empty_string_null('local') }} AS INT64) AS operating_local,
        SAFE_CAST({{ trim_make_empty_string_null('unnamed__11') }} AS INT64) AS capital_local,
        SAFE_CAST({{ trim_make_empty_string_null('unnamed__12') }} AS INT64) AS total_local,

        SAFE_CAST({{ trim_make_empty_string_null('other') }} AS INT64) AS operating_other,
        SAFE_CAST({{ trim_make_empty_string_null('unnamed__14') }} AS INT64) AS capital_other,
        SAFE_CAST({{ trim_make_empty_string_null('unnamed__15') }} AS INT64) AS total_other,

        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__operating_and_capital_funding_time_series__summary_total
