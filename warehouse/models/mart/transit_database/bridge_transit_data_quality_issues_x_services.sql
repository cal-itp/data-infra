{{ config(materialized='table') }}

WITH transit_data_quality_issues AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__transit_data_quality_issues') }}
),

services AS ( -- noqa
    SELECT *
    FROM {{ ref('dim_services') }}
),

bridge_transit_data_quality_issues_x_services AS (
 {{ transit_database_many_to_many_versioned(
    shared_start_date_name = '_valid_from',
    shared_end_date_name = '_valid_to',
    shared_current_name = '_is_current',
    table_a = {'name': 'transit_data_quality_issues',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'transit_data_quality_issue_key',
        'name_col': 'issue__',
        'name_col_name': 'transit_data_quality_issue_issue__',
        'unversioned_join_col': 'services',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'services',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'service_key',
        'name_col': 'name',
        'name_col_name': 'service_name',
        'unversioned_join_col': 'key',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
)

SELECT * FROM bridge_transit_data_quality_issues_x_services
