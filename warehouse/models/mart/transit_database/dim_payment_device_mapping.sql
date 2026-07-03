{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__payment_device_mapping_dim') }}
),

dim_payment_device_mapping AS (
    SELECT
        key,
        source_record_id,
        device_id,
        littlepay_participant_id,
        agency_organization_source_record_id,
        agency_name,
        notes,
        start_date,
        end_date,
        status,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM dim_payment_device_mapping
