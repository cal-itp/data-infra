WITH intermediate_contractual_relationships AS (
    SELECT *
    FROM {{ ref('int_ntd__unioned_contractual_relationships') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

dim_contractual_relationships AS (
    SELECT
        int.agency_name,
        int.ntd_id,
        int.year,
        int.other_reconciling_item_expenses_incurred_by_the_buyer,
        int.total_modal_expenses,
        int.contract_capital_leasing_expenses,
        int.direct_payment_agency_subsidy,
        int.months_seller_operated_in_fy,
        int.primary_feature,
        int.voms_under_contract,
        int.service_captured,
        int.fares_retained_by,
        int.other_party,
        int.other_public_assets_provided,
        int.buyer_supplies_vehicles_to_seller,
        int.contractee_ntd_id,
        int.pt_fare_revenues_passenger_fees,
        int.tos,
        int.type_of_contract,
        int.reporter_contractual_position,
        int.other_operating_expenses_incurred_by_the_buyer,
        int.passenger_out_of_pocket_expenses,
        int.buyer_provides_maintenance_facility_to_seller,
        int.contractee_operator_name,
        int.mode,
        int.reporting_module,
        int.reporter_type,
        int.other_public_assets_provided_desc,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        int.dt,
        int.execution_ts
    FROM intermediate_contractual_relationships AS int
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM dim_contractual_relationships
