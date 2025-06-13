--
-- ENTITIES
--
{% macro schedule_feed() %}
'schedule_feed'
{% endmacro %}

{% macro schedule_url() %}
'schedule_url'
{% endmacro %}

{% macro rt_feed() %}
'rt_feed'
{% endmacro %}

{% macro rt_feed_vp() %}
'rt_feed_vp'
{% endmacro %}

{% macro rt_feed_tu() %}
'rt_feed_tu'
{% endmacro %}

{% macro rt_feed_sa() %}
'rt_feed_sa'
{% endmacro %}

{% macro rt_url_vp() %}
'rt_url_vp'
{% endmacro %}

{% macro rt_url_tu() %}
'rt_url_tu'
{% endmacro %}

{% macro rt_url_sa() %}
'rt_url_sa'
{% endmacro %}

{% macro organization() %}
'organization'
{% endmacro %}

{% macro service() -%}
'service'
{% endmacro %}

{% macro gtfs_service_data_schedule() -%}
'gtfs_service_data_schedule'
{% endmacro %}

{% macro gtfs_dataset_schedule() -%}
'gtfs_dataset_schedule'
{% endmacro %}

{% macro gtfs_dataset_vp() -%}
'gtfs_dataset_vp'
{% endmacro %}

{% macro gtfs_dataset_tu() -%}
'gtfs_dataset_tu'
{% endmacro %}

{% macro gtfs_dataset_sa() -%}
'gtfs_dataset_sa'
{% endmacro %}

--
-- CHECK NAMES
--
{% macro static_feed_downloaded_successfully() %}
"GTFS schedule feed downloads successfully"
{% endmacro %}

{% macro no_validation_errors() %}
"No errors in MobilityData GTFS Schedule Validator"
{% endmacro %}

{% macro complete_wheelchair_accessibility_data() %}
"Includes complete wheelchair accessibility data in both stops.txt and trips.txt"
{% endmacro %}

{% macro wheelchair_accessible_trips() %}
"Includes wheelchair_accessible in trips.txt"
{% endmacro %}

{% macro wheelchair_boarding_stops() %}
"Includes wheelchair_boarding in stops.txt"
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
"Feed has feed_info.txt file and technical contact is listed in feed_contact_email field within the feed_info.txt file"
{% endmacro %}

{% macro no_rt_validation_errors_vp() %}
"The Vehicle positions feed produces no errors in the MobilityData GTFS Realtime Validator"
{% endmacro %}

{% macro no_rt_validation_errors_tu() %}
"The Trip updates feed produces no errors in the MobilityData GTFS Realtime Validator"
{% endmacro %}

{% macro no_rt_validation_errors_sa() %}
"The Service alerts feed produces no errors in the MobilityData GTFS Realtime Validator"
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
"Feed has pathways.txt file and no pathways-related errors appear in the MobilityData GTFS Schedule Validator"
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

{% macro rt_20sec_vp() %}
"Vehicle Positions feed contains updates at least once every 20 seconds"
{% endmacro %}

{% macro rt_20sec_tu() %}
"Trip Updates feed contains updates at least once every 20 seconds"
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

{% macro modification_date_present_service_alerts() %}
"The Service alerts API endpoint is configured to report the file modification date"
{% endmacro %}

{% macro modification_date_present_vehicle_positions() %}
"The Vehicle positions API endpoint is configured to report the file modification date"
{% endmacro %}

{% macro modification_date_present_trip_updates() %}
"The Trip updates API endpoint is configured to report the file modification date"
{% endmacro %}

{% macro organization_has_contact_info() %}
"A technical contact email address is listed on the organization website"
{% endmacro %}

{% macro shapes_accurate() %}
"Shapes in shapes.txt are precise enough to show the right-of-way that the vehicle uses and not inaccurately exit the right-of-way"
{% endmacro %}

{% macro data_license_schedule() %}
"Includes an open license that allows commercial use of GTFS Schedule feed"
{% endmacro %}

{% macro data_license_vp() %}
"Includes an open license that allows commercial use of Vehicle positions feed"
{% endmacro %}

