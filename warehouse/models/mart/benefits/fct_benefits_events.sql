{{ config(materialized='table') }}

WITH fct_benefits_events_raw AS (
  -- fct_benefits_events_raw extracts JSON columns and
  -- COALESCEs old columns as they evolve
  -- this is an intermediate CTE used to build the final table

  -- Keep fields in alphabetical order, list all fields in the final table
  SELECT
    amplitude_id,
    app,
    city,
    client_event_time,
    client_upload_time,
    country,
    device_family,
    device_id,
    device_type,
    event_id,
    {{ json_extract_column('event_properties', 'card_category') }},
    {{ json_extract_column('event_properties', 'card_scheme') }},
    {{ json_extract_column('event_properties', 'card_tokenize_func') }},
    {{ json_extract_column('event_properties', 'card_tokenize_url') }},
    -- Historical data existed in `auth_provider` but new data is in `claims_provider`
    -- https://github.com/cal-itp/benefits/pull/2401
    COALESCE(
      {{ json_extract_column('event_properties', 'claims_provider', no_alias = true) }},
      {{ json_extract_column('event_properties', 'auth_provider', no_alias = true) }}
    ) AS event_properties_claims_provider,
    {{ json_extract_column('event_properties', 'eligibility_verifier') }},
    -- Historical data existed in `eligibility_types` but new data is in `enrollment_flows`
    -- https://github.com/cal-itp/benefits/pull/2379
    COALESCE(
        {{ json_extract_flattened_column('event_properties', 'enrollment_flows', no_alias = true) }},
        {{ json_extract_flattened_column('event_properties', 'eligibility_types', no_alias = true) }}
    ) AS event_properties_enrollment_flows,
    -- Historical data existed in `payment_group` but new data is in `enrollment_group`
    -- https://github.com/cal-itp/benefits/pull/2391
    COALESCE(
        {{ json_extract_column('event_properties', 'enrollment_group', no_alias = true) }},
        {{ json_extract_column('event_properties', 'payment_group', no_alias = true) }}
    ) AS event_properties_enrollment_group,
    -- New column `enrollment_method`, historical values should be set to "digital"
    -- https://github.com/cal-itp/benefits/pull/2402
    COALESCE(
      {{ json_extract_column('event_properties', 'enrollment_method', no_alias = true) }},
      "digital"
    ) AS event_properties_enrollment_method,
    {{ json_extract_column('event_properties', 'error.name') }},
    {{ json_extract_column('event_properties', 'error.status') }},
    {{ json_extract_column('event_properties', 'error.sub') }},
    -- Combining null and blank extra_claims into blank, to avoid counting them separately
    COALESCE(
      {{ json_extract_flattened_column('event_properties', 'extra_claims', no_alias = true) }},
      ""
    ) AS event_properties_extra_claims,
    {{ json_extract_column('event_properties', 'href') }},
    {{ json_extract_column('event_properties', 'language') }},
    {{ json_extract_column('event_properties', 'origin') }},
    {{ json_extract_column('event_properties', 'path') }},
    {{ json_extract_column('event_properties', 'status') }},
    {{ json_extract_column('event_properties', 'transit_agency') }},
    -- Auto-populate `transit_processor` with 'littlepay' for all events prior to first confirmed Switchio enrollment
    COALESCE(
      {{ json_extract_column('event_properties', 'transit_processor', no_alias = true) }},
      CASE WHEN client_event_time < '2025-10-24T19:00:00Z' THEN "littlepay" END,
      ""
    ) AS event_properties_transit_processor,
    event_time,
    event_type,
    language,
    library,
    os_name,
    os_version,
    processed_time,
    region,
    server_received_time,
    server_upload_time,
    session_id,
    start_version,
    user_id,
    {{ json_extract_column('user_properties', 'eligibility_verifier') }},
    -- Historical data existed in `eligibility_types` but new data is in `enrollment_flows`
    -- https://github.com/cal-itp/benefits/pull/2379
    COALESCE(
        {{ json_extract_flattened_column('user_properties', 'enrollment_flows', no_alias = true) }},
        {{ json_extract_flattened_column('user_properties', 'eligibility_types', no_alias = true) }}
    ) AS user_properties_enrollment_flows,
    -- New column `enrollment_method`, historical values should be set to "digital"
    -- https://github.com/cal-itp/benefits/pull/2402
    COALESCE(
      {{ json_extract_column('user_properties', 'enrollment_method', no_alias = true) }},
      "digital"
    ) AS user_properties_enrollment_method,
    {{ json_extract_column('user_properties', 'initial_referrer') }},
    {{ json_extract_column('user_properties', 'initial_referring_domain') }},
    {{ json_extract_column('user_properties', 'referrer') }},
    {{ json_extract_column('user_properties', 'referring_domain') }},
    -- Historical data existed in `provider_name` but new data is in `transit_agency`
    -- https://github.com/cal-itp/benefits/pull/901
    COALESCE(
        {{ json_extract_column('user_properties', 'transit_agency', no_alias = true) }},
        {{ json_extract_column('user_properties', 'provider_name', no_alias = true) }}
    ) AS user_properties_transit_agency,
    {{ json_extract_column('user_properties', 'user_agent') }},
    uuid,
    version_name
  FROM {{ ref('stg_amplitude__benefits_events') }}
),
fct_benefits_events AS (
  -- fct_benefits_events applies data cleanup and transformations
  -- on top of the fct_benefits_events_raw CTE
  -- this is an intermediate CTE used to build the final table

  -- Keep fields in alphabetical order, list all fields in the final table
  SELECT
    amplitude_id,
    app,
    city,
    client_event_time,
    client_upload_time,
    country,
    device_family,
    device_id,
    device_type,
    event_id,
    event_properties_card_category,
    event_properties_card_scheme,
    event_properties_card_tokenize_func,
    event_properties_card_tokenize_url,
    CASE
      WHEN event_properties_claims_provider = "cdt-logingov-ial2"
        THEN "cdt-logingov"
      ELSE event_properties_claims_provider
    END AS event_properties_claims_provider,
    -- Normalize historic data into current format
    -- https://github.com/cal-itp/benefits/issues/2521
    CASE
      WHEN event_properties_eligibility_verifier IN (
        '(MST) CDT claims via Login.gov',
        '(SBMTD) CDT claims via Login.gov',
        'CDT claims via Login.gov (MST)',
        'CDT claims via Login.gov (SBMTD)',
        'OAuth claims via Login.gov',
        'senior'
      ) THEN "cdt-logingov"
      WHEN event_properties_eligibility_verifier IN (
        '(MST) VA.gov - Veteran',
        'VA.gov - Veteran (MST)',
        'veteran'
      ) THEN "cdt-vagov"
      WHEN event_properties_eligibility_verifier IN (
        '(MST) Courtesy Card Eligibility Server Verifier (prod)',
        'MST Courtesy Card Eligibility Server Verifier',
        'courtesy_card'
      ) THEN "https://mst-courtesy-cards-eligibility-server-prod-azcscsbmembwcugk.z01.azurefd.net/verify"
      WHEN event_properties_eligibility_verifier IN (
        '(SBMTD) Mobility Pass Eligibility Server Verifier (prod)',
        'SBMTD Mobility Pass Eligibility Server Verifier (prod)',
        'mobility_pass'
      ) THEN "https://sbmtd-mobility-pass-eligibility-server-prod-h3d3djedb7ahfqeg.z01.azurefd.net/verify"
      ELSE event_properties_eligibility_verifier
    END AS event_properties_eligibility_verifier,
    event_properties_enrollment_flows,
    event_properties_enrollment_group,
    event_properties_enrollment_method,
    event_properties_error_name,
    event_properties_error_status,
    event_properties_error_sub,
    event_properties_extra_claims,
    event_properties_href,
    event_properties_language,
    event_properties_origin,
    event_properties_path,
    event_properties_status,
    event_properties_transit_agency,
    event_properties_transit_processor,
    event_time,
    CASE
      WHEN event_type = "selected eligibility verifier"
        THEN "selected enrollment flow"
      WHEN event_type = "started payment connection"
        THEN "started card tokenization"
      WHEN event_type = "closed payment connection" or event_type = "ended card tokenization"
        THEN "finished card tokenization"
      ELSE event_type
    END AS event_type,
    language,
    library,
    os_name,
    os_version,
    processed_time,
    region,
    server_received_time,
    server_upload_time,
    session_id,
    -- Fix bugs in Docker build process resulting in incorrect version strings
    -- https://github.com/cal-itp/benefits/pull/2392
    -- https://github.com/cal-itp/benefits/pull/3314
    CASE
      WHEN start_version = "2024.7.3.dev0+gcd3b083.d20240731"
        THEN "2024.7.2"
      WHEN start_version = "2024.8.2.dev0+g7664917.d20240821"
        THEN "2024.8.1"
      WHEN start_version = "2024.9.2.dev0+gadf41b9.d20240909"
        THEN "2024.9.1"
      WHEN start_version = "2024.9.3.dev0+gfeb06d2.d20240918"
        THEN "2024.9.2"
      WHEN start_version = "2024.9.4.dev0+g861519e.d20240926"
        THEN "2024.9.3"
      WHEN start_version = "2024.10.2.dev0+g158e1b0.d20241010"
        THEN "2024.10.1"
      WHEN start_version = "2025.8.2.dev0+g6908fadc2.d20250825"
        THEN "2025.8.1"
      WHEN start_version = "2025.10.2.dev0+ge1598d1c5.d20251003"
        THEN "2025.10.1"
      WHEN start_version = "2025.11.2.dev0+gc6af905c7.d20251105"
        THEN "2025.11.1"
      ELSE start_version
    END AS start_version,
    user_id,
    -- Normalize historic data into current format
    -- https://github.com/cal-itp/benefits/issues/2521
    CASE
      WHEN user_properties_eligibility_verifier IN (
        '(MST) CDT claims via Login.gov',
        '(SBMTD) CDT claims via Login.gov',
        'CDT claims via Login.gov (MST)',
        'CDT claims via Login.gov (SBMTD)',
        'OAuth claims via Login.gov',
        'senior'
      ) THEN "cdt-logingov"
      WHEN user_properties_eligibility_verifier IN (
        '(MST) VA.gov - Veteran',
        'VA.gov - Veteran (MST)',
        'veteran'
      ) THEN "cdt-vagov"
      WHEN user_properties_eligibility_verifier IN (
        '(MST) Courtesy Card Eligibility Server Verifier (prod)',
        'MST Courtesy Card Eligibility Server Verifier',
        'courtesy_card'
      ) THEN "https://mst-courtesy-cards-eligibility-server-prod-azcscsbmembwcugk.z01.azurefd.net/verify"
      WHEN user_properties_eligibility_verifier IN (
        '(SBMTD) Mobility Pass Eligibility Server Verifier (prod)',
        'SBMTD Mobility Pass Eligibility Server Verifier (prod)',
        'mobility_pass'
      ) THEN "https://sbmtd-mobility-pass-eligibility-server-prod-h3d3djedb7ahfqeg.z01.azurefd.net/verify"
      ELSE user_properties_eligibility_verifier
    END AS user_properties_eligibility_verifier,
    user_properties_enrollment_flows,
    user_properties_enrollment_method,
    user_properties_initial_referrer,
    user_properties_initial_referring_domain,
    user_properties_referrer,
    user_properties_referring_domain,
    user_properties_transit_agency,
    user_properties_user_agent,
    uuid,
    -- Fix bugs in Docker build process resulting in incorrect version strings
    -- https://github.com/cal-itp/benefits/pull/2392
    -- https://github.com/cal-itp/benefits/pull/3314
    CASE
      WHEN version_name = "2024.7.3.dev0+gcd3b083.d20240731"
        THEN "2024.7.2"
      WHEN version_name = "2024.8.2.dev0+g7664917.d20240821"
        THEN "2024.8.1"
      WHEN version_name = "2024.9.2.dev0+gadf41b9.d20240909"
        THEN "2024.9.1"
      WHEN version_name = "2024.9.3.dev0+gfeb06d2.d20240918"
        THEN "2024.9.2"
      WHEN version_name = "2024.9.4.dev0+g861519e.d20240926"
        THEN "2024.9.3"
      WHEN version_name = "2024.10.2.dev0+g158e1b0.d20241010"
        THEN "2024.10.1"
      WHEN version_name = "2025.8.2.dev0+g6908fadc2.d20250825"
        THEN "2025.8.1"
      WHEN version_name = "2025.10.2.dev0+ge1598d1c5.d20251003"
        THEN "2025.10.1"
      WHEN version_name = "2025.11.2.dev0+gc6af905c7.d20251105"
        THEN "2025.11.1"
      ELSE version_name
    END AS version_name
  FROM fct_benefits_events_raw
  -- Filter out events from the Azure healthprobe feature
  -- captured before we stopped sending events for this feature
  -- https://github.com/cal-itp/benefits/issues/1276
  WHERE user_properties_user_agent NOT IN ('Edge Health Probe', 'AlwaysOn')
),
fct_benefits_historic_enrollments AS (
  -- fct_benefits_historic_enrollments transforms old enrollment events
  -- from the fct_benefits_events CTE into the newer style
  -- this is an intermediate CTE used to build the final table

  -- Keep fields in alphabetical order, list all fields in the final table
  SELECT
    amplitude_id,
    app,
    city,
    client_event_time,
    client_upload_time,
    country,
    device_family,
    device_id,
    device_type,
    event_id,
    event_properties_card_category,
    event_properties_card_scheme,
    event_properties_card_tokenize_func,
    event_properties_card_tokenize_url,
    CASE
      WHEN client_event_time < '2022-08-12T07:00:00Z'
        THEN "ca-dmv"
      WHEN client_event_time >= '2022-08-12T07:00:00Z'
        THEN "cdt-logingov"
    END AS event_properties_claims_provider,
    CASE
      WHEN client_event_time < '2022-08-12T07:00:00Z'
        THEN "ca-dmv"
      WHEN client_event_time >= '2022-08-12T07:00:00Z'
        THEN "cdt-logingov"
    END AS event_properties_eligibility_verifier,
    "senior" AS event_properties_enrollment_flows,
    "5170d37b-43d5-4049-899c-b4d850e14990" AS event_properties_enrollment_group,
    event_properties_enrollment_method,
    event_properties_error_name,
    event_properties_error_status,
    event_properties_error_sub,
    event_properties_extra_claims,
    event_properties_href,
    event_properties_language,
    event_properties_origin,
    event_properties_path,
    "success" AS event_properties_status,
    "Monterey-Salinas Transit" AS event_properties_transit_agency,
    event_properties_transit_processor,
    event_time,
    "returned enrollment" AS event_type,
    language,
    library,
    os_name,
    os_version,
    processed_time,
    region,
    server_received_time,
    server_upload_time,
    session_id,
    start_version,
    user_id,
    CASE
      WHEN client_event_time < '2022-08-12T07:00:00Z'
        THEN "ca-dmv"
      WHEN client_event_time >= '2022-08-12T07:00:00Z'
        THEN "cdt-logingov"
    END AS user_properties_eligibility_verifier,
    "senior" AS user_properties_enrollment_flows,
    user_properties_enrollment_method,
    user_properties_initial_referrer,
    user_properties_initial_referring_domain,
    user_properties_referrer,
    user_properties_referring_domain,
    "Monterey-Salinas Transit" AS user_properties_transit_agency,
    user_properties_user_agent,
    uuid,
    version_name
  FROM fct_benefits_events
  WHERE client_event_time >= '2021-12-08T08:00:00Z'
    and client_event_time < '2022-08-29T07:00:00Z'
    and (region = 'California' or region is null)
    and (city != 'Los Angeles' or city is null)
    and event_type = 'viewed page'
    and event_properties_path = '/enrollment/success'
)

-- the final table is the combination of
-- fct_benefits_historic_enrollments + fct_benefits_events
SELECT * FROM fct_benefits_historic_enrollments
UNION DISTINCT
SELECT * FROM fct_benefits_events
