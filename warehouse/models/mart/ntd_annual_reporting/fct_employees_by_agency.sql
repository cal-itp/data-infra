WITH staging_employees_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__employees_by_agency') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_employees_by_agency AS (
    SELECT
        stg.agency,
        stg.avgwagerate,
        stg.count_capital_labor_count_q,
        stg.count_capital_labor_hours_q,
        stg.count_facility_maintenance_count_q,
        stg.count_facility_maintenance_hours_q,
        stg.count_general_administration_count_q,
        stg.count_general_administration_hours_q,
        stg.count_total_employee_count_q,
        stg.count_total_employee_hours_q,
        stg.count_vehicle_maintenance_count_q,
        stg.count_vehicle_maintenance_hours_q,
        stg.count_vehicle_operations_count_q,
        stg.count_vehicle_operations_hours_q,
        stg.max_agency_voms_1,
        stg.max_city_1,
        stg.max_mode_voms,
        stg.max_ntd_id,
        stg.max_primary_uza_population_1,
        stg.max_state_1,
        stg.max_uza_name_1,
        stg.report_year,
        stg.sum_total_hours,
        stg.total_employees,
        stg.total_operating_hours,
        stg.total_salaries,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_employees_by_agency AS stg
    LEFT JOIN current_dim_organizations AS orgs ON stg.max_ntd_id = orgs.ntd_id
)

SELECT * FROM fct_employees_by_agency
