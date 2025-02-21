-- this was already here, no changes
WITH staging_breakdowns_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__breakdowns_by_agency') }}
),

-- this is a new CTE, which pulls two columns from dim_organizations: ntd_id to join on in the CTE immediately below, and caltrans_district to enrich the final table
current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

-- this is a new CTE, perform the join on staging_breakdowns_by_agency to include caltrans_district
enrich_with_caltrans_district AS (
    SELECT
        staging_breakdowns_by_agency.*,
        current_dim_organizations.caltrans_district
    FROM staging_breakdowns_by_agency
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

-- this CTE was here previously, but it used to pull from the first CTE (staging_breakdowns_by_agency). now I have ajusted the from statement to pull from the new CTE that performs the join and enriches with caltrans_district
fct_breakdowns_by_agency AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    count_major_mechanical_failures_questionable,
    count_other_mechanical_failures_questionable,
    count_total_mechanical_failures_questionable,
    count_train_miles_questionable,
    count_train_revenue_miles_questionable,
    count_vehicle_passenger_car_miles_questionable,
    max_agency,
    max_agency_voms,
    max_city,
    max_organization_type,
    max_primary_uza_population,
    max_reporter_type,
    max_state,
    max_uace_code,
    max_uza_name,
    ntd_id,
    report_year,
    sum_major_mechanical_failures,
    sum_other_mechanical_failures,
    sum_total_mechanical_failures,
    sum_train_miles,
    sum_train_revenue_miles,
    sum_vehicle_passenger_car_miles,
    sum_vehicle_passenger_car_revenue,
-- include newly added column in column selection
    caltrans_district,
    dt,
    execution_ts
FROM fct_breakdowns_by_agency
