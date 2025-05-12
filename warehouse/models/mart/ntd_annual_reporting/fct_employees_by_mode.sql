WITH staging_employees_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__employees_by_mode') }}
),

dim_agency_information AS (
    SELECT
        ntd_id,
        agency_name,
        year,
        city,
        state,
    FROM {{ ref('dim_agency_information') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_employees_by_mode AS (
    SELECT
        agency.agency_name,

        stg.ntd_id,
        stg.report_year,

        agency.city,
        agency.state,

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
        stg.max_mode_name,
        stg.mode,
        stg.sum_total_employee_count,
        stg.sum_total_hours,
        stg.type_of_service,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_employees_by_mode AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_employees_by_mode
