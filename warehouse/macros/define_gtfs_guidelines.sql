-- declare checks
{% macro static_feed_downloaded_successfully() %}
"GTFS schedule feed downloads successfully"
{% endmacro %}

{% macro no_validation_errors() %}
"No errors in MobilityData GTFS Schedule Validator"
{% endmacro %}

{% macro complete_wheelchair_accessibility_data() %}
"Includes complete wheelchair accessibility data in both stops.txt and trips.txt"
{% endmacro %}

{% macro shapes_file_present() %}
"Shapes.txt file is present"
{% endmacro %}

{% macro shapes_for_all_trips() %}
"Every trip in trips.txt has a shape_id listed"
{% endmacro %}

{% macro shapes_valid() %}
"No shapes-related errors appear in the MobilityData GTFS Schedule Validator"
{% endmacro %}

{% macro technical_contact_listed() %}
"Technical contact is listed in feed_contact_email field within the feed_info.txt file"
{% endmacro %}

{% macro no_rt_validation_errors() %}
"No errors in the MobilityData GTFS Realtime Validator"
{% endmacro %}

{% macro trip_id_alignment() %}
"All trip_ids provided in the GTFS-rt feed exist in the GTFS Schedule feed"
{% endmacro %}

{% macro feed_present_vehicle_positions() %}
"Vehicle positions RT feed is present"
{% endmacro %}

{% macro feed_present_trip_updates() %}
"Trip updates RT feed is present"
{% endmacro %}

{% macro feed_present_service_alerts() %}
"Service alerts RT feed is present"
{% endmacro %}

{% macro rt_https_vehicle_positions() %}
"Vehicle positions RT feed uses HTTPS"
{% endmacro %}

{% macro rt_https_trip_updates() %}
"Trip updates RT feed uses HTTPS"
{% endmacro %}

{% macro rt_https_service_alerts() %}
"Service alerts RT feed uses HTTPS"
{% endmacro %}

{% macro pathways_valid() %}
"No pathways-related errors appear in the MobilityData GTFS Schedule Validator"
{% endmacro %}

{% macro schedule_feed_on_transitland() %}
"GTFS schedule feed is listed on feed aggregator transit.land"
{% endmacro %}

{% macro vehicle_positions_feed_on_transitland() %}
"Vehicle positions RT feed is listed on feed aggregator transit.land"
{% endmacro %}

{% macro trip_updates_feed_on_transitland() %}
"Trip updates RT feed is listed on feed aggregator transit.land"
{% endmacro %}

{% macro service_alerts_feed_on_transitland() %}
"Service alerts RT feed is listed on feed aggregator transit.land"
{% endmacro %}

{% macro schedule_feed_on_mobility_database() %}
"GTFS schedule feed is listed on feed aggregator Mobility Database"
{% endmacro %}

{% macro vehicle_positions_feed_on_mobility_database() %}
"Vehicle positions RT feed is listed on feed aggregator Mobility Database"
{% endmacro %}

{% macro trip_updates_feed_on_mobility_database() %}
"Trip updates RT feed is listed on feed aggregator Mobility Database"
{% endmacro %}

{% macro service_alerts_feed_on_mobility_database() %}
"Service alerts RT feed is listed on feed aggregator Mobility Database"
{% endmacro %}

{% macro include_tts() %}
"Include tts_stop_name entries in stops.txt for stop names that are pronounced incorrectly in most mobile applications"
{% endmacro %}

{% macro no_expired_services() %}
"No expired services are listed in the feed"
{% endmacro %}

{% macro no_7_day_feed_expiration() %}
"Feed will be valid for more than 7 days"
{% endmacro %}

{% macro no_30_day_feed_expiration() %}
"Feed will be valid for more than 30 days"
{% endmacro %}

{% macro passes_fares_validator() %}
"Passes Fares v2 portion of MobilityData GTFS Schedule Validator"
{% endmacro %}

{% macro lead_time() %}
"All schedule changes in the last month have provided at least 7 days of lead time"
{% endmacro %}

{% macro no_pb_error_tu() %}
"Fewer than 1% of requests to Trip updates RT feed result in a protobuf error"
{% endmacro %}

{% macro no_pb_error_sa() %}
"Fewer than 1% of requests to Service alerts RT feed result in a protobuf error"
{% endmacro %}

{% macro no_pb_error_vp() %}
"Fewer than 1% of requests to Vehicle positions RT feed result in a protobuf error"
{% endmacro %}

{% macro persistent_ids_schedule() %}
"Schedule feed maintains persistent identifiers for stop_id, route_id, and agency_id"
{% endmacro %}

{% macro no_stale_vehicle_positions() %}
"Vehicle positions RT feed contains no updates older than 90 seconds"
{% endmacro %}