{% macro data_license_tu() %}
"Includes an open license that allows commercial use of Trip updates feed"
{% endmacro %}

{% macro data_license_sa() %}
"Includes an open license that allows commercial use of Service alerts feed"
{% endmacro %}

{% macro authentication_acceptable_schedule() %}
"GTFS Schedule feed requires easy (if any) authentication"
{% endmacro %}

{% macro authentication_acceptable_vp() %}
"Vehicle positions feed requires easy (if any) authentication"
{% endmacro %}

{% macro authentication_acceptable_tu() %}
"Trip updates feed requires easy (if any) authentication"
{% endmacro %}

{% macro authentication_acceptable_sa() %}
"Service alerts feed requires easy (if any) authentication"
{% endmacro %}

{% macro stable_url_schedule() %}
"GTFS Schedule feed is published at a stable URI (permalink) from which it can be “fetched” automatically by trip-planning applications"
{% endmacro %}

{% macro stable_url_vp() %}
"Vehicle positions feed is published at a stable URI (permalink) from which it can be “fetched” automatically by trip-planning applications"
{% endmacro %}

{% macro stable_url_tu() %}
"Trip updates feed is published at a stable URI (permalink) from which it can be “fetched” automatically by trip-planning applications"
{% endmacro %}

{% macro stable_url_sa() %}
"Service alerts feed is published at a stable URI (permalink) from which it can be “fetched” automatically by trip-planning applications"
{% endmacro %}

{% macro grading_scheme_v1() %}
"Passes Grading Scheme v1"
{% endmacro %}

{% macro link_to_dataset_on_website_schedule() %}
"GTFS Schedule link is posted on website"
{% endmacro %}

{% macro link_to_dataset_on_website_vp() %}
"Vehicle positions link is posted on website"
{% endmacro %}

{% macro link_to_dataset_on_website_tu() %}
"Trip updates link is posted on website"
{% endmacro %}

{% macro link_to_dataset_on_website_sa() %}
"Service alerts link is posted on website"
{% endmacro %}

{% macro trip_planner_schedule() %}
"GTFS Schedule feed ingested by Google Maps and/or a combination of Apple Maps, Transit App, Bing Maps, Moovit or local Open Trip Planner services"
{% endmacro %}

{% macro trip_planner_rt() %}
"Realtime feeds ingested by Google Maps and/or a combination of Apple Maps, Transit App, Bing Maps, Moovit or local Open Trip Planner services"
{% endmacro %}

{% macro fixed_routes_match() %}
"Static feeds are representative of all fixed-route transit services under the transit providers’ purview"
{% endmacro %}

{% macro demand_responsive_routes_match() %}
"Static feeds are representative of all demand-responsive transit services under the transit providers’ purview"
{% endmacro %}

{% macro scheduled_trips_in_tu_feed() %}
"100% of scheduled trips on a given day are represented within the Trip updates feed"
{% endmacro %}

{% macro all_tu_in_vp() %}
"100% of trips marked as Scheduled, Canceled, or Added within the Trip updates feed are represented within the Vehicle positions feed"
{% endmacro %}

{% macro feed_listed_schedule() %}
"A GTFS Schedule feed is listed"
{% endmacro %}

{% macro feed_listed_vp() %}
"A Vehicle positions feed is listed"
{% endmacro %}

{% macro feed_listed_tu() %}
"A Trip updates feed is listed"
{% endmacro %}

{% macro feed_listed_sa() %}
"A Service alerts feed is listed"
{% endmacro %}

--
-- FEATURE NAMES
--

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

{% macro demand_responsive_completeness() %}
"Demand-Responsive Completeness"
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

{% macro availability_on_website() %}
"Availability on Website"
{% endmacro %}

--
-- QUERIES
--
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

--
-- TESTS
--

{% test extreme_results(model) %}
{{ config(severity = 'warn') }}

    SELECT * FROM
    (
        SELECT
            date,
            COUNT(CASE WHEN status = 'PASS' THEN 1 END) * 100.0 / COUNT(*) AS percent_pass
        FROM {{ model }}
       WHERE date > CURRENT_DATE - 30
       GROUP BY 1
    )
    WHERE percent_pass = 100 OR percent_pass = 0

