{{ config(materialized='ephemeral') }}

-- 2022-06-29 is the first date that v2 airtable data was extracted
{{ dbt_utils.date_spine(
    datepart="day",
    start_date="cast('2022-06-29' AS datetime)",
    end_date="CURRENT_DATE()"
   )
    }}
