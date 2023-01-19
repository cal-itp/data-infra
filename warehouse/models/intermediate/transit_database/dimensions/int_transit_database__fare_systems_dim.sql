{{ config(materialized='table') }}

WITH latest_fare_systems AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__fare_systems'),
        order_by = 'dt DESC'
        ) }}
),

-- TODO: make this table actually historical
historical AS (
    SELECT
        *,
        TRUE AS _is_current,
        CAST(universal_first_val AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _valid_to
    FROM latest_fare_systems
),


int_transit_database__fare_systems_dim AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', '_valid_from']) }} AS key,
        id AS original_record_id,
        fare_system,
        fares_based_on_zone,
        fares_based_on_route,
        zone_based_fares,
        flat_fares,
        reduced_fare,
        generalized_fare_categories,
        reduced_fare_categories,
        category_notes,
        transfers_allowed,
        transfer_time,
        transfer_fee,
        transfers_notes,
        interagency_transfers,
        interagency_transfer_notes,
        pass_times_trips,
        pass_notes,
        reservations,
        group_school_trip_discount,
        ticket_pass_sales_methods,
        payment_accepted,
        ticket_media,
        electronic_fare_program,
        ticket_validation,
        bike_fee,
        cheaper_base_fare_with_smartcard,
        reg_adult_ticket_price_min,
        reg_adult_ticket_price_max,
        pass_price_min,
        pass_price_max,
        fare_capping,
        paratransit_fare_url,
        demand_response_fare_url,
        itp_id,
        transit_services,
        _is_current,
        _valid_from,
        _valid_to
    FROM historical
)

SELECT * FROM int_transit_database__fare_systems_dim
