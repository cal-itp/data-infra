{% docs int_gtfs_quality__guideline_checks_long %}

Each row represents a date/organization/service/feed/guideline/check combination, with pass/fail
information indicating whether that entity complied with that check on that date. Entities
in this table are considered `assessed` for guidelines purposes, meaning:

* Organizations in this table have a `reporting_category` of `Core` or `Other Public Transit`
* The organization manages at least one service that is currently operating and has at least some fixed-route service
* That service is represented in at least one customer-facing GTFS dataset

This table is designed to be an exhaustive accounting of all checks performed on assessed entities which can then be further summarized (grouped) based on the specific entity of interest  (for example, services or organizations). See the `fct_daily_organization_combined_guideline_checks` and `fct_daily_service_combined_guideline_checks` tables to
get daily assessments for organizations or services; they use the aggregation logic described below.

This table should **not** be used in its raw form for counts of passing/failing checks. The grain of this table is 'every organization/service/dataset combination that was assessed on this date', which is not generally an intuitive or useful grain for analysis. Each row represents a single organization/service/dataset/feed/guideline/check combination, which means that the number of rows for one service, organization, dataset, or feed varies based on the number of relationships that entity has.

For example, a service with a trip updates feed but no vehicle positions feed may have fewer rows than a service with both types of feed. Similarly, an organization with five services (even if they are
all represented in the same GTFS dataset) will have more rows than an organization with just one service.
This makes the raw row counts or percentages in this table very difficult to interpret.

To aggregate to a given entity-level (service, organization, dataset, or feed), as this
table is intended to be used, the logic is:
* Group by date, that entity's key (for example, `organization_key`), `check`, and `feature`
* Apply `LOGICAL_OR` and `LOGICAL_AND` aggregation on the `status` column, like so:

```
-- note that the order here matters; the conditions are meant to be applied in this order
-- so that failing takes precendence
CASE
    WHEN LOGICAL_OR(NULLIF(status, "N/A") = "FAIL") THEN "FAIL"
    WHEN LOGICAL_AND(NULLIF(status, "N/A") = "PASS") THEN "PASS"
    WHEN LOGICAL_AND(NULLIF(status, "N/A") = "MANUAL CHECK NEEDED") THEN "MANUAL CHECK NEEDED"
    WHEN LOGICAL_AND(status = "N/A") THEN "N/A"
END as status
```

This will result in:
* The overall entity check will fail if any check on a constituent entity failed
* The overall entity check will pass if all constituent entity checks were either `N/A` or pass
* The overall entity check will be `MANUAL CHECK NEEDED` if all constituent entity checks were `N/A` or `MANUAL CHECK NEEDED`
* The overall entity check will be `N/A` if all constituent entity checks were `N/A`

