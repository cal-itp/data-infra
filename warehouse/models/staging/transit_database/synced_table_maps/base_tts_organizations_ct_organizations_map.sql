WITH

ct_organizations AS (
    SELECT *, LEAD({{ make_end_of_valid_range('ts') }}, 1,  CAST("2099-01-01" AS TIMESTAMP)) OVER (PARTITION BY name ORDER BY ts) AS next_ts
    FROM {{ ref('base_california_transit__organizations')}}
    WHERE TRIM(name) != ""
),

tts_organizations AS (
    SELECT *, LEAD({{ make_end_of_valid_range('ts') }}, 1,  CAST("2099-01-01" AS TIMESTAMP)) OVER (PARTITION BY name ORDER BY ts) AS next_ts
    FROM {{ ref('base_transit_technology_stacks__organizations')}}
    WHERE TRIM(name) != ""
),

base_tts_organizations_ct_organizations_map AS (
    SELECT
        ct.name AS ct_name,
        ct.key AS ct_key,
        tts.name AS tts_name,
        tts.key AS tts_key,
        -- use the later one for start date
        CASE WHEN ct.ts < tts.ts THEN tts.ts ELSE ct.ts END AS _valid_from,
        -- use the earlier one for end date
        CASE WHEN ct.next_ts < tts.next_ts THEN ct.next_ts ELSE tts.next_ts END AS _valid_to
    FROM ct_organizations AS ct
    INNER JOIN tts_organizations AS tts
        ON ct.name = tts.name
        AND ct.ts < tts.next_ts
        AND ct.next_ts > tts.ts
)

SELECT * FROM base_tts_organizations_ct_organizations_map
