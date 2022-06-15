WITH

ct_organizations AS (
    SELECT *
    FROM {{ source('airtable', 'california_transit__organizations') }}
    WHERE TRIM(name) != ""
),

tts_organizations AS (
    SELECT *
    FROM {{ source('airtable', 'transit_technology_stacks__organizations') }}
    WHERE TRIM(name) != ""
),

int_tts_organizations_ct_organizations_map AS (
    {{ transit_database_synced_table_id_mapping(
        table_a_dict = {'table_name': 'ct_organizations',
            'base': 'ct',
            'id_col': 'organization_id'
        },
        table_b_dict = {'table_name': 'tts_organizations',
            'base': 'tts',
            'id_col': 'organization_id'
        })
    }}
)

SELECT * FROM int_tts_organizations_ct_organizations_map
