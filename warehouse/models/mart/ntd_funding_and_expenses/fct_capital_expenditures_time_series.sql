WITH int_total AS (
    SELECT *
    FROM {{ ref('int_ntd__capital_expenditures_time_series_total') }}
),

int_rolling_stock AS (
    SELECT *
    FROM {{ ref('int_ntd__capital_expenditures_time_series_rolling_stock') }}
),

int_facilities AS (
    SELECT *
    FROM {{ ref('int_ntd__capital_expenditures_time_series_facilities') }}
),

int_other AS (
    SELECT *
    FROM {{ ref('int_ntd__capital_expenditures_time_series_other') }}
),

fct_capital_expenditures_time_series AS (
    SELECT
        -- key is 'ntd_id', 'year', 'legacy_ntd_id', 'mode'
        COALESCE(int_total.key, int_rolling_stock.key, int_facilities.key, int_other.key) AS key,
        COALESCE(int_total.ntd_id, int_rolling_stock.ntd_id, int_facilities.ntd_id, int_other.ntd_id) AS ntd_id,
        COALESCE(int_total.year, int_rolling_stock.year, int_facilities.year, int_other.year) AS year,
        COALESCE(int_total.legacy_ntd_id, int_rolling_stock.legacy_ntd_id, int_facilities.legacy_ntd_id, int_other.legacy_ntd_id) AS legacy_ntd_id,
        COALESCE(int_total.mode, int_rolling_stock.mode, int_facilities.mode, int_other.mode) AS mode,
        {{ generate_ntd_mode_full_name('int_total.mode') }} AS mode_full_name,

        int_total.agency_status,
        int_total.census_year,
        int_total.last_report_year,
        int_total.reporter_type,
        int_total.reporting_module,
        int_total.uace_code,
        int_total.uza_area_sq_miles,
        int_total.uza_name,
        int_total.uza_population,

        COALESCE(int_total.total, 0) AS total_capital_expenditures,
        COALESCE(int_rolling_stock.rolling_stock, 0) AS rolling_stock_expenditures,
        COALESCE(int_facilities.facilities, 0) AS facilities_expenditures,
        COALESCE(int_other.other, 0) AS other_expenditures,

        int_total._2024_mode_status,
        int_total.agency_name AS source_agency,
        int_total.city AS source_city,
        int_total.state AS source_state,
        int_total.dt,
        int_total.execution_ts,

    FROM int_total
    LEFT JOIN int_rolling_stock USING (key)
    LEFT JOIN int_facilities USING (key)
    LEFT JOIN int_other USING (key)
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE int_total.key NOT IN ('1dd913ef427f13b6c7f5d4c082319d1a','b1ee4eae111d285bf12594f7957f4d63','7c0b7bde854402586c8259b31900dcbc',
        '0aedbd11c7a3f1ab9a7a8c745b9f803c','516b52734b5ab3c449c6d6e01c1f3efa','bee58df2e3b7c3932800fa39faea69b3',
        '1728fcec5b9dc7f3da5a55477f89a2dd','89610c0b889d427b29c3bbbeec296590')
)

SELECT * FROM fct_capital_expenditures_time_series
