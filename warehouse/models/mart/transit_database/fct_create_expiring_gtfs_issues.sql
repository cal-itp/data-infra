{{ config(materialized='table') }}

WITH base_calendar_max AS (
  SELECT
    feed_key,
    MAX(end_date) AS max_calendar
  FROM {{ ref('dim_calendar_latest') }}
  WHERE monday = 1
     OR tuesday = 1
     OR wednesday = 1
     OR thursday = 1
     OR friday = 1
     OR saturday = 1
     OR sunday = 1
  GROUP BY feed_key
),

base_calendar_exceptions_max AS (
  SELECT
    feed_key,
    MAX(date) AS max_calendar_date
  FROM {{ ref('dim_calendar_dates_latest') }}
  WHERE exception_type = 1
  GROUP BY feed_key
),

feed_max_service_end AS (
  SELECT
    COALESCE(c.feed_key, e.feed_key) AS feed_key,
    GREATEST(
      COALESCE(c.max_calendar, e.max_calendar_date),
      COALESCE(e.max_calendar_date, c.max_calendar)
    ) AS max_end_date
  FROM base_calendar_max c
  FULL OUTER JOIN base_calendar_exceptions_max e
    USING (feed_key)
),

current_schedule_feeds AS (
  SELECT
    ms.feed_key,
    ms.max_end_date,
    sf.base64_url
  FROM feed_max_service_end ms
  INNER JOIN {{ ref('dim_schedule_feeds') }} sf
    ON ms.feed_key = sf.key
  WHERE sf._is_current = TRUE
),

datasets_with_expiration AS (
  SELECT
    dg.name,
    dg.key AS gtfs_dataset_key,
    dg.source_record_id AS gtfs_dataset_source_record_id,
    csf.max_end_date,
    CASE
      WHEN csf.max_end_date < CURRENT_DATE() THEN 'Expired'
      WHEN DATE_ADD(csf.max_end_date, INTERVAL -31 DAY) < CURRENT_DATE()
        THEN 'Expiring in Less Than 30 Days'
      ELSE 'OK'
    END AS expiration_status
  FROM current_schedule_feeds csf
  INNER JOIN {{ ref('dim_gtfs_datasets') }} dg
    USING (base64_url)
  WHERE dg._is_current = TRUE
),

expiring_datasets AS (
  SELECT
    dwe.name,
    dwe.gtfs_dataset_source_record_id,
    dwe.max_end_date,
    dwe.expiration_status,
    ARRAY_AGG(
      STRUCT(
        dp.service_name,
        dp.service_source_record_id,
        dp.organization_name
      )
      ORDER BY dp.service_source_record_id
      LIMIT 1
    )[OFFSET(0)] AS service_info
  FROM datasets_with_expiration dwe
  INNER JOIN {{ ref('dim_provider_gtfs_data') }} dp
    ON dwe.gtfs_dataset_key = dp.schedule_gtfs_dataset_key
  WHERE dwe.expiration_status != 'OK'
    AND dp._is_current = TRUE
    AND dp.public_customer_facing_or_regional_subfeed_fixed_route
  GROUP BY
    dwe.name,
    dwe.gtfs_dataset_source_record_id,
    dwe.max_end_date,
    dwe.expiration_status
),

airtable_services_latest AS (
  SELECT DISTINCT
    source_record_id,
    id
  FROM {{ source('external_airtable', 'transit_data_quality_issues__services') }}
  WHERE dt = (
    SELECT MAX(dt)
    FROM {{ source('external_airtable', 'transit_data_quality_issues__services') }}
  )
),

airtable_datasets_latest AS (
  SELECT DISTINCT
    source_record_id,
    id
  FROM {{ source('external_airtable', 'transit_data_quality_issues__gtfs_datasets') }}
  WHERE dt = (
    SELECT MAX(dt)
    FROM {{ source('external_airtable', 'transit_data_quality_issues__gtfs_datasets') }}
  )
),

expiring_datasets_with_airtable_ids AS (
  SELECT
    ed.name,
    ed.gtfs_dataset_source_record_id,
    ed.max_end_date,
    ed.expiration_status,
    ed.service_info.service_name AS service_name,
    ed.service_info.service_source_record_id AS service_source_record_id,
    ed.service_info.organization_name AS organization_name,
    s.id AS service_record_id,
    d.id AS gtfs_dataset_record_id
  FROM expiring_datasets ed
  INNER JOIN airtable_services_latest s
    ON ed.service_info.service_source_record_id = s.source_record_id
  INNER JOIN airtable_datasets_latest d
    ON ed.gtfs_dataset_source_record_id = d.source_record_id
),

expiring_open_issues AS (
  SELECT
    gtfs_dataset_source_record_id,
    issue__ AS issue_number
  FROM {{ ref('fct_transit_data_quality_issues') }}
  WHERE is_open = TRUE
    AND issue_type_name IN (
      'About to Expire Schedule Feed',
      'Expired Schedule Feed',
      'Expiring feed maintained by Cal-ITP',
      'Los Angeles Metro feed transition',
      'About to Expire Feed'
    )
),

fct_create_expiring_gtfs_issues AS (
  SELECT
    edwai.name AS gtfs_dataset_name,
    edwai.max_end_date,
    edwai.expiration_status,
    edwai.gtfs_dataset_record_id,
    edwai.service_name,
    edwai.service_record_id,
    edwai.organization_name
  FROM expiring_datasets_with_airtable_ids edwai
  LEFT JOIN expiring_open_issues i
    ON edwai.gtfs_dataset_source_record_id = i.gtfs_dataset_source_record_id
  WHERE i.issue_number IS NULL
)

SELECT *
FROM fct_create_expiring_gtfs_issues
ORDER BY max_end_date, gtfs_dataset_name
