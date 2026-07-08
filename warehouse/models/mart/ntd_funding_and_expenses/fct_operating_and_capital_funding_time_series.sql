WITH int_op_total AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_operating_total') }}
),

int_op_fed AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_operating_federal') }}
),

int_op_state AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_operating_state') }}
),

int_op_local AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_operating_local') }}
),

int_op_other AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_operating_other') }}
),

int_cap_total AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_capital_total') }}
),

int_cap_fed AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_capital_federal') }}
),

int_cap_state AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_capital_state') }}
),

int_cap_local AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_capital_local') }}
),

int_cap_other AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_capital_other') }}
),

fct_operating_and_capital_funding_time_series AS (
    SELECT
        -- key 'ntd_id', 'year', 'legacy_ntd_id'
        COALESCE(int_op_total.key, int_cap_total.key) AS key,
        COALESCE(int_op_total.ntd_id, int_cap_total.ntd_id) AS ntd_id,
        COALESCE(int_op_total.year, int_cap_total.year) AS year,
        COALESCE(int_op_total.legacy_ntd_id, int_cap_total.legacy_ntd_id) AS legacy_ntd_id,

        COALESCE(int_op_total.agency_status, int_cap_total.agency_status) AS agency_status,
        COALESCE(int_op_total.census_year, int_cap_total.census_year) AS census_year,
        COALESCE(int_op_total.last_report_year, int_cap_total.last_report_year) AS last_report_year,
        COALESCE(int_op_total.reporter_type, int_cap_total.reporter_type) AS reporter_type,
        COALESCE(int_op_total.reporting_module, int_cap_total.reporting_module) AS reporting_module,
        COALESCE(int_op_total.uace_code, int_cap_total.uace_code) AS uace_code,
        COALESCE(int_op_total.uza_area_sq_miles, int_cap_total.uza_area_sq_miles) AS uza_area_sq_miles,
        COALESCE(int_op_total.primary_uza_name, int_cap_total.primary_uza_name) AS primary_uza_name,
        COALESCE(int_op_total.uza_population, int_cap_total.uza_population) AS uza_population,
        COALESCE(int_op_total._2024_status, int_cap_total._2024_status) AS _2024_status,

        COALESCE(int_op_total.agency_name, int_cap_total.agency_name) AS source_agency,
        COALESCE(int_op_total.city, int_cap_total.city) AS source_city,
        COALESCE(int_op_total.state, int_cap_total.state) AS source_state,

        COALESCE(int_op_total.operating_total, 0) AS operating_total,
        COALESCE(int_op_fed.operating_federal, 0) AS operating_federal,
        COALESCE(int_op_state.operating_state, 0) AS operating_state,
        COALESCE(int_op_local.operating_local, 0) AS operating_local,
        COALESCE(int_op_other.operating_other, 0) AS operating_other,

        COALESCE(int_cap_total.capital_total, 0) AS capital_total,
        COALESCE(int_cap_fed.capital_federal, 0) AS capital_federal,
        COALESCE(int_cap_state.capital_state, 0) AS capital_state,
        COALESCE(int_cap_local.capital_local, 0) AS capital_local,
        COALESCE(int_cap_other.capital_other, 0) AS capital_other,

    FROM int_op_total
    FULL OUTER JOIN int_cap_total USING (key)
    LEFT JOIN int_op_fed USING (key)
    LEFT JOIN int_op_state USING (key)
    LEFT JOIN int_op_local USING (key)
    LEFT JOIN int_op_other USING (key)
    LEFT JOIN int_cap_fed USING (key)
    LEFT JOIN int_cap_state USING (key)
    LEFT JOIN int_cap_local USING (key)
    LEFT JOIN int_cap_other USING (key)
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE COALESCE(int_op_total.key, int_cap_total.key) NOT IN ('ceee48d5b549eacd30c16bc7af1ec79d','4c39c378621ca926c1e98efc929a64f9','7417b3a1931fc284be99824925f55d55',
        '21f4adad5adcd91c37292b036d47370d')
)

SELECT * FROM fct_operating_and_capital_funding_time_series
