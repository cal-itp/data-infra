WITH staging_operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_type_and_agency') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_operating_expenses_by_type_and_agency AS (
    SELECT
        staging_operating_expenses_by_type_and_agency.*,
        dim_organizations.caltrans_district
    FROM staging_operating_expenses_by_type_and_agency
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_operating_expenses_by_type_and_agency.report_year = 2022 THEN
                staging_operating_expenses_by_type_and_agency.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_operating_expenses_by_type_and_agency.ntd_id = dim_organizations.ntd_id
        END
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
