WITH staging_employees_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__employees_by_mode') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_employees_by_mode AS (
    SELECT
        staging_employees_by_mode.*,
        dim_organizations.caltrans_district
    FROM staging_employees_by_mode
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_employees_by_mode.report_year = 2022 THEN
                staging_employees_by_mode.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_employees_by_mode.ntd_id = dim_organizations.ntd_id
        END
)

SELECT
    count_capital_labor_count_q,
    count_capital_labor_hours_q,
    count_facility_maintenance_count_q,
    count_facility_maintenance_hours_q,
    count_general_administration_count_q,
    count_general_administration_hours_q,
    count_total_employee_count_q,
    count_total_employee_hours_q,
    count_vehicle_maintenance_count_q,
    count_vehicle_maintenance_hours_q,
    count_vehicle_operations_count_q,
    count_vehicle_operations_hours_q,
    max_mode_name,
    mode,
    ntd_id,
    report_year,
    sum_total_employee_count,
    sum_total_hours,
    type_of_service,
    caltrans_district,
    dt,
    execution_ts
FROM fct_employees_by_mode
