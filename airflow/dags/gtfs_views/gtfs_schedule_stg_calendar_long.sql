---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_stg_calendar_long"

tests:
  check_composite_unique:
    - calitp_itp_id
    - calitp_url_number
    - service_id
    - day_name
    - calitp_extracted_at

external_dependencies:
    - gtfs_views_staging: all

---

# Note that you can unnest values easily in SQL, but getting the column names
# is weirdly hard. To work around this, we just UNION ALL.
{% for dow in ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"] %}

{% if not loop.first %}
UNION ALL
{% endif %}

SELECT
  calitp_itp_id
  , calitp_url_number
  , service_id
  , start_date
  , end_date
  , calitp_extracted_at
  , calitp_deleted_at
  , "{{dow | title}}" AS day_name
  , {{dow}} AS service_indicator
FROM `gtfs_views_staging.calendar_clean`
{% endfor %}
