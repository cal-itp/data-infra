Docs related to traversing the GTFS quartets (schedule columns used to populate, interpret, or validate RT tables)

{% docs gtfs_dataset_name %}
Name from the associated GTFS dataset record.  
{% enddocs %}

{% docs column_rt_schedule_dataset_key %}
The foreign key to `dim_gtfs_datasets` for the GTFS schedule dataset
record associated with this GTFS RT dataset for validation purposes.
{% enddocs %}

{% docs column_rt_schedule_dataset_name %}
Name of the GTFS schedule dataset used to validate this GTFS RT dataset.
{% enddocs %}

{% docs column_rt_schedule_feed_key %}
Foreign key to `dim_schedule_feeds` for the GTFS schedule feed associated
with the GTFS schedule dataset that is used to validate this GTFS RT data.
This is the schedule feed version that was in effect at the time the GTFS
RT data was scraped. If this is null, we did not download GTFS schedule
data associated with the dataset used to validate this GTFS RT data.
This could happen because of download failures (for example, a temporary
technical issue) or because of issues with the GTFS dataset associations
upstream.
{% enddocs %}


{% docs column_rt_schedule_base64_url %}
URL-safe base64-encoded URL of the schedule feed used to validate this 
RT feed.
{% enddocs %}

{% docs column_rt_schedule_feed_timezone %}
The `feed_timezone` of the feed referenced by `schedule_feed_key`.
This information is required to match trips from GTFS RT to their
scheduled counterparts, so that the date/time data from the RT feed can be
interpreted within the appropriate time zone to align with its schedule.
{% enddocs %}
