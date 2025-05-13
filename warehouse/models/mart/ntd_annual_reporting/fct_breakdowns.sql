WITH staging_breakdowns AS (
    SELECT *
    FROM {{ ref('stg_ntd__breakdowns') }}
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

fct_breakdowns AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.report_year', 'stg.mode', 'stg.type_of_service']) }} AS key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.agency_voms,
        stg.major_mechanical_failures,
        stg.major_mechanical_failures_1,
        stg.mode,
        stg.mode_name,
        stg.mode_voms,
        stg.organization_type,
        stg.other_mechanical_failures,
        stg.other_mechanical_failures_1,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_mechanical_failures,
        stg.total_mechanical_failures_1,
        stg.train_miles,
        stg.train_miles_questionable,
        stg.train_revenue_miles,
        stg.train_revenue_miles_1,
        stg.type_of_service,
        stg.uace_code,
        stg.uza_name,
        stg.vehicle_passenger_car_miles,
        stg.vehicle_passenger_car_miles_1,
        stg.vehicle_passenger_car_miles_2,
        stg.vehicle_passenger_car_revenue,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_breakdowns AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_breakdowns
