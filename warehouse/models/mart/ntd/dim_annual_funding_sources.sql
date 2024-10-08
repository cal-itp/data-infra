{{ config(materialized='table') }}

WITH local_funding_sources AS (
    SELECT "local" AS funding_source,
           agency,
           agency_voms,
           city,
           fuel_tax,
           null AS fta_capital_program_5309,
           null AS fta_rural_progam_5311,
           null AS fta_urbanized_area_formula,
           general_fund AS general_funds,
           income_tax,
           ntd_id,
           organization_type,
           null AS other_dot_funds,
           null AS other_federal_funds,
           null AS other_fta_funds,
           other_funds,
           other_taxes,
           primary_uza_population,
           property_tax,
           reduced_reporter_funds,
           report_year,
           reporter_type,
           sales_tax,
           state,
           tolls,
           null AS transportation_funds,
           uace_code,
           uza_name
      FROM {{ ref("stg_ntd_annual_data__2022__funding_sources_local") }}
),

state_funding_sources AS (
    SELECT "state" AS funding_source,
           agency,
           agency_voms,
           city,
           null AS fuel_tax,
           null AS fta_capital_program_5309,
           null AS fta_rural_progam_5311,
           null AS fta_urbanized_area_formula,
           general_funds,
           null AS income_tax,
           ntd_id,
           organization_type,
           null AS other_dot_funds,
           null AS other_federal_funds,
           null AS other_fta_funds,
           null AS other_funds,
           null AS other_taxes,
           primary_uza_population,
           null AS property_tax,
           reduced_reporter_funds,
           report_year,
           reporter_type,
           null AS sales_tax,
           state,
           null AS tolls,
           transportation_funds,
           uace_code,
           uza_name
      FROM {{ ref("stg_ntd_annual_data__2022__funding_sources_state") }}
),

federal_funding_sources AS (
    SELECT "federal" AS funding_source,
           agency,
           agency_voms,
           city,
           null AS fuel_tax,
           fta_capital_program_5309,
           fta_rural_progam_5311,
           fta_urbanized_area_formula,
           null AS general_funds,
           null AS income_tax,
           ntd_id,
           organization_type,
           other_dot_funds,
           other_federal_funds,
           other_fta_funds,
           null AS other_funds,
           null AS other_taxes,
           primary_uza_population,
           null AS property_tax,
           null AS reduced_reporter_funds,
           report_year,
           reporter_type,
           null AS sales_tax,
           state,
           null AS tolls,
           null AS transportation_funds,
           uace_code,
           uza_name
      FROM {{ ref("stg_ntd_annual_data__2022__funding_sources_federal") }}
)

SELECT * FROM local_funding_sources
 UNION ALL
SELECT * FROM state_funding_sources
 UNION ALL
SELECT * FROM federal_funding_sources
