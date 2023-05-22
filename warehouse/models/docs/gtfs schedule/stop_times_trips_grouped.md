Columns that appear in int_gtfs_schedule__stop_times and fct_daily_scheduled_trips

--- NON-ENUM AGGREGATIONS ---

{% docs column_contains_warning_duplicate_stop_times_primary_key %}
Rows with `true` in this column indicate that the columns in this table that are aggregated from
stop times data (including `num_distinct_stops_served`, `num_stop_times`,  `trip_first_departure_ts`, `trip_last_arrival_ts`,
and `service_hours`) contain at least one row that had a duplicate primary key in the source stop times data.

I.e., at least one row being aggregated had a `trip_id` / `stop_sequence` pair that was not unique
in the input data. This indicates that data quality issues were present in the stop times data
that is being summarized here, and counts may be inflated due to multiple rows with identical identifiers.
{% enddocs %}

{% docs column_contains_warning_missing_foreign_key_stop_id %}
Rows with `true` in this column indicate that the columns in this table that are aggregated from
stop times data (including `num_distinct_stops_served`, `num_stop_times`,  `trip_first_departure_ts`, `trip_last_arrival_ts`,
and `service_hours`) contain at least one row that had a missing `stop_id` foreign key in the source stops data.

I.e., at least one row being aggregated had a `stop_id` foreign key that was missing
in the input data. This indicates that data quality issues were present in the stop times data
that is being summarized here, and the count of distinct `stop_id`s at the trip level may be incorrect.
{% enddocs %}

{% docs column_frequencies_defined_trip %}
Rows with `true` are trips defined in `frequencies.txt`, where they are defined as a
repeating trip. This means the underlying data structure is different for these trips;
see https://gtfs.org/schedule/reference/#frequenciestxt for more information.
{% enddocs %}

{% docs column_st_iteration_num %}
For frequencies-defined trips, the iteration number (starting from 0) for this trip within its
defined window. So the first iteration of the trip will have `iteration_num = 0`, and the next
trip will have `iteration_num = 1`, and so on.
{% enddocs %}

{% docs column_trip_start_timezone %}
The time zone of the first stop in this trip, from `dim_stops.stop_timezone_coalesced` with additional fallback to `feed_timezone`.
{% enddocs %}

{% docs column_trip_end_timezone %}
The time zone of the final stop in this trip, from `dim_stops.stop_timezone_coalesced` with additional fallback to `feed_timezone`.
{% enddocs %}

{% docs column_service_hours %}
A trip's total hours of service, calculated by subtracting `trip_first_departure_sec` from `trip_last_arrival_sec` and converting to hours (dividing by 3,600).
{% enddocs %}

{% docs column_flex_service_hours %}
A trip's total possible hours of flexible service, calculated by subtracting `first_start_pickup_drop_off_window_sec` from `last_end_pickup_drop_off_window_sec` and converting to hours (dividing by 3,600).
{% enddocs %}

{% docs column_num_arrival_times_populated_stop_times %}
Count of stop times on this trip where `arrival_time` is populated.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_departure_times_populated_stop_times %}
Count of stop times on this trip where `departure_time` is populated.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_is_gtfs_flex_trip %}
Boolean indicator for whether this is a flexible trip defined using GTFS-Flex.
GTFS-Flex flexible trips are indicated by using the fields `start_pickup_drop_off_window`and `end_pickup_drop_off_window` for their stop times.
This means this is not a fixed-route trip.

Note that there may be some demand-responsive behavior on trips where this column is `false`; for example, there can be stops where a phone call to the agency is required to arrange pickup/drop off, which will be indicated in pickup/drop off type columns even if they are not included as "flexible" in this column.
{% enddocs %}

{% docs column_first_start_pickup_drop_off_window_sec %}
Earliest value of `start_pickup_drop_off_window_sec` for this trip. Only populated for flexible trips.

Represents the number of seconds after 12 hours before noon (usually midnight) at which flexible pickups/drop offs begin for the earliest flexible stop on this trip.
{% enddocs %}

{% docs column_last_end_pickup_drop_off_window_sec %}
Latest value of `end_pickup_drop_off_window_sec` for this trip. Only populated for flexible trips.

Represents the number of seconds after 12 hours before noon (usually midnight) at which flexible pickups/drop offs end for final flexible stop on this trip.
{% enddocs %}

