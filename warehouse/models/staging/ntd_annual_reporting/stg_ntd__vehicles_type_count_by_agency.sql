WITH external_vehicles_type_count_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__vehicles_type_count_by_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_vehicles_type_count_by_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__vehicles_type_count_by_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    SAFE_CAST(aerial_tram AS NUMERIC) AS aerial_tram,
    SAFE_CAST(aerial_tram_rptulb AS NUMERIC) AS aerial_tram_rptulb,
    SAFE_CAST(aerial_tram_ulb AS NUMERIC) AS aerial_tram_ulb,
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
    SAFE_CAST(articulated_bus AS NUMERIC) AS articulated_bus,
    SAFE_CAST(articulated_bus_ulb AS NUMERIC) AS articulated_bus_ulb,
    SAFE_CAST(articulated_busrptulb AS NUMERIC) AS articulated_busrptulb,
    SAFE_CAST(automated_guideway_vehicle AS NUMERIC) AS automated_guideway_vehicle,
    SAFE_CAST(automated_guideway_vehicle_1 AS NUMERIC) AS automated_guideway_vehicle_1,
    SAFE_CAST(automated_guideway_vehicle_2 AS NUMERIC) AS automated_guideway_vehicle_2,
    SAFE_CAST(automobile AS NUMERIC) AS automobile,
    SAFE_CAST(automobile_ulb AS NUMERIC) AS automobile_ulb,
    SAFE_CAST(automobilerptulb AS NUMERIC) AS automobilerptulb,
    SAFE_CAST(automobiles AS NUMERIC) AS automobiles,
    SAFE_CAST(automobiles_ulb AS NUMERIC) AS automobiles_ulb,
    SAFE_CAST(bus AS NUMERIC) AS bus,
    SAFE_CAST(bus_ulb AS NUMERIC) AS bus_ulb,
    SAFE_CAST(busrptulb AS NUMERIC) AS busrptulb,
    SAFE_CAST(cable_car AS NUMERIC) AS cable_car,
    SAFE_CAST(cable_car_rptulb AS NUMERIC) AS cable_car_rptulb,
    SAFE_CAST(cable_car_ulb AS NUMERIC) AS cable_car_ulb,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST(commuter_rail_passenger_coach AS NUMERIC) AS commuter_rail_passenger_coach,
    SAFE_CAST(commuter_rail_passenger_coach_1 AS NUMERIC) AS commuter_rail_passenger_coach_1,
    SAFE_CAST(commuter_rail_passenger_coach_2 AS NUMERIC) AS commuter_rail_passenger_coach_2,
    SAFE_CAST(commuter_rail_self_propelled AS NUMERIC) AS commuter_rail_self_propelled,
    SAFE_CAST(commuter_rail_self_propelled_1 AS NUMERIC) AS commuter_rail_self_propelled_1,
    SAFE_CAST(commuter_rail_self_propelled_2 AS NUMERIC) AS commuter_rail_self_propelled_2,
    SAFE_CAST(cutaway AS NUMERIC) AS cutaway,
    SAFE_CAST(cutaway_ulb AS NUMERIC) AS cutaway_ulb,
    SAFE_CAST(cutawayrptulb AS NUMERIC) AS cutawayrptulb,
    SAFE_CAST(double_decker_bus AS NUMERIC) AS double_decker_bus,
    SAFE_CAST(double_decker_bus_ulb AS NUMERIC) AS double_decker_bus_ulb,
    SAFE_CAST(double_decker_busrptulb AS NUMERIC) AS double_decker_busrptulb,
    SAFE_CAST(ferryboat AS NUMERIC) AS ferryboat,
    SAFE_CAST(ferryboat_rptulb AS NUMERIC) AS ferryboat_rptulb,
    SAFE_CAST(ferryboat_ulb AS NUMERIC) AS ferryboat_ulb,
    SAFE_CAST(heavy_rail_passenger_car AS NUMERIC) AS heavy_rail_passenger_car,
    SAFE_CAST(heavy_rail_passenger_car_1 AS NUMERIC) AS heavy_rail_passenger_car_1,
    SAFE_CAST(heavy_rail_passenger_car_2 AS NUMERIC) AS heavy_rail_passenger_car_2,
    SAFE_CAST(inclined_plane AS NUMERIC) AS inclined_plane,
    SAFE_CAST(inclined_plane_rptulb AS NUMERIC) AS inclined_plane_rptulb,
    SAFE_CAST(inclined_plane_ulb AS NUMERIC) AS inclined_plane_ulb,
    SAFE_CAST(light_rail_vehicle AS NUMERIC) AS light_rail_vehicle,
    SAFE_CAST(light_rail_vehicle_rptulb AS NUMERIC) AS light_rail_vehicle_rptulb,
    SAFE_CAST(light_rail_vehicle_ulb AS NUMERIC) AS light_rail_vehicle_ulb,
    SAFE_CAST(locomotive AS NUMERIC) AS locomotive,
    SAFE_CAST(locomotive_rptulb AS NUMERIC) AS locomotive_rptulb,
    SAFE_CAST(locomotive_ulb AS NUMERIC) AS locomotive_ulb,
    SAFE_CAST(minivan AS NUMERIC) AS minivan,
    SAFE_CAST(minivan_ulb AS NUMERIC) AS minivan_ulb,
    SAFE_CAST(minivanrptulb AS NUMERIC) AS minivanrptulb,
    SAFE_CAST(monorail AS NUMERIC) AS monorail,
    SAFE_CAST(monorail_ulb AS NUMERIC) AS monorail_ulb,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST(other AS NUMERIC) AS other,
    SAFE_CAST(other_rptulb AS NUMERIC) AS other_rptulb,
    SAFE_CAST(other_ulb AS NUMERIC) AS other_ulb,
    SAFE_CAST(over_the_road_bus AS NUMERIC) AS over_the_road_bus,
    SAFE_CAST(over_the_road_bus_ulb AS NUMERIC) AS over_the_road_bus_ulb,
    SAFE_CAST(over_the_road_busrptulb AS NUMERIC) AS over_the_road_busrptulb,
    SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
    SAFE_CAST(report_year AS INT64) AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    SAFE_CAST(school_bus AS NUMERIC) AS school_bus,
    SAFE_CAST(school_bus_ulb AS NUMERIC) AS school_bus_ulb,
    SAFE_CAST(schoolbusrptulb AS NUMERIC) AS schoolbusrptulb,
    SAFE_CAST(sport_utility_vehicle AS NUMERIC) AS sport_utility_vehicle,
    SAFE_CAST(sport_utility_vehicle_rptulb AS NUMERIC) AS sport_utility_vehicle_rptulb,
    SAFE_CAST(sport_utility_vehicle_ulb AS NUMERIC) AS sport_utility_vehicle_ulb,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST(steel_wheel_vehicles AS NUMERIC) AS steel_wheel_vehicles,
    SAFE_CAST(steel_wheel_vehicles_ulb AS NUMERIC) AS steel_wheel_vehicles_ulb,
    SAFE_CAST(streetcar AS NUMERIC) AS streetcar,
    SAFE_CAST(streetcar_rptulb AS NUMERIC) AS streetcar_rptulb,
    SAFE_CAST(streetcar_ulb AS NUMERIC) AS streetcar_ulb,
    SAFE_CAST(total_revenue_vehicles AS NUMERIC) AS total_revenue_vehicles,
    SAFE_CAST(total_revenue_vehicles_ulb AS NUMERIC) AS total_revenue_vehicles_ulb,
    SAFE_CAST(total_rptulb AS NUMERIC) AS total_rptulb,
    SAFE_CAST(total_service_vehicles AS NUMERIC) AS total_service_vehicles,
    SAFE_CAST(total_service_vehicles_ulb AS NUMERIC) AS total_service_vehicles_ulb,
    SAFE_CAST(trolleybus AS NUMERIC) AS trolleybus,
    SAFE_CAST(trolleybus_ulb AS NUMERIC) AS trolleybus_ulb,
    SAFE_CAST(trolleybusrptulb AS NUMERIC) AS trolleybusrptulb,
    SAFE_CAST(trucks_and_other_rubber_tire AS NUMERIC) AS trucks_and_other_rubber_tire,
    SAFE_CAST(trucks_and_other_rubber_tire_1 AS NUMERIC) AS trucks_and_other_rubber_tire_1,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    SAFE_CAST(van AS NUMERIC) AS van,
    SAFE_CAST(van_ulb AS NUMERIC) AS van_ulb,
    SAFE_CAST(vanrptulb AS NUMERIC) AS vanrptulb,
    SAFE_CAST(vintage_historic_trolley AS NUMERIC) AS vintage_historic_trolley,
    SAFE_CAST(vintage_historic_trolley_1 AS NUMERIC) AS vintage_historic_trolley_1,
    SAFE_CAST(vintage_historic_trolley_2 AS NUMERIC) AS vintage_historic_trolley_2,
    dt,
    execution_ts
FROM stg_ntd__vehicles_type_count_by_agency