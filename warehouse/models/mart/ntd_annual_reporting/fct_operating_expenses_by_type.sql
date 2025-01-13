WITH staging_operating_expenses_by_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_type') }}
),

fct_operating_expenses_by_type AS (
    SELECT *
    FROM staging_operating_expenses_by_type
)

SELECT
    agency,
    agency_voms,
    casualty_and_liability,
    casualty_and_liability_1,
    city,
    fringe_benefits,
    fringe_benefits_questionable,
    fuel_and_lube,
    fuel_and_lube_questionable,
    miscellaneous,
    miscellaneous_questionable,
    mode,
    mode_name,
    mode_voms,
    ntd_id,
    operator_paid_absences,
    operator_paid_absences_1,
    operators_wages,
    operators_wages_questionable,
    organization_type,
    other_materials_supplies,
    other_materials_supplies_1,
    other_paid_absences,
    other_paid_absences_1,
    other_salaries_wages,
    other_salaries_wages_1,
    primary_uza_population,
    purchased_transportation,
    purchased_transportation_1,
    reduced_reporter_expenses,
    reduced_reporter_expenses_1,
    report_year,
    reporter_type,
    separate_report_amount,
    separate_report_amount_1,
    services,
    services_questionable,
    state,
    taxes,
    taxes_questionable,
    tires,
    tires_questionable,
    total,
    total_questionable,
    type_of_service,
    uace_code,
    utilities,
    utilities_questionable,
    uza_name,
    dt,
    execution_ts
FROM fct_operating_expenses_by_type
