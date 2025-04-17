WITH staging_contractual_relationships AS (
    SELECT *
    FROM {{ ref('stg_ntd__2023_contractual_relationships') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_2023_contractual_relationships AS (
    SELECT
        stg.other_reconciling_item_expenses_incurred_by_the_buyer,
        stg.total_modal_expenses,
        stg.contract_capital_leasing_expenses,
        stg.direct_payment_agency_subsidy,
        stg.months_seller_operated_in_fy,
        stg.primary_feature,
        stg.voms_under_contract,
        stg.service_captured,
        stg.fares_retained_by,
        stg.other_party,
        stg.other_public_assets_provided,
        stg.buyer_supplies_vehicles_to_seller,
        stg.contractee_ntd_id,
        stg.pt_fare_revenues_passenger_fees,
        stg.agency_name,
        stg.tos,
        stg.type_of_contract,
        stg.reporter_contractual_position,
        stg.other_operating_expenses_incurred_by_the_buyer,
        stg.passenger_out_of_pocket_expenses,
        stg.buyer_provides_maintenance_facility_to_seller,
        stg.contractee_operator_name,
        stg.mode,
        stg.reporting_module,
        stg.reporter_type,
        stg.other_public_assets_provided_desc,
        stg.ntd_id,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_contractual_relationships AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_2023_contractual_relationships
