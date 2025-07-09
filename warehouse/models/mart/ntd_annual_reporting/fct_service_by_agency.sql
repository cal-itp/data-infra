WITH staging_service_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__service_by_agency') }}
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

fct_service_by_agency AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.max_agency_voms,
        stg.max_organization_type,
        stg.max_primary_uza_area_sq_miles,
        stg.max_primary_uza_code,
        stg.max_primary_uza_name,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_service_area_population,
        stg.max_service_area_sq_miles,
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
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_service_by_agency AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE stg.key NOT IN ('0610e7c75b67e0edd77f3ef3117b15ba','abd981f1eeb176cd71024b38c0ce24e6','9d4f1caeda82b63dcee955f1009b34d6',
        'ef4dab4a487ec44305b459568f3fb3f6')
)

SELECT * FROM fct_service_by_agency
