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
),
fct_old_enrollments AS (
  SELECT
    app,
    device_id,
    user_id,
    client_event_time,
    event_id,
    session_id,
    "returned enrollment" as event_type,
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
    event_properties_auth_provider,
    event_properties_card_tokenize_func,
    event_properties_card_tokenize_url,
    CASE
      WHEN client_event_time < '2022-08-12T07:00:00Z'
        THEN "DMV"
      WHEN client_event_time >= '2022-08-12T07:00:00Z'
        THEN "OAuth claims via Login.gov"
    END as event_properties_eligibility_verifier,
    event_properties_error.name,
    event_properties_error.status,
    event_properties_error.sub,
    event_properties_href,
    event_properties_language,
    event_properties_origin,
    event_properties_path,
    "5170d37b-43d5-4049-899c-b4d850e14990" as event_properties_payment_group,
    "success" as event_properties_status,
    "Monterey-Salinas Transit" as event_properties_transit_agency,
    "senior" as event_properties_eligibility_types,
    CASE
      WHEN client_event_time < '2022-08-12T07:00:00Z'
        THEN "DMV"
      WHEN client_event_time >= '2022-08-12T07:00:00Z'
        THEN "OAuth claims via Login.gov"
    END as user_properties_eligibility_verifier,
    user_properties_initial_referrer,
    user_properties_initial_referring_domain,
    "Monterey-Salinas Transit" as user_properties_transit_agency,
    user_properties_user_agent,
    user_properties_referrer,
    user_properties_referring_domain,
    "senior" as user_properties_eligibility_types
  FROM fct_benefits_events
  WHERE client_event_time >= '2021-12-08T08:00:00Z'
    and client_event_time < '2022-08-29T07:00:00Z'
    and (region = 'California' or region is null)
    and (city != 'Los Angeles' or city is null)
    and event_type = 'viewed page'
    and event_properties_path = '/enrollment/success'
)

SELECT * FROM fct_benefits_events
UNION DISTINCT
SELECT * FROM fct_old_enrollments
