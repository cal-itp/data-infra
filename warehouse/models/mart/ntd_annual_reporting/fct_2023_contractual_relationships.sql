WITH staging_contractual_relationships AS (
    SELECT *
    FROM {{ ref('stg_ntd__2023_contractual_relationships') }}
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
        staging_contractual_relationships.*,
        current_dim_organizations.caltrans_district
    FROM staging_contractual_relationships
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_2023_contractual_relationships AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    other_reconciling_item_expenses_incurred_by_the_buyer,
    total_modal_expenses,
    contract_capital_leasing_expenses,
    direct_payment_agency_subsidy,
    months_seller_operated_in_fy,
    primary_feature,
    voms_under_contract,
    service_captured,
    fares_retained_by,
    other_party,
    other_public_assets_provided,
    buyer_supplies_vehicles_to_seller,
    contractee_ntd_id,
    pt_fare_revenues_passenger_fees,
    agency_name,
    tos,
    type_of_contract,
    reporter_contractual_position,
    other_operating_expenses_incurred_by_the_buyer,
    passenger_out_of_pocket_expenses,
    buyer_provides_maintenance_facility_to_seller,
    contractee_operator_name,
    mode,
    reporting_module,
    reporter_type,
    other_public_assets_provided_desc,
    ntd_id,
    caltrans_district,
    dt,
    execution_ts
FROM fct_2023_contractual_relationships
