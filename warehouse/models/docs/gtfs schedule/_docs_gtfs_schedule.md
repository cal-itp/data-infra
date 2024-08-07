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
     
