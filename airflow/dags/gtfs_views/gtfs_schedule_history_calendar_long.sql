---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_history_calendar_long"
dependencies:
  - warehouse_loaded
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
  , PARSE_DATE("%Y%m%d", start_date) AS start_date
  , PARSE_DATE("%Y%m%d", end_date) AS end_date
  , calitp_extracted_at
  , calitp_deleted_at
  , "{{dow | title}}" AS day_name
  , {{dow}} AS service_indicator
FROM `gtfs_schedule_type2.calendar`
{% endfor %}
