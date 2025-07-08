WITH staging_employees_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__employees_by_agency') }}
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

fct_employees_by_agency AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

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
        stg.max_mode_voms,
        stg.max_primary_uza_population_1,
        stg.max_uza_name_1,
        stg.sum_total_hours,
        stg.total_employees,
        stg.total_operating_hours,
        stg.total_salaries,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_employees_by_agency AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_employees_by_agency
