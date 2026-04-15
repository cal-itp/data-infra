{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        }
    )
}}

select *
from {{ ref('fct_scheduled_trips') }}
where service_date
between
    {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_MICROBATCH_LOOKBACK_DAYS"), data_earliest_start=var("GTFS_SCHEDULE_START")) }}
    and {{ ranged_incremental_max_date() }}
