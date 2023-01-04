{{ config(materialized='ephemeral') }}

{{ dbt_utils.date_spine(
    datepart="day",
    start_date="cast('2021-04-15' as datetime)",
    end_date="DATE_ADD(CURRENT_DATE(), INTERVAL 1 YEAR)"
   )
    }}
