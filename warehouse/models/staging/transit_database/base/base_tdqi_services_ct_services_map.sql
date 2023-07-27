WITH

ct_services AS ( -- noqa: L045
    SELECT *
    FROM {{ source('airtable', 'california_transit__services') }}
    WHERE TRIM(name) != ""
),

tdqi_services AS ( -- noqa: L045
    SELECT *
    FROM {{ source('airtable', 'transit_data_quality_issues__services') }}
    WHERE TRIM(name) != ""
),

base_tdqi_services_ct_services_map AS (
    {{ transit_database_synced_table_id_mapping(
        table_a_dict = {'table_name': 'ct_services',
            'base': 'ct',
            'id_col': 'id'
        },
        table_b_dict = {'table_name': 'tdqi_services',
            'base': 'tdqi',
            'id_col': 'id'
        }) }}
)

SELECT * FROM base_tdqi_services_ct_services_map
