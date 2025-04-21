WITH staging_employees_by_mode_and_employee_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__employees_by_mode_and_employee_type') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_employees_by_mode_and_employee_type AS (
    SELECT
        stg.agency,
        stg.agency_voms,
        stg.capital_labor_count,
        stg.capital_labor_count_q,
        stg.capital_labor_hours,
        stg.capital_labor_hours_q,
        stg.city,
        stg.facility_maintenance_count,
        stg.facility_maintenance_count_q,
        stg.facility_maintenance_hours,
        stg.facility_maintenance_hours_q,
        stg.full_or_part_time,
        stg.general_administration_count,
        stg.general_administration_count_q,
        stg.general_administration_hours,
        stg.general_administration_hours_q,
        stg.mode,
        stg.mode_name,
        stg.mode_voms,
        stg.ntd_id,
        stg.organization_type,
        stg.primary_uza_population,
        stg.report_year,
        stg.state,
        stg.total_employee_count,
        stg.total_employee_count_q,
        stg.total_hours,
        stg.total_hours_q,
        stg.type_of_service,
        stg.uace_code,
        stg.uza_name,
        stg.vehicle_maintenance_count,
        stg.vehicle_maintenance_count_q,
        stg.vehicle_maintenance_hours,
        stg.vehicle_maintenance_hours_q,
        stg.vehicle_operations_count,
        stg.vehicle_operations_count_q,
        stg.vehicle_operations_hours,
        stg.vehicle_operations_hours_q,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_employees_by_mode_and_employee_type AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
    WHERE stg.state = 'CA'
)

SELECT * FROM fct_employees_by_mode_and_employee_type
