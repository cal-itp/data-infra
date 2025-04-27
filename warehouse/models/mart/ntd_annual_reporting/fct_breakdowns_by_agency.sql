WITH staging_breakdowns_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__breakdowns_by_agency') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_breakdowns_by_agency AS (
    SELECT
        stg.max_agency AS agency,
        stg.ntd_id,
        stg.report_year,
        stg.max_city AS city,
        stg.max_state AS state,
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

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_breakdowns_by_agency AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_breakdowns_by_agency
