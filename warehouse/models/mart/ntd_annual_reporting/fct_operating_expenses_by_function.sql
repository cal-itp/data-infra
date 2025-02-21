WITH staging_operating_expenses_by_function AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_function') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

enrich_with_caltrans_district AS (
    SELECT
        staging_operating_expenses_by_function.*,
        current_dim_organizations.caltrans_district
    FROM staging_operating_expenses_by_function
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_operating_expenses_by_function AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    agency,
    agency_voms,
    city,
    facility_maintenance,
    facility_maintenance_1,
    general_administration,
    general_administration_1,
    mode,
    mode_name,
    mode_voms,
    ntd_id,
    organization_type,
    primary_uza_population,
    reduced_reporter_expenses,
    reduced_reporter_expenses_1,
    report_year,
    reporter_type,
    separate_report_amount,
    separate_report_amount_1,
    state,
    total,
    total_questionable,
    type_of_service,
    vehicle_maintenance,
    vehicle_maintenance_1,
    vehicle_operations,
    vehicle_operations_1,
    uace_code,
    uza_name,
    caltrans_district,
    dt,
    execution_ts
FROM fct_operating_expenses_by_function
