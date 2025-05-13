WITH staging_employees_by_mode_and_employee_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__employees_by_mode_and_employee_type') }}
),

dim_agency_information AS (
    SELECT
        ntd_id,
        year,
        agency_name,
        city,
        state,
        caltrans_district_current,
        caltrans_district_name_current
    FROM {{ ref('dim_agency_information') }}
),

fct_employees_by_mode_and_employee_type AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.report_year', 'stg.mode', 'stg.type_of_service', 'stg.full_or_part_time']) }} AS key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.agency_voms,
        stg.capital_labor_count,
        stg.capital_labor_count_q,
        stg.capital_labor_hours,
        stg.capital_labor_hours_q,
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
        stg.organization_type,
        stg.primary_uza_population,
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
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_employees_by_mode_and_employee_type AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_employees_by_mode_and_employee_type
