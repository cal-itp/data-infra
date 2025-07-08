WITH staging_vehicles_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__vehicles_age_distribution') }}
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

fct_vehicles_age_distribution AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.vehicle_type,
        stg._0,
        stg._1,
        stg._10,
        stg._11,
        stg._12,
        stg._13_15,
        stg._16_20,
        stg._2,
        stg._21_25,
        stg._26_30,
        stg._3,
        stg._31_60,
        stg._4,
        stg._5,
        stg._6,
        stg._60,
        stg._7,
        stg._8,
        stg._9,
        stg.agency_voms,
        stg.average_age_of_fleet_in_years,
        stg.average_lifetime_miles_per,
        stg.organization_type,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_vehicles,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_vehicles_age_distribution AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
    -- remove bad rows
    WHERE stg.key NOT IN ('f8662a87cef6728dc5d415898ea961bc','362599715156a4b8a87e996e27fa7c66','300ad6405ebdad622b98c1e1464a097a',
        'a2630b40e2986baeb869d6d2ddc157b6','5ce449ed74e71f9d2eb9213096d8e418','9b5c848686f7fa944fcff8c9583b83cd',
        'c3abf27c17d79938826fcc0a5141dbfc','818d59d339e05f42c0996942a99d22ba','9d1d578074774050bc18ff6a637f6567',
        '3f3359e99a866a62616c42ea3e712b27','f95c3dbb9c8afa819633f6324eee5666','b10bdbf9b36af9d6d43dae09b465cefb',
        '3f68825803bd7f731ec76a8a2f06aef3','81c30900ef731ccdf1695c665c457d31','aa4a5909f80c759050da8e38191f8cb5',
        'cc141bc5bbccafe985ac6cb8a0b6cf16')
)

SELECT * FROM fct_vehicles_age_distribution
