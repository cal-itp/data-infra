{{ config(materialized='table') }}

WITH fct_benefits_events AS (
    SELECT
        -- Only fields that aren't _always_ empty (https://dashboards.calitp.org/question#eyJkYXRhc2V0X3F1ZXJ5Ijp7ImRhdGFiYXNlIjoyLCJxdWVyeSI6eyJzb3VyY2UtdGFibGUiOjM1ODR9LCJ0eXBlIjoicXVlcnkifSwiZGlzcGxheSI6InRhYmxlIiwidmlzdWFsaXphdGlvbl9zZXR0aW5ncyI6e319)
        app,
        device_id,
        user_id,
        client_event_time,
        event_id,
        session_id,
        event_type,
        version_name,
        os_name,
        os_version,
        device_family,
        device_type,
        country,
        language,
        library,
        city,
        region,
        event_time,
        client_upload_time,
        server_upload_time,
        server_received_time,
        amplitude_id,
        start_version,
        uuid,
        processed_time,

        -- Event Properties (https://app.amplitude.com/data/compiler/Benefits/properties/main/latest/event)
        {{ json_extract_column('event_properties', 'auth_provider') }},
        {{ json_extract_column('event_properties', 'card_tokenize_func') }},
        {{ json_extract_column('event_properties', 'card_tokenize_url') }},
        {{ json_extract_column('event_properties', 'eligibility_verifier') }},
        {{ json_extract_column('event_properties', 'error.name') }},
        {{ json_extract_column('event_properties', 'error.status') }},
        {{ json_extract_column('event_properties', 'error.sub') }},
        {{ json_extract_column('event_properties', 'href') }},
        {{ json_extract_column('event_properties', 'language') }},
        {{ json_extract_column('event_properties', 'origin') }},
        {{ json_extract_column('event_properties', 'path') }},
        {{ json_extract_column('event_properties', 'payment_group') }},
        {{ json_extract_column('event_properties', 'status') }},
        {{ json_extract_column('event_properties', 'transit_agency') }},
        {{ json_extract_flattened_column('event_properties', 'eligibility_types') }},

        -- User Properties (https://app.amplitude.com/data/compiler/Benefits/properties/main/latest/user)
        {{ json_extract_column('user_properties', 'eligibility_verifier') }},
        {{ json_extract_column('user_properties', 'initial_referrer') }},
        {{ json_extract_column('user_properties', 'initial_referring_domain') }},

        -- Historical data existed in `provider_name` but new data is in `transit_agency`
        -- https://github.com/cal-itp/benefits/pull/901
        COALESCE(
            {{ json_extract_column('user_properties', 'transit_agency', no_alias = true) }},
            {{ json_extract_column('user_properties', 'provider_name', no_alias = true) }}
        ) AS user_properties_transit_agency,

        {{ json_extract_column('user_properties', 'referrer') }},
        {{ json_extract_column('user_properties', 'referring_domain') }},
        {{ json_extract_column('user_properties', 'user_agent') }},
        {{ json_extract_flattened_column('user_properties', 'eligibility_types') }}

    FROM {{ ref('stg_amplitude__benefits_events') }}
)

SELECT * FROM fct_benefits_events