{% docs column_num_distinct_stops_served %}
Count of distinct `stop_id` values with stop times specified for this trip.
If a trip visits a given stop multiple times (for example, a loop trip that ends where it started), that stop will only be counted once here. Because this represents a count of distinct values per trip it is not
appropriate to sum across trips (because if Trip A and Trip B both visit Stop X, that stop will be
included in both their counts, so summing both trips' values will double-count Stop X.)
Note that `stop_id` here may also refer to area or location IDs for flexible trips. See https://github.com/MobilityData/gtfs-flex/blob/master/spec/reference.md for more details on the handling of `stop_id` for flexible trips.
{% enddocs %}

{% docs column_num_stop_times %}
Count of rows in `stop_times.txt` for this trip.
If a trip visits a given stop multiple times (for example, a loop trip that ends where it started),
the trip will have multiple stop times counted in this column.
Note that for flexible or demand responsive trips this column will not necessarily reflect actual trip activity, because the number of stop times is not known in advance and for flexible trips in particular a single row in `stop_times.txt` can represent activity throughout an entire service area rather than at an individual stop. See https://github.com/MobilityData/gtfs-flex/blob/master/spec/reference.md for more details on the handling of `stop_id` for flexible trips.
{% enddocs %}

{% docs column_num_gtfs_flex_stop_times %}
Count of rows in `stop_times.txt` for this trip where the fields `start_pickup_drop_off_window`and `end_pickup_drop_off_window` are populated, indicating use of the GTFS-Flex v2 specification.
{% enddocs %}

{% docs column_is_entirely_demand_responsive_trip %}
This field is experimental and may be subject to change as we improve our methods to identify
demand-responsive trips.

This column is `true` when a trip `is_gtfs_flex_trip` or if all stop times on the trip have pickup type and drop off type `2`, indicating that a phone call to the agency is required to arrange pickup/drop off at all stops.

There will be trips with some demand-responsive behavior (including deviated fixed-route) that are not captured here. This field only captures trips that indicate that they have no guaranteed fixed-route behavior and are exclusively demand-responsive.

Consider filtering these trips out of analyses that are only concerned with fixed-route activity.
{% enddocs %}

{% docs column_has_rider_service %}
A `false` in this column indicates that all stops on this trip have `pickup_type = drop_off_type = continuous_pickup_type = continuous_drop_off_type = 1`, i.e., there is no pickup or drop off behavior anywhere on this trip. These trips are presumed deadheads / non revenue service.
{% enddocs %}

--- ENUMS ---
Original field definitions provided in https://gtfs.org/reference/static#stop_timestxt
These are aggregated columns providing the counts of instances of various enum values

{% docs column_num_regularly_scheduled_pickup_stop_times %}
Count of stop times on this trip where `pickup_type` is null or 0, indicating a regularly scheduled pickups at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_no_pickup_stop_times %}
Count of stop times on this trip where `pickup_type` is 1, indicating no pickups at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_phone_call_required_for_pickup_stop_times %}
Count of stop times on this trip where `pickup_type` is 1, indicating that a phone call is required to arrange a pickup at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_coordinate_pickup_with_driver_stop_times %}
Count of stop times on this trip where `pickup_type` is 3, indicating that coordination with the driver is required to arrange a pickup at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_regularly_scheduled_drop_off_stop_times %}
Count of stop times on this trip where `drop_off_type` is null or 0, indicating a regularly scheduled drop offs at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_no_drop_off_stop_times %}
Count of stop times on this trip where `drop_off_type` is 1, indicating no drop offs at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_phone_call_required_for_drop_off_stop_times %}
Count of stop times on this trip where `drop_off_type` is 1, indicating that a phone call is required to arrange a drop off at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_coordinate_drop_off_with_driver_stop_times %}
Count of stop times on this trip where `drop_off_type` is 3, indicating that coordination with the driver is required to arrange a drop off at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_continuous_pickup_stop_times %}
Count of stop times on this trip where `continuous_pickup` is 0, indicating continuous stopping pickups between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_no_continuous_pickup_stop_times %}
Count of stop times on this trip where `continuous_pickup` is null or 1, indicating that there is no continuous stopping pickup behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_phone_call_required_for_continuous_pickup_stop_times %}
Count of stop times on this trip where `continuous_pickup` is 2, indicating that a phone call to the agency is required to arrange continuous pickup behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_coordinate_continuous_pickup_with_driver_stop_times %}
Count of stop times on this trip where `continuous_pickup` is 3, indicating that coordination with the driver is required to arrange continuous pickup behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_continuous_drop_off_stop_times %}
Count of stop times on this trip where `continuous_drop_off` is 0, indicating continuous stopping drop offs between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_no_continuous_drop_off_stop_times %}
Count of stop times on this trip where `continuous_drop_off` is null or 1, indicating that there is no continuous stopping drop off behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_phone_call_required_for_continuous_drop_off_stop_times %}
Count of stop times on this trip where `continuous_drop_off` is 2, indicating that a phone call to the agency is required to arrange continuous drop off behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_coordinate_continuous_drop_off_with_driver_stop_times %}
Count of stop times on this trip where `continuous_drop_off` is 3, indicating that coordination with the driver is required to arrange continuous drop off behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_approximate_timepoint_stop_times %}
Count of stop times on this trip where `timepoint` is 0, indicating approximate stop arrival/departure times.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_exact_timepoint_stop_times %}
Count of stop times on this trip where `timepoint` is null or 1, indicating exact stop arrival/departure times.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}
