WITH staging_operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_type_and_agency') }}
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
        staging_operating_expenses_by_type_and_agency.*,
        current_dim_organizations.caltrans_district
    FROM staging_operating_expenses_by_type_and_agency
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM enrich_with_caltrans_district
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
    caltrans_district,
    dt,
    execution_ts
FROM fct_operating_expenses_by_type_and_agency
