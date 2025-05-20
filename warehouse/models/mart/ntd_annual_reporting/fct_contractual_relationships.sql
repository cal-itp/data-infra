WITH intermediate_contractual_relationships AS (
    SELECT *
    FROM {{ ref('int_ntd__unioned_contractual_relationships') }}
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

fct_contractual_relationships AS (
    SELECT
        int.ntd_id,
        int.year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        int.contractee_ntd_id,
        int.contractee_operator_name,
        int.type_of_contract,
        int.mode,
        int.service_captured,
        int.tos,
        int.other_reconciling_item_expenses_incurred_by_the_buyer,
        int.total_modal_expenses,
        int.contract_capital_leasing_expenses,
        int.direct_payment_agency_subsidy,
        int.months_seller_operated_in_fy,
        int.primary_feature,
        int.voms_under_contract,
        int.fares_retained_by,
        int.other_party,
        int.other_public_assets_provided,
        int.buyer_supplies_vehicles_to_seller,
        int.pt_fare_revenues_passenger_fees,
        int.reporter_contractual_position,
        int.other_operating_expenses_incurred_by_the_buyer,
        int.passenger_out_of_pocket_expenses,
        int.buyer_provides_maintenance_facility_to_seller,
        int.reporting_module,
        int.reporter_type,
        int.other_public_assets_provided_desc,
        int.source_agency_name,
        int.dt,
        int.execution_ts,
        {{ dbt_utils.generate_surrogate_key(['int.ntd_id', 'int.year', 'agency.agency_name', 'agency.city',
            'agency.state', 'agency.caltrans_district_current', 'agency.caltrans_district_name_current',
            'int.contractee_ntd_id', 'int.contractee_operator_name', 'int.type_of_contract', 'int.mode',
            'int.service_captured', 'int.tos', 'int.other_reconciling_item_expenses_incurred_by_the_buyer',
            'int.total_modal_expenses', 'int.contract_capital_leasing_expenses', 'int.direct_payment_agency_subsidy',
            'int.months_seller_operated_in_fy', 'int.primary_feature', 'int.voms_under_contract', 'int.fares_retained_by',
            'int.other_party', 'int.other_public_assets_provided', 'int.buyer_supplies_vehicles_to_seller',
            'int.pt_fare_revenues_passenger_fees', 'int.reporter_contractual_position', 'int.other_operating_expenses_incurred_by_the_buyer',
            'int.passenger_out_of_pocket_expenses', 'int.buyer_provides_maintenance_facility_to_seller', 'int.reporting_module',
            'int.reporter_type', 'int.other_public_assets_provided_desc', 'int.source_agency_name']) }} AS _content_hash
    FROM intermediate_contractual_relationships AS int
    LEFT JOIN dim_agency_information AS agency_name
        ON int.ntd_id = agency.ntd_id
            AND int.year = agency.year
)

SELECT * FROM fct_contractual_relationships