{% macro no_stale_trip_updates() %}
"Trip updates RT feed contains no updates older than 90 seconds"
{% endmacro %}

{% macro no_stale_service_alerts() %}
"Service alerts RT feed contains no updates older than 10 minutes"
{% endmacro %}

{% macro modification_date_present() %}
"The GTFS Schedule API endpoint is configured to report the file modification date"
{% endmacro %}

-- declare features
{% macro compliance_schedule() %}
"Compliance (Schedule)"
{% endmacro %}

{% macro compliance_rt() %}
"Compliance (RT)"
{% endmacro %}

{% macro accurate_accessibility_data() %}
"Accurate Accessibility Data"
{% endmacro %}

{% macro accurate_service_data() %}
"Accurate Service Data"
{% endmacro %}

{% macro technical_contact_availability() %}
"Technical Contact Availability"
{% endmacro %}

{% macro fixed_route_completeness() %}
"Fixed-Route Completeness"
{% endmacro %}

{% macro feed_aggregator_availability_schedule() %}
"Feed Aggregator Availability (Schedule)"
{% endmacro %}

{% macro feed_aggregator_availability_rt() %}
"Feed Aggregator Availability (RT)"
{% endmacro %}

{% macro best_practices_alignment_schedule() %}
"Best Practices Alignment (Schedule)"
{% endmacro %}

{% macro best_practices_alignment_rt() %}
"Best Practices Alignment (RT)"
{% endmacro %}

{% macro fare_completeness() %}
"Fare Completeness"
{% endmacro %}

{% macro up_to_dateness() %}
"Up-to-Dateness"
{% endmacro %}

-- columns
{% macro gtfs_guidelines_columns() %}
date,
calitp_itp_id,
calitp_url_number,
calitp_agency_name,
check,
status,
feature
{% endmacro %}

-- queries
-- For use in int_gtfs_quality__persistent_ids_schedule:
{% macro ids_version_compare_aggregate(id, dim) %}
(
    -- For a given dim table (stops, routes, agency, etc), get every dim with its corresponding feed version metadata
    WITH ids_version_history AS (
        SELECT t1.{{ id }} AS id,
               t2.*
          FROM {{ dim }} AS t1
          JOIN feed_version_history AS t2
            ON t2.feed_key = t1.feed_key
    ),

    ids_version_compare AS (
      SELECT
             -- base64_url is same between feed versions
             COALESCE(ids.base64_url,prev_ids.base64_url) AS base64_url,
             -- one feed's key is the previous feed's next key
             COALESCE(ids.feed_key,prev_ids.next_feed_key) AS feed_key,
             -- one feed's previous key is the previous feed's key
             COALESCE(ids.prev_feed_key,prev_ids.feed_key) AS prev_feed_key,
             COALESCE(ids.valid_from,prev_ids.next_feed_valid_from) AS valid_from,
             ids.id,
             prev_ids.id AS prev_id
        FROM ids_version_history AS ids
        FULL OUTER JOIN ids_version_history AS prev_ids
          ON ids.prev_feed_key = prev_ids.feed_key
         AND ids.id = prev_ids.id
       -- The first feed version doesn't have a previous to compare to
       WHERE ids.feed_version_number > 1
    )

    SELECT base64_url,
           feed_key,
           -- Total id's in current and previous feeds
           COUNT(CASE WHEN id IS NOT null AND prev_id IS NOT null THEN 1 END) AS ids_both_feeds,
           -- Total id's in current feed
           COUNT(CASE WHEN id IS NOT null THEN 1 END) AS ids_current_feed,
           -- Total id's in current feed
           COUNT(CASE WHEN prev_id IS NOT null THEN 1 END) AS ids_prev_feed,
           -- New id's added
           COUNT(CASE WHEN prev_id IS null THEN 1 END) AS id_added,
           -- Previous id's removed
           COUNT(CASE WHEN id IS null THEN 1 END) AS id_removed
      FROM ids_version_compare
     GROUP BY 1,2
    HAVING ids_current_feed > 0
)
{% endmacro %}

-- For use in int_gtfs_quality__persistent_ids_schedule:
{% macro max_new_id_ratio(table_name) %}
    MAX({{ table_name }}.id_added * 100 / {{ table_name }}.ids_current_feed )
       OVER (
           PARTITION BY t1.feed_key
           ORDER BY t1.date
           ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
        )
{% endmacro %}

-- For use in feed aggregator checks
-- turns both "https://website.com" and "http://website.com" into "website.com"
{% macro url_remove_scheme(url) %}
    REGEXP_REPLACE({{ url }}, "^https?://", "")
{% endmacro %}