{% endtest %}


--
-- CHECK STATUSES
--
{% macro guidelines_manual_check_needed_status() %}
"MANUAL CHECK NEEDED"
{% endmacro %}

{% macro guidelines_na_check_status() %}
"N/A - CHECK-SPECIFIC LOGIC"
{% endmacro %}

{% macro guidelines_na_too_early_status() %}
"N/A - BEFORE CHECK ASSESSED"
{% endmacro %}

{% macro guidelines_na_entity_status() %}
"N/A - NO APPLICABLE ENTITY"
{% endmacro %}

{% macro guidelines_pass_status() %}
"PASS"
{% endmacro %}

{% macro guidelines_fail_status() %}
"FAIL"
{% endmacro %}

{% macro guidelines_to_be_assessed_status() %}
"TO BE ASSESSED"
{% endmacro %}

{% macro guidelines_reports_general_na_status() %}
"NOT APPLICABLE/DATA UNAVAILABLE"
{% endmacro %}


{% macro guidelines_aggregation_logic() %}
CASE
    -- order of evaluation matters here!
    -- fail trumps everything
    WHEN LOGICAL_OR(status = {{ guidelines_fail_status() }}) THEN {{ guidelines_fail_status() }}
    -- if at least one check is manual check needed, then manual check needed
    WHEN LOGICAL_OR(status = {{ guidelines_manual_check_needed_status() }}) THEN {{ guidelines_manual_check_needed_status() }}
    -- if at least one check passes and the rest are NA; or null, then let it pass
    WHEN LOGICAL_OR(status = {{ guidelines_pass_status() }}) THEN {{ guidelines_pass_status() }}
    -- if at least one check is NA because of specific check logic and the rest are NA too early, NA-no entity, or null, then use NA-specific check
    WHEN LOGICAL_OR(status = {{ guidelines_na_check_status() }}) THEN {{ guidelines_na_check_status() }}
    -- if at least one check is NA because too early and the rest are NA-no entity or null then use NA-specific check
    WHEN LOGICAL_OR(status = {{ guidelines_na_too_early_status() }}) THEN {{ guidelines_na_too_early_status() }}
    -- if all remaining checks are NA because no entity and the rest are null, then use NA no entity
    -- note that this one is AND because we want to confirm that this is all that's left at this point
    WHEN LOGICAL_AND(status = {{ guidelines_na_entity_status() }}) THEN {{ guidelines_na_entity_status() }}
END
{% endmacro %}

-- Logic (and comments) is recycled from guidelines_aggregation_logic() macro,
-- but all NA values are replaced with the "general NA" value used for the reports site
{% macro guidelines_aggregation_logic_reports() %}
CASE
    -- order of evaluation matters here!
    -- fail trumps everything
    WHEN LOGICAL_OR(status = {{ guidelines_fail_status() }}) THEN {{ guidelines_fail_status() }}
    -- if at least one check is manual check needed, then manual check needed
    WHEN LOGICAL_OR(status = {{ guidelines_manual_check_needed_status() }}) THEN {{ guidelines_reports_general_na_status() }}
    -- if at least one check passes and the rest are NA; or null, then let it pass
    WHEN LOGICAL_OR(status = {{ guidelines_pass_status() }}) THEN {{ guidelines_pass_status() }}
    -- if at least one check is NA because of specific check logic and the rest are NA too early, NA-no entity, or null, then use NA-specific check
    WHEN LOGICAL_OR(status = {{ guidelines_na_check_status() }}) THEN {{ guidelines_reports_general_na_status() }}
    -- if at least one check is NA because too early and the rest are NA-no entity or null then use NA-specific check
    WHEN LOGICAL_OR(status = {{ guidelines_na_too_early_status() }}) THEN {{ guidelines_reports_general_na_status() }}
    -- if all remaining checks are NA because no entity and the rest are null, then use NA no entity
    -- note that this one is AND because we want to confirm that this is all that's left at this point
    WHEN LOGICAL_AND(status = {{ guidelines_na_entity_status() }}) THEN {{ guidelines_reports_general_na_status() }}
END
{% endmacro %}
