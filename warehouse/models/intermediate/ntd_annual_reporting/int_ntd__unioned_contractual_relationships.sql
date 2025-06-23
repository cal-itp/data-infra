WITH stg_ntd__2022_contractual_relationships AS (
    SELECT *
    FROM {{ ref('stg_ntd__2022_contractual_relationships') }}
),

stg_ntd__2023_contractual_relationships AS (
    SELECT *
    FROM {{ ref('stg_ntd__2023_contractual_relationships') }}
),

int_ntd__unioned_contractual_relationships AS (
    SELECT
        2022 AS year,
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
        source_agency_name,
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
        dt,
        execution_ts
    FROM stg_ntd__2022_contractual_relationships

    UNION ALL

    SELECT
        2023 AS year,
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
        source_agency_name,
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
        dt,
        execution_ts
    FROM stg_ntd__2023_contractual_relationships
)

SELECT * FROM int_ntd__unioned_contractual_relationships
