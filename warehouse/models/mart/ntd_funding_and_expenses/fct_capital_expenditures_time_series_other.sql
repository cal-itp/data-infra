WITH int_ntd__capital_expenditures_time_series_other AS (
    SELECT *
    FROM {{ ref('int_ntd__capital_expenditures_time_series_other') }}
),

dim_agency_information AS (
    SELECT
        ntd_id,
        year,
        agency_name,
        city,
        state,
        caltrans_district_current,
        caltrans_district_name_current
    FROM {{ ref('dim_agency_information') }}
),

fct_capital_expenditures_time_series_other AS (
    SELECT
        int.key,
        int.ntd_id,
        int.year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        int.legacy_ntd_id,
        int.mode,
        int.agency_status,
        int.census_year,
        int.last_report_year,
        int.reporter_type,
        int.reporting_module,
        int.uace_code,
        int.uza_area_sq_miles,
        int.uza_name,
        int.uza_population,
        int.other,
        int._2023_mode_status,
        int.agency_name AS source_agency,
        int.city AS source_city,
        int.state AS source_state,
        int.dt,
        int.execution_ts
    FROM int_ntd__capital_expenditures_time_series_other AS int
    LEFT JOIN dim_agency_information AS agency
        ON int.ntd_id = agency.ntd_id
            AND int.year = agency.year
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE int.key NOT IN ('bee58df2e3b7c3932800fa39faea69b3','89610c0b889d427b29c3bbbeec296590','1728fcec5b9dc7f3da5a55477f89a2dd',
        '516b52734b5ab3c449c6d6e01c1f3efa','0aedbd11c7a3f1ab9a7a8c745b9f803c','7c0b7bde854402586c8259b31900dcbc',
        'b1ee4eae111d285bf12594f7957f4d63','1dd913ef427f13b6c7f5d4c082319d1a')
)

SELECT * FROM fct_capital_expenditures_time_series_other
