Docs macros that apply to GTFS schedule data only

{% docs gtfs_schedule_feed_timezone %}
Timezone value for this feed (most common `agency_timestamp` value from `agency.txt`).
This will be a string value that can be passed to the TIMESTAMP function as a valid
timezone, for example 'America/Los_Angeles' or 'US/Pacific'.
{% enddocs %}


{% docs gtfs_schedule_stop_timezone_coalesced %}
This field applies the fallback logic specified by https://gtfs.org/schedule/reference/#stopstxt to have a guaranteed non-null time zone for this stop. The logic is:
* If there is a parent stop with stop_timezone, use that.
* Otherwise if there is a stop_timezone for this stop, use that (technically per the spec if there is a parent stop with null timezone and the child stop_timezone is populated, it is not clear what is supposed to happen. In that case this field would just use the child stop's timezone.)
* Finally, fall back to `agency_timezone` from `agency.txt`, which here is available as `feed_timezone`.
{% enddocs %}


{% docs gtfs_schedule_feed_key %}
Foreign key to the `dim_schedule_feeds` table.
{% enddocs %}


{% docs gtfs_schedule_gtfs_dataset_key %}
Foreign key to the associated GTFS dataset record.
Because GTFS data was downloaded in the v1 pipeline before
`gtfs dataset` records were being archived in the warehouse,
it is possible for GTFS data to be associated with a GTFS dataset
record that was not yet in effect at the time the data was downloaded.
(So, you may see GTFS data from January 2022 associated with a GTFS dataset
record that does not take effect until July 2022.)
This is done for convenience to facilitate labeling of older data (the alternative
would be failing to join and making it essentially impossible to label
historical GTFS data with their associated transit database records).
{% enddocs %}


{% docs gtfs_schedule_route_type_0 %}
The count of stop events associated with route_type 0 - Tram, Streetcar, Light rail.
{% enddocs %}


{% docs gtfs_schedule_route_type_1 %}
The count of stop events associated with route_type 1 - Subway, Metro.
{% enddocs %}


{% docs gtfs_schedule_route_type_2 %}
The count of stop events associated with route_type 2 - Rail.
{% enddocs %}


{% docs gtfs_schedule_route_type_3 %}
The count of stop events associated with route_type 3 - Bus.
{% enddocs %}


{% docs gtfs_schedule_route_type_4 %}
The count of stop events associated with route_type 4 - Ferry.
{% enddocs %}


{% docs gtfs_schedule_route_type_5 %}
The count of stop events associated with route_type 5 - Cable Tram.
{% enddocs %}


{% docs gtfs_schedule_route_type_6 %}
The count of stop events associated with route_type 6 - Aerial lift,
suspended cable car (e.g., gondola lift, aerial tramway).
{% enddocs %}


{% docs gtfs_schedule_route_type_7 %}
The count of stop events associated with route_type 7 - Cable Tram.
{% enddocs %}


{% docs gtfs_schedule_route_type_11 %}
The count of stop events associated with route_type 11 - Trolleybus.
{% enddocs %}


{% docs gtfs_schedule_route_type_12 %}
The count of stop events associated with route_type 12 - Monorail.
{% enddocs %}


{% docs gtfs_schedule_missing_route_type %}
The count of stop events associated with a `stop_id` that had a null `route_type` value in `dim_routes`.
{% enddocs %}
