WITH

ct_services AS (
    SELECT
        * EXCEPT(name),
        COALESCE(name, "missing_name_" || CAST(ROW_NUMBER() OVER (ORDER BY name) AS STRING)) AS name
    FROM {{ source('airtable', 'california_transit__services') }}
),

tts_services AS (
    SELECT
        * EXCEPT(name),
        COALESCE(name, "missing_name_" || CAST(ROW_NUMBER() OVER (ORDER BY name) AS STRING)) AS name
    FROM {{ source('airtable', 'transit_technology_stacks__services') }}
),

int_tts_services_ct_services_map AS (
    SELECT DISTINCT
        tts.service_id AS tts_service_id,
        ct.service_id AS ct_service_id,
        tts.name AS tts_name,
        ct.name AS ct_name,
        tts.dt AS tts_date,
        tts.time AS tts_time,
        ct.dt AS ct_date,
        ct.time AS ct_time
    FROM ct_services AS ct
    FULL OUTER JOIN tts_services AS tts
        USING (name, dt)
)

SELECT * FROM int_tts_services_ct_services_map
