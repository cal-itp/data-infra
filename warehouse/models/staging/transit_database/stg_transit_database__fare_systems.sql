

WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__fare_systems'),
        order_by = 'time DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__fare_systems AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "fare_system") }},
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
        mobility_services_managed__from_transit_provider_,
        gtfs_dataset__from_mobility_services_managed___from_transit_provider_,
        unnested_transit_provider AS transit_provider_organization_key,
        fares_v2_status__from_mobility_services_managed___from_transit_provider_,
        itp_id,
        time,
        dt AS calitp_extracted_at
    FROM latest
    LEFT JOIN UNNEST(latest.transit_provider) AS unnested_transit_provider
)

SELECT * FROM stg_transit_database__fare_systems
