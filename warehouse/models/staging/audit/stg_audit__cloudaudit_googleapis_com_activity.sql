{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'date',
            'data_type': 'date',
            'granularity': 'day',
        },
        partitions=['current_date()'],
    )
}}
-- Note this uses a direct reference instead of source, because a new table is created daily

WITH latest AS (
    {% set today = modules.datetime.date.today() %}

    SELECT *, current_date() as date
    FROM cal-itp-data-infra.audit.cloudaudit_googleapis_com_data_access_{{ today.strftime('%Y%m%d') }}
),

everything AS (
    {% set start_date = modules.datetime.date(year=2022, month=4, day=11) %}
    {% set days = (modules.datetime.date.today() - start_date).days + 1 %}

    {% for add in range(days) %}

    {% set current = start_date + modules.datetime.timedelta(days=add) %}

    SELECT *, EXTRACT(DATE FROM timestamp) AS date
    FROM cal-itp-data-infra.audit.cloudaudit_googleapis_com_data_access_{{ current.strftime('%Y%m%d') }}
    {% if not loop.last %}
    UNION ALL
    {% endif %}

    {% endfor %}
),

stg_audit__cloudaudit_googleapis_com_activity AS (
    SELECT *
    {% if is_incremental() %}
    FROM latest
    {% else %}
    FROM everything
    {% endif %}
)

SELECT * FROM stg_audit__cloudaudit_googleapis_com_activity
