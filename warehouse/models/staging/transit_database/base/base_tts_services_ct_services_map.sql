WITH

ct_services AS (
    SELECT *, LEAD({{ make_end_of_valid_range('ts') }}, 1,  CAST("2099-01-01" AS TIMESTAMP)) OVER (PARTITION BY id ORDER BY ts) AS next_ts
    FROM {{ source('airtable', 'california_transit__services') }}
    WHERE TRIM(name) != ""
),

tts_services AS (
    SELECT *, LEAD({{ make_end_of_valid_range('ts') }}, 1,  CAST("2099-01-01" AS TIMESTAMP)) OVER (PARTITION BY id ORDER BY ts) AS next_ts
    FROM {{ source('airtable', 'transit_technology_stacks__services') }}
    WHERE TRIM(name) != ""
),

base_tts_services_ct_services_map AS (
    SELECT
        ct.name AS ct_name,
        ct.id AS ct_id,
        tts.name AS tts_name,
        tts.id AS tts_id,
        -- use the later one for start date
        CASE WHEN ct.ts < tts.ts THEN tts.ts ELSE ct.ts END AS ts,
        -- use the earlier one for end date
        CASE WHEN ct.next_ts < tts.next_ts THEN ct.next_ts ELSE tts.next_ts END AS next_ts
    FROM ct_services AS ct
    INNER JOIN tts_services AS tts
        ON ct.name = tts.name
        AND ct.ts < tts.next_ts
        AND ct.next_ts > tts.ts
)

SELECT * FROM base_tts_services_ct_services_map
