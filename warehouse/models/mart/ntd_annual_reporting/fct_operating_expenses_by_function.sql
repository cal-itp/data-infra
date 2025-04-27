WITH staging_operating_expenses_by_function AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_function') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_operating_expenses_by_function AS (
    SELECT
        stg.ntd_id,
        stg.agency,
        stg.report_year,
        stg.city,
        stg.state,
        stg.agency_voms,
        stg.facility_maintenance,
        stg.facility_maintenance_1,
        stg.general_administration,
        stg.general_administration_1,
        stg.mode,
        stg.mode_name,
        stg.mode_voms,
        stg.organization_type,
        stg.primary_uza_population,
        stg.reduced_reporter_expenses,
        stg.reduced_reporter_expenses_1,
        stg.reporter_type,
        stg.separate_report_amount,
        stg.separate_report_amount_1,
        stg.total,
        stg.total_questionable,
        stg.type_of_service,
        stg.vehicle_maintenance,
        stg.vehicle_maintenance_1,
        stg.vehicle_operations,
        stg.vehicle_operations_1,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_operating_expenses_by_function AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_operating_expenses_by_function
