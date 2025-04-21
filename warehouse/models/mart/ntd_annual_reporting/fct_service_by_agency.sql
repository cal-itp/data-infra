WITH staging_service_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__service_by_agency') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_service_by_agency AS (
    SELECT
        stg._5_digit_ntd_id,
        stg.agency,
        stg.max_agency_voms,
        stg.max_city,
        stg.max_organization_type,
        stg.max_primary_uza_area_sq_miles,
        stg.max_primary_uza_code,
        stg.max_primary_uza_name,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_service_area_population,
        stg.max_service_area_sq_miles,
        stg.max_state,
        stg.report_year,
        stg.sum_actual_vehicles_passenger_car_deadhead_hours,
        stg.sum_actual_vehicles_passenger_car_hours,
        stg.sum_actual_vehicles_passenger_car_miles,
        stg.sum_actual_vehicles_passenger_car_revenue_hours,
        stg.sum_actual_vehicles_passenger_car_revenue_miles,
        stg.sum_actual_vehicles_passenger_deadhead_miles,
        stg.sum_ada_upt,
        stg.sum_charter_service_hours,
        stg.sum_directional_route_miles,
        stg.sum_passenger_miles,
        stg.sum_scheduled_vehicles_passenger_car_revenue_miles,
        stg.sum_school_bus_hours,
        stg.sum_sponsored_service_upt,
        stg.sum_train_deadhead_hours,
        stg.sum_train_deadhead_miles,
        stg.sum_train_hours,
        stg.sum_train_miles,
        stg.sum_train_revenue_hours,
        stg.sum_train_revenue_miles,
        stg.sum_trains_in_operation,
        stg.sum_unlinked_passenger_trips_upt,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_service_by_agency AS stg
    LEFT JOIN current_dim_organizations AS orgs ON stg._5_digit_ntd_id = orgs.ntd_id
    WHERE stg.max_state = 'CA'
)

SELECT * FROM fct_service_by_agency
