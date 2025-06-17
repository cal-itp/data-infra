WITH staging_breakdowns_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__breakdowns_by_agency') }}
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

fct_breakdowns_by_agency AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.count_major_mechanical_failures_questionable,
        stg.count_other_mechanical_failures_questionable,
        stg.count_total_mechanical_failures_questionable,
        stg.count_train_miles_questionable,
        stg.count_train_revenue_miles_questionable,
        stg.count_vehicle_passenger_car_miles_questionable,
        stg.max_agency_voms,
        stg.max_organization_type,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_uace_code,
        stg.max_uza_name,
        stg.sum_major_mechanical_failures,
        stg.sum_other_mechanical_failures,
        stg.sum_total_mechanical_failures,
        stg.sum_train_miles,
        stg.sum_train_revenue_miles,
        stg.sum_vehicle_passenger_car_miles,
        stg.sum_vehicle_passenger_car_revenue,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_breakdowns_by_agency AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_breakdowns_by_agency
