WITH

ct_organizations AS (
    SELECT *
    FROM {{ source('airtable', 'california_transit__organizations') }}
    WHERE TRIM(name) IS NOT NULL
),

tts_organizations AS (
    SELECT *
    FROM {{ source('airtable', 'transit_technology_stacks__organizations') }}
    WHERE TRIM(name) IS NOT NULL
),

int_tts_organizations_ct_organizations_map AS (
    {{ transit_database_synced_table_id_mapping(
        table_a = 'ct_organizations',
        base_a = 'ct',
        table_a_id_col = 'organization_id',
        table_a_name_col = 'name',
        table_a_date_col = 'dt',
        table_b = 'tts_organizations',
        base_b = 'tts',
        table_b_id_col = 'organization_id',
        table_b_name_col = 'name',
        table_b_date_col = 'dt',
        shared_id_name = 'key',
        shared_name_name = 'name',
        shared_date_name = 'date') }}
)

SELECT * FROM int_tts_organizations_ct_organizations_map
