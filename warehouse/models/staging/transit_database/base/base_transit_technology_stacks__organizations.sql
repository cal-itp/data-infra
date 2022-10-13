WITH

source AS (
    SELECT * FROM {{ source('airtable_tts', 'transit_technology_stacks__organizations') }}
),

base_transit_technology_stacks__organizations AS (
    SELECT
        id AS record_id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        ts
    FROM source
    WHERE name IS NOT NULL
)

SELECT * FROM base_transit_technology_stacks__organizations
