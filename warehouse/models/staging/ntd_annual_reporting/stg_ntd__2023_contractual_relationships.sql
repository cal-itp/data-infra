WITH external_contractual_relationships AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2023__annual_database_contractual_relationships') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_contractual_relationships
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__2023_contractual_relationships AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    SAFE_CAST(other_reconciling_item_expenses_incurred_by_the_buyer AS INTEGER) AS other_reconciling_item_expenses_incurred_by_the_buyer,
    SAFE_CAST(total_modal_expenses AS INTEGER) AS total_modal_expenses,
    SAFE_CAST(contract_capital_leasing_expenses AS INTEGER) AS contract_capital_leasing_expenses,
    SAFE_CAST(direct_payment_agency_subsidy AS INTEGER) AS direct_payment_agency_subsidy,
    SAFE_CAST(months_seller_operated_in_fy AS INTEGER) AS months_seller_operated_in_fy,
    {{ trim_make_empty_string_null('primary_feature') }} AS primary_feature,
    SAFE_CAST(voms_under_contract AS INTEGER) AS voms_under_contract,
    {{ trim_make_empty_string_null('service_captured') }} AS service_captured,
    {{ trim_make_empty_string_null('fares_retained_by') }} AS fares_retained_by,
    {{ trim_make_empty_string_null('other_party') }} AS other_party,
    SAFE_CAST(other_public_assets_provided AS BOOLEAN) AS other_public_assets_provided,
    SAFE_CAST(buyer_supplies_vehicles_to_seller AS BOOLEAN) AS buyer_supplies_vehicles_to_seller,
    {{ trim_make_empty_string_null('contractee_ntd_id') }} AS contractee_ntd_id,
    SAFE_CAST(pt_fare_revenues_passenger_fees AS INTEGER) AS pt_fare_revenues_passenger_fees,
    {{ trim_make_empty_string_null('agency_name') }} AS agency_name,
    {{ trim_make_empty_string_null('tos') }} AS tos,
    {{ trim_make_empty_string_null('type_of_contract') }} AS type_of_contract,
    {{ trim_make_empty_string_null('reporter_contractual_position') }} AS reporter_contractual_position,
    SAFE_CAST(other_operating_expenses_incurred_by_the_buyer AS INTEGER) AS other_operating_expenses_incurred_by_the_buyer,
    SAFE_CAST(passenger_out_of_pocket_expenses AS INTEGER) AS passenger_out_of_pocket_expenses,
    SAFE_CAST(buyer_provides_maintenance_facility_to_seller AS BOOLEAN) AS buyer_provides_maintenance_facility_to_seller,
    {{ trim_make_empty_string_null('contractee_operator_name') }} AS contractee_operator_name,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    {{ trim_make_empty_string_null('reporting_module') }} AS reporting_module,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    {{ trim_make_empty_string_null('other_public_assets_provided_desc') }} AS other_public_assets_provided_desc,
    SAFE_CAST(ntd_id AS STRING) AS ntd_id,
    dt,
    execution_ts
FROM stg_ntd__2023_contractual_relationships
