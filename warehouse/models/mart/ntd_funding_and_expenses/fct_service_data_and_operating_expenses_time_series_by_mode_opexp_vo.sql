WITH int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_vo AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_vo') }}
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

fct_service_data_and_operating_expenses_time_series_by_mode_opexp_vo AS (
    SELECT
        int.key,
        int.ntd_id,
        int.year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        int.mode,
        int.type_of_service,
        int.agency_status,
        int.census_year,
        int.last_report_year,
        int.mode_status,
        int.reporter_type,
        int.reporting_module,
        int.uace_code,
        int.uza_area_sq_miles,
        int.primary_uza_name,
        int.uza_population,
        int.opexp_vo,
        int.agency_name AS source_agency,
        int.city AS source_city,
        int.state AS source_state,
        int.dt,
        int.execution_ts
    FROM int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_vo AS int
    LEFT JOIN dim_agency_information AS agency
        ON int.ntd_id = agency.ntd_id
            AND int.year = agency.year
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE int.key NOT IN ('da108425cb2696446aa1017bca72340f','7d3e30725b3fa42c6d1722308f9cc855','e41f3812655066d28ec4bbc851545517',
        'f5f160d19e3753e3a99d9ad55b4f2210','98692053a5a16aae8ef8e2579f19b8a3','73f01d2aa1c268ec1dafbcf1fdaa84fc',
        'a31019318eddb35b747ab79470e10017','5b13563073a95faa05c9da4f77c0b3a8','c3ae0b0299c10ffa25e1193404762136',
        '564993fcc3a920cc0800005f3af9fd73','0fab2ef186a2a74edc98d16427d4d61a','d6809f84a9d19808f8b1f013fc1cd537')
)

SELECT * FROM fct_service_data_and_operating_expenses_time_series_by_mode_opexp_vo
