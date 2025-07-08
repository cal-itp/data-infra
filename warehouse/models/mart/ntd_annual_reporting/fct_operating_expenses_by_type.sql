WITH staging_operating_expenses_by_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_type') }}
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

fct_operating_expenses_by_type AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.mode,
        stg.mode_name,
        stg.type_of_service,
        stg.agency_voms,
        stg.casualty_and_liability,
        stg.casualty_and_liability_1,
        stg.fringe_benefits,
        stg.fringe_benefits_questionable,
        stg.fuel_and_lube,
        stg.fuel_and_lube_questionable,
        stg.miscellaneous,
        stg.miscellaneous_questionable,
        stg.mode_voms,
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
        stg.reporter_type,
        stg.separate_report_amount,
        stg.separate_report_amount_1,
        stg.services,
        stg.services_questionable,
        stg.taxes,
        stg.taxes_questionable,
        stg.tires,
        stg.tires_questionable,
        stg.total,
        stg.total_questionable,
        stg.uace_code,
        stg.utilities,
        stg.utilities_questionable,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_operating_expenses_by_type AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE stg.key NOT IN ('33c3d376e7d93b04c210041d62e015f2','f8b280fb1301a54725feefa098f519ec','e1503c0491fb6666f060aa64276fb707',
        '1e9138bb433fed360f111c90866fc94a','faf75088d148925ea862051b49b54429','9078bab61ab02779f9a4a5b043e377d9',
        '1d5f79c7f06b68f023dd6513f8d797d4','1bebb98cd526881d0beab080dafd1e6a','61eeee88a89ab9a2e63c24ac99d297b8',
        '04804150c414bd12329423ebf09442fd')
)

SELECT * FROM fct_operating_expenses_by_type
