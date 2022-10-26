{{ config(materialized='incremental') }}

new_rows AS (
select *
from stg_trips t1
inner join dim_schedule_feeds t2
    on t1.base64_url = t2.base64_url
    and t1.ts = t2._valid_from
{% if is_incremental %}
    and t2._valid_from >
        (select max(ts)
        from {{ this }})
{% endif %}
)

-- todo: test
-- do full refresh w fake limit on dim schedule feeds
-- run table again, no new rows
-- remove fake limit on dim schedule feeds & rerun it
-- new rows get inserted

select *
from new_rows
