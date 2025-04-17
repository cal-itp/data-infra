WITH staging_master AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__master') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__master AS (
    SELECT
        stg.ntd_id,
        stg.legacy_ntd_id,
        stg.agency,
        stg.mode,
        stg.tos,
        stg._3_mode,
        stg.mode_type_of_service_status,
        stg.reporter_type,
        stg.organization_type,
        stg.hq_city,
        stg.hq_state,
        stg.uace_cd,
        stg.uza_name,
        stg.uza_sq_miles,
        stg.uza_population,
        stg.service_area_population,
        stg.service_area_sq_miles,
        stg.last_closed_report_year,
        stg.last_closed_fy_end_month,
        stg.last_closed_fy_end_year,
        stg.passenger_miles_fy,
        stg.unlinked_passenger_trips_fy,
        stg.avg_trip_length_fy,
        stg.fares_fy,
        stg.operating_expenses_fy,
        stg.avg_cost_per_trip_fy,
        stg.avg_fares_per_trip_fy,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_master AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__master
