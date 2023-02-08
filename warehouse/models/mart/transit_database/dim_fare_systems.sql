{{ config(materialized='table') }}

WITH int_transit_database__fare_systems_dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__fare_systems_dim') }}
),

dim_fare_systems AS (
    SELECT
        key,
        source_record_id,
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
        _is_current,
        _valid_from,
        _valid_to
    FROM int_transit_database__fare_systems_dim
)

SELECT * FROM dim_fare_systems
