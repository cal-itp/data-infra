WITH staging_metrics AS (
    SELECT *
    FROM {{ ref('stg_ntd__metrics') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_metrics AS (
    SELECT
        stg.agency,
        stg.agency_voms,
        stg.city,
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
        stg.mode,
        stg.mode_name,
        stg.mode_voms,
        stg.ntd_id,
        stg.organization_type,
        stg.passenger_miles,
        stg.passenger_miles_questionable,
        stg.passengers_per_hour,
        stg.passengers_per_hour_1,
        stg.primary_uza_population,
        stg.report_year,
        stg.reporter_type,
        stg.state,
        stg.total_operating_expenses,
        stg.total_operating_expenses_1,
        stg.type_of_service,
        stg.unlinked_passenger_trips,
        stg.unlinked_passenger_trips_1,
        stg.vehicle_revenue_hours,
        stg.vehicle_revenue_hours_1,
        stg.vehicle_revenue_miles,
        stg.vehicle_revenue_miles_1,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_metrics AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
    WHERE stg.state = 'CA'
)

SELECT * FROM fct_metrics
