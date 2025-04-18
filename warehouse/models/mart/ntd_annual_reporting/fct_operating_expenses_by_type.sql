WITH staging_operating_expenses_by_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_type') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_operating_expenses_by_type AS (
    SELECT
        stg.agency,
        stg.agency_voms,
        stg.casualty_and_liability,
        stg.casualty_and_liability_1,
        stg.city,
        stg.fringe_benefits,
        stg.fringe_benefits_questionable,
        stg.fuel_and_lube,
        stg.fuel_and_lube_questionable,
        stg.miscellaneous,
        stg.miscellaneous_questionable,
        stg.mode,
        stg.mode_name,
        stg.mode_voms,
        stg.ntd_id,
        stg.operator_paid_absences,
        stg.operator_paid_absences_1,
        stg.operators_wages,
        stg.operators_wages_questionable,
        stg.organization_type,
        stg.other_materials_supplies,
        stg.other_materials_supplies_1,
        stg.other_paid_absences,
        stg.other_paid_absences_1,
        stg.other_salaries_wages,
        stg.other_salaries_wages_1,
        stg.primary_uza_population,
        stg.purchased_transportation,
        stg.purchased_transportation_1,
        stg.reduced_reporter_expenses,
        stg.reduced_reporter_expenses_1,
        stg.report_year,
        stg.reporter_type,
        stg.separate_report_amount,
        stg.separate_report_amount_1,
        stg.services,
        stg.services_questionable,
        stg.state,
        stg.taxes,
        stg.taxes_questionable,
        stg.tires,
        stg.tires_questionable,
        stg.total,
        stg.total_questionable,
        stg.type_of_service,
        stg.uace_code,
        stg.utilities,
        stg.utilities_questionable,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_operating_expenses_by_type AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_operating_expenses_by_type
