WITH staging_operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_type_and_agency') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_operating_expenses_by_type_and_agency AS (
    SELECT
        stg.max_agency,
        stg.max_agency_voms,
        stg.max_city,
        stg.max_organization_type,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_state,
        stg.max_uace_code,
        stg.max_uza_name,
        stg.ntd_id,
        stg.report_year,
        stg.sum_casualty_and_liability,
        stg.sum_fringe_benefits,
        stg.sum_fuel_and_lube,
        stg.sum_miscellaneous,
        stg.sum_operator_paid_absences,
        stg.sum_operators_wages,
        stg.sum_other_materials_supplies,
        stg.sum_other_paid_absences,
        stg.sum_other_salaries_wages,
        stg.sum_purchased_transportation,
        stg.sum_reduced_reporter_expenses,
        stg.sum_separate_report_amount,
        stg.sum_services,
        stg.sum_taxes,
        stg.sum_tires,
        stg.sum_total,
        stg.sum_utilities,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_operating_expenses_by_type_and_agency AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_operating_expenses_by_type_and_agency
