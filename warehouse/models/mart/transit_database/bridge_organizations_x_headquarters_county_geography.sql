{{ config(materialized='table') }}

WITH orgs AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__organizations_dim') }}
),

county_geography AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__county_geography_dim') }}
),

bridge_organizations_x_headquarters_county_geography AS (
 {{ transit_database_many_to_many_versioned(
    shared_start_date_name = '_valid_from',
    shared_end_date_name = '_valid_to',
    shared_current_name = '_is_current',
    table_a = {'name': 'orgs',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'organization_key',
        'name_col': 'name',
        'name_col_name': 'organization_name',
        'unversioned_join_col': 'hq_county_geography',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'county_geography',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'county_geography_key',
        'name_col': 'name',
        'name_col_name': 'county_geography_name',
        'unversioned_join_col': 'organization_key',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
)

SELECT * FROM bridge_organizations_x_headquarters_county_geography