Else it will be null.

Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
| No errors in MobilityData GTFS Schedule Validator | Compliance (Schedule) |GTFS Schedule Validator produced no errors for the transit provider’s static feed. |
| No shapes-related errors appear in the MobilityData GTFS Schedule Validator | Accurate Service Data | None of the following shapes-related errors appear in the MobilityData GTFS Schedule Validator: decreasing_shape_distance, equal_shape_distance_diff_coordinates, decreasing_or_equal_shape_distance, decreasing_or_equal_shape_distance. |
| Feed will be valid for more than 7 days | Best Practices Alignment (Schedule) | The MobilityData GTFS Validator warning, feed_expiration_date_7_days, does not appear for the given day. The warning description reads: "Dataset should be valid for at least the next 7 days." |
| Feed will be valid for more than 30 days | Best Practices Alignment (Schedule) | The MobilityData GTFS Validator warning, feed_expiration_date_30_days, does not appear for the given day. The warning description reads: "Dataset should cover at least the next 30 days of service." |
| Shapes.txt file is present | Accurate Service Data | Static GTFS feed contains the file shapes.txt.|
| Every trip in trips.txt has a shape_id listed | Accurate Service Data | Every trip in trips.txt has a shape_id listed. |
| Technical contact is listed in feed_contact_email field within the feed_info.txt file | Technical Contact Availability | The feed_contact_email field in feed_info.txt contains a non-empty value. |
| Include tts_stop_name entries in stops.txt for stop names that are pronounced incorrectly in most mobile applications. | Accurate Accessibility Data | For every stop_name in stops.txt containing text that is commonly mispronounced in trip planning applications, there is a non-null tts_stop_name field which is not identical to the stop_name field. The commonly mispronounced text includes directional abbreviations ("n","s","e","w","ne","se","sw","nw","nb","sb","eb","wb"), right-of-way names ("st","rd","blvd","hwy"), two or more adjacent numerals, and the symbols "/", "(" and ")". |
| Includes complete wheelchair accessibility data in both stops.txt and trips.txt | Accurate Accessibility Data | Trips.txt contains non-empty and non-zero values for each trip in the wheelchair_accessible column, and stops.txt contains non-empty and non-zero values for each stop in the wheelchair_boarding column. |
| Includes wheelchair_accessible in trips.txt | Accurate Accessibility Data | Trips.txt contains non-empty and non-zero values for each trip in the wheelchair_accessible column. |
| Includes wheelchair_boarding in stops.txt | Accurate Accessibility Data | Stops.txt contains non-empty and non-zero values for each stop in the wheelchair_boarding column. |
| No pathways-related errors appear in the MobilityData GTFS Validator | Accurate Accessibility Data| A transit provider is eligible for this check if they have at least one stop listed in stops.txt that: 1) Has "station" or "transit center" in the name, 2) Serves rail, or 3) Has a parent_station listed. For transit providers eligible for this check, they will pass if none of the following pathways-related notices appear in the GTFS Schedule Validator: pathway_to_platform_with_boarding_areas, pathway_to_wrong_location_type, pathway_unreachable_location, missing_level_id, station_with_parent_station, wrong_parent_location_type. |
| Passes Fares v2 portion of MobilityData GTFS Schedule Validator | Fare Completeness | For feeds containing at least one of the files: fare_leg_rules, rider_categories, fare_containers, fare_products, fare_transfer_rules, none of the following errors appear in the MobilityData GTFS Schedule Validator: fare_transfer_rule_duration_limit_type_without_duration_limit, fare_transfer_rule_duration_limit_without_type, fare_transfer_rule_invalid_transfer_count, fare_transfer_rule_missing_transfer_count, fare_transfer_rule_with_forbidden_transfer_count, invalid_currency_amount. |
| No expired services are listed in the feed | Best Practices Alignment (Schedule) | No service_id's exist in calendars.txt or calendar_dates.txt where the last in-effect date is in the past. |
| All schedule changes in the last month have provided at least 7 days of lead time | Up-to-Dateness | All changes made in the last 30 days to stops.txt, stop_times.txt, calendar.txt, and calendar_dates.txt did not impact trips within seven days of when the update was made. |
| Schedule feed maintains persistent identifiers for stop_id, route_id, and agency_id | Best Practices Alignment (Schedule)| In the last 30 days, no updates to the schedule feed have created a situation where 50% or more of a given ID (stop_id, route_id, agency_id) were not present in the previous feed version. |
| The GTFS Schedule API endpoint is configured to report the file modification date | Best Practices Alignment (Schedule) | When the GTFS Schedule API endpoint is requested, the response header includes a field called "Last-Modified". |
| Schedule feed is listed on feed aggregator transit.land | Feed Aggregator Availability (Schedule) | Schedule feed is present on the feed aggregator transit.land. |
| Schedule feed is listed on feed aggregator Mobility Database | Feed Aggregator Availability (Schedule) | Schedule feed is present on the feed aggregator Mobility Database. |
| Schedule feed downloads successfully | Compliance (Schedule) | On the given date, the schedule feed was downloaded and parsed successfully |
|Vehicle positions feed produces no errors in the MobilityData GTFS Realtime Validator | Compliance (RT) | The Vehicle positions feed has at least one GTFS-RT file present on the given day, and GTFS Realtime Validator produced no errors for that feed on that day. |
|Trip updates feed produces no errors in the MobilityData GTFS Realtime Validator | Compliance (RT) | The Trip updates feed has at least one GTFS-RT file present on the given day, and GTFS Realtime Validator produced no errors for that feed on that day. |
|Service alerts feed produces no errors in the MobilityData GTFS Realtime Validator | Compliance (RT) | The Service alerts feed has at least one GTFS-RT file present on the given day, and GTFS Realtime Validator produced no errors for that feed on that day. |
| All trip_ids provided in the GTFS-rt feed exist in the GTFS Schedule feed| Fixed-Route Completeness | Error code E003 does not appear in the MobilityData GTFS Realtime Validator on that day.|
| Vehicle positions RT feed is present | Compliance (RT) | The vehicle positions RT feed contains at least one file on the given day.|
| Trip updates RT feed is present | Compliance (RT) | The trip updates RT feed contains at least one file on the given day.|
| Service alerts RT feed is present | Compliance (RT) | The service alerts RT feed contains at least one file on the given day.|
| Service alerts RT feed uses HTTPS | Best Practice Alignment (RT) | The service alerts RT feed endpoint uses HTTPS instead of HTTPS to ensure feed integrity.|
| Vehicle positions RT feed uses HTTPS | Best Practice Alignment (RT) | The vehicle positions RT feed endpoint uses HTTPS instead of HTTPS to ensure feed integrity.|
| Trip updates RT feed uses HTTPS | Best Practice Alignment (RT) | The trip updates RT feed endpoint uses HTTPS instead of HTTPS to ensure feed integrity.|
| Fewer than 1% of requests to Trip updates RT feed result in a protobuf error | Best Practice Alignment (RT) | On the given day, fewer than 1% of Trip updates RT feed downloads result in a protobuf error.|
| Fewer than 1% of requests to Service alerts RT feed result in a protobuf error | Best Practice Alignment (RT) | On the given day, fewer than 1% of Service alerts RT feed downloads result in a protobuf error.|
| Fewer than 1% of requests to Vehicle positions RT feed result in a protobuf error | Best Practice Alignment (RT) | On the given day, fewer than 1% of Vehicle positions RT feed downloads result in a protobuf error.|
| Vehicle positions RT feed contains no updates older than 90 seconds. | Best Practices Alignment (RT) | At no point during the day is there a Vehicle positions file that is older than 90 seconds. |
| Trip updates RT feed contains no updates older than 90 seconds. | Best Practices Alignment (RT) | At no point during the day is there a Trip updates file that is older than 90 seconds. |
| Service alerts RT feed contains no updates older than 10 minutes. | Best Practices Alignment (RT) | At no point during the day is there a Service alerts file that is older than 10 minutes. |
| Vehicle positions RT feed is listed on feed aggregator transit.land | Feed Aggregator Availability (RT) | Vehicle positions RT feed is present on the feed aggregator transit.land. |
| Trip updates RT feed is listed on feed aggregator transit.land | Feed Aggregator Availability (RT) | Trip updates RT feed is present on the feed aggregator transit.land. |
| Service alerts RT feed is listed on feed aggregator transit.land | Feed Aggregator Availability (RT) | Service alerts RT feed is present on the feed aggregator transit.land. |
| Vehicle positions RT feed is listed on feed aggregator Mobility Database | Feed Aggregator Availability (RT) | Vehicle positions RT feed is present on the feed aggregator Mobility Database. |
| Trip updates RT feed is listed on feed aggregator Mobility Database | Feed Aggregator Availability (RT) | Trip updates RT feed is present on the feed aggregator Mobility Database. |
| Service alerts RT feed is listed on feed aggregator Mobility Database | Feed Aggregator Availability (RT) | Service alerts RT feed is present on the feed aggregator Mobility Database. |
| The Service alerts API endpoint is configured to report the file modification date | Best Practices Alignment (RT) | When the Service alerts API endpoint is requested, the response header includes a field called "Last-Modified". |
| The Vehicle positions API endpoint is configured to report the file modification date | Best Practices Alignment (RT) | When the Vehicle Positions API endpoint is requested, the response header includes a field called "Last-Modified". |
| The Trip updates API endpoint is configured to report the file modification date | Best Practices Alignment (RT) | When the Trip updates API endpoint is requested, the response header includes a field called "Last-Modified". |
| A technical contact email address is listed on the organization website | Technical Contact Availability | A designated contact is listed on the organization website, to be reached out to for GTFS-related questions. |
| Shapes in shapes.txt are precise enough to show the right-of-way that the vehicle uses and not inaccurately exit the right-of-way | Accurate Service Data | All trip shapes match the right-of-way. |
| Includes an open license that allows commercial use of GTFS Schedule feed| Compliance (Schedule) | The transit provider’s website includes an open license that allows commercial use of GTFS Schedule feed. |
| Includes an open license that allows commercial use of Vehicle positions feed| Compliance (RT) | The transit provider’s website includes an open license that allows commercial use of Vehicle positions feed. |
| Includes an open license that allows commercial use of Trip updates feed| Compliance (RT) | The transit provider’s website includes an open license that allows commercial use of Trip updates feed. |
| Includes an open license that allows commercial use of Service alerts feed| Compliance (RT) | The transit provider’s website includes an open license that allows commercial use of Service alerts feed. |
| GTFS Schedule feed requires easy (if any) authentication | Availability on Website | If an API key is required to access the GTFS Schedule feed, the registration process must be straightforward, quick, and transparent. |
| Vehicle positions feed requires easy (if any) authentication | Availability on Website | If an API key is required to access the Vehicle positions feed, the registration process must be straightforward, quick, and transparent. |
| Trip updates feed requires easy (if any) authentication | Availability on Website | If an API key is required to access the Trip updates feed, the registration process must be straightforward, quick, and transparent. |
| Service alerts feed requires easy (if any) authentication | Availability on Website | If an API key is required to access the Service alerts feed, the registration process must be straightforward, quick, and transparent. |
| GTFS Schedule feed is published at a stable URI (permalink) from which it can be “fetched” automatically by trip-planning applications | Compliance (Schedule) | The GTFS Schedule URL appears to be permanent (meaning the link is stable and does not change) for the foreseeable future. Common issues that would make a URL not permanent are that the URL has a date within it, or the URL includes a reference to a specific time of year, such as a season. |
| Vehicle positions feed is published at a stable URI (permalink) from which it can be “fetched” automatically by trip-planning applications | Compliance (RT) | The Vehicle positions URL appears to be permanent (meaning the link is stable and does not change) for the foreseeable future. Common issues that would make a URL not permanent are that the URL has a date within it, or the URL includes a reference to a specific time of year, such as a season. |
| Trip updates feed is published at a stable URI (permalink) from which it can be “fetched” automatically by trip-planning applications | Compliance (RT) | The Trip updates URL appears to be permanent (meaning the link is stable and does not change) for the foreseeable future. Common issues that would make a URL not permanent are that the URL has a date within it, or the URL includes a reference to a specific time of year, such as a season. |
| Service alerts feed is published at a stable URI (permalink) from which it can be “fetched” automatically by trip-planning applications | Compliance (RT) | The Service alerts URL appears to be permanent (meaning the link is stable and does not change) for the foreseeable future. Common issues that would make a URL not permanent are that the URL has a date within it, or the URL includes a reference to a specific time of year, such as a season. |
| Passes Grading Scheme v1 | Accurate Service Data | The GTFS Schedule feed passes the manual Grading Scheme v1 process. |
| GTFS Schedule link is posted on website | Availability on Website | If an API key is required to access the GTFS Schedule feed, the registration process must be straightforward, quick, and transparent. |
| Vehicle positions link link is posted on website | Availability on Website | If an API key is required to access the Vehicle positions feed, the registration process must be straightforward, quick, and transparent. |
| Trip updates link is posted on website | Availability on Website | If an API key is required to access the Trip updates feed, the registration process must be straightforward, quick, and transparent. |
| Service alerts link is posted on website | Availability on Website | If an API key is required to access the Service alerts feed, the registration process must be straightforward, quick, and transparent. |
| GTFS Schedule feed ingested by Google Maps and/or a combination of Apple Maps, Transit App, Bing Maps, Moovit or local Open Trip Planner services. | Compliance (Schedule) | Transit riders are able to access the trip schedule within commonly-used trip planning apps. |
| Realtime feeds ingested by Google Maps and/or a combination of Apple Maps, Transit App, Bing Maps, Moovit or local Open Trip Planner services. | Compliance (RT) | Transit riders are able to access live trip statuses within commonly-used trip planning apps. |
| Static and RT feeds are representative of all fixed-route transit services under the transit providers’ purview | Fixed-Route Completeness | All fixed-route routes represented on the agency website are represented in the GTFS feeds. |
| Static and RT feeds are representative of all demand-responsive transit services under the transit providers’ purview | Demand-Responsive Completeness | All demand-responsive routes represented on the agency website are represented in the GTFS feeds. |
| 100% of scheduled trips on a given day are represented within the Trip updates feed | Fixed-Route Completeness | 100% of scheduled trips on a given day are represented within the Trip Updates feed. This includes canceled trips, which should be accounted for by either marking a trip as canceled or adjusting the estimated arrival times. |
| 100% of trips marked as “Scheduled”, “Canceled”, or “Added” within the Trip updates feed are represented within the Vehicle positions feed | Fixed-Route Completeness | 100% of trips marked as “Scheduled”, “Canceled”, or “Added” within the Trip updates feed are represented within the Vehicle positions feed. |
| A schedule feed is listed | Compliance (Schedule) | A schedule feed is listed for this service. |
| A Vehicle positions feed is listed | Compliance (RT) | A Vehicle positions feed is listed for this service. |
| A Trip updates feed is listed | Compliance (RT) | A Trip updates feed is listed for this service. |
| A Service alerts feed is listed | Compliance (RT) | A Service alerts feed is listed for this service. |
{% enddocs %}
