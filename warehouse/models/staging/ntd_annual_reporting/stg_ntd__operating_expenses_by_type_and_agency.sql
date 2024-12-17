WITH external_operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__operating_expenses_by_type_and_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_operating_expenses_by_type_and_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
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
    sum_casualty_and_liability,
    sum_fringe_benefits,
    sum_fuel_and_lube,
    sum_miscellaneous,
    sum_operator_paid_absences,
    sum_operators_wages,
    sum_other_materials_supplies,
    sum_other_paid_absences,
    sum_other_salaries_wages,
    sum_purchased_transportation,
    sum_reduced_reporter_expenses,
    sum_separate_report_amount,
    sum_services,
    sum_taxes,
    sum_tires,
    sum_total,
    sum_utilities,
    dt,
    execution_ts
FROM stg_ntd__operating_expenses_by_type_and_agency
