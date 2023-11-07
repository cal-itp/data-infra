{{ config(materialized='table') }}

WITH fct_benefits_events AS (
    SELECT
        *,
        JSON_VALUE(event_properties, '$.path') AS event_properties_path,
        JSON_VALUE(event_properties, '$.eligibility_verifier') AS event_properties_eligibility_verifier,
        JSON_VALUE(event_properties, '$.transit_agency') AS event_properties_transit_agency,
        ARRAY_TO_STRING(
            JSON_VALUE_ARRAY(event_properties, '$.eligibility_types'),
            ';'
        ) AS event_properties_eligibility_types,
        JSON_VALUE(user_properties, '$.referrer') AS user_properties_referrer,
        JSON_VALUE(user_properties, '$.referring_domain') AS user_properties_referring_domain,
        JSON_VALUE(user_properties, '$.user_agent') AS user_properties_user_agent
    FROM {{ ref('stg_amplitude__benefits_events') }}
)

SELECT * FROM fct_benefits_events
