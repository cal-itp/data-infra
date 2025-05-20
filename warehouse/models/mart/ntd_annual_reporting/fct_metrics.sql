WITH staging_metrics AS (
    SELECT *
    FROM {{ ref('stg_ntd__metrics') }}
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

fct_metrics AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.report_year', 'stg.mode', 'stg.type_of_service']) }} AS key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.mode,
        stg.mode_name,
        stg.type_of_service,
        stg.agency_voms,
        stg.cost_per_hour,
        stg.cost_per_hour_questionable,
        stg.cost_per_passenger,
        stg.cost_per_passenger_1,
        stg.cost_per_passenger_mile,
        stg.cost_per_passenger_mile_1,
        stg.fare_revenues_earned,
        stg.fare_revenues_earned_1,
        stg.fare_revenues_per_total,
        stg.fare_revenues_per_total_1,
        stg.fare_revenues_per_unlinked,
        stg.fare_revenues_per_unlinked_1,
        stg.mode_voms,
        stg.organization_type,
        stg.passenger_miles,
        stg.passenger_miles_questionable,
        stg.passengers_per_hour,
        stg.passengers_per_hour_1,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_operating_expenses,
        stg.total_operating_expenses_1,
        stg.unlinked_passenger_trips,
        stg.unlinked_passenger_trips_1,
        stg.vehicle_revenue_hours,
        stg.vehicle_revenue_hours_1,
        stg.vehicle_revenue_miles,
        stg.vehicle_revenue_miles_1,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_metrics AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_metrics
