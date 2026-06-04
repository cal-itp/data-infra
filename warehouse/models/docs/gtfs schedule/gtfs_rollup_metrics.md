--- These columns are derived from combining multiple GTFS tables ---
--- Multiple schedule (trips + stop_times + stops) or ---
--- schedule + RT (scheduled trips + observed_trips) ---

{% docs column_gtfs_route_name %}
Parsed and standardized combined form of `route_id`, `route_short_name`, and `route_long_name`.
This column is used to describe a route entity with time-series data.

Ex 1 same route, different route_ids, due to feed versioning by transit operator: 
- LA Metro Route 150
- route_id: 150-13188 (on 2025-12-01) and 150-13196 (on 2026-02-01)
- route_short_name: 150 (both dates)
- route_long_name: Metro Local Line (both dates) 
- route_name for time-series labeling: `150__150 Metro Local Line` with the 
pattern `[parsed_route_id]__[route_short_name] [route_long_name]`

Ex 2 route_short_name and route_long_name provide duplicate labeling:
- Antelope Valley Transit Authority Route 5
- route_id: 5
- route_short_name: 5
- route_long_name: Route 5
- route_name for time-series labeling: `5__Route 5` with the 
pattern `[parsed_route_id]__[route_long_name]`

See the macro: https://dbt-docs.dds.dot.ca.gov/#!/macro/macro.calitp_warehouse.get_combined_route_name
{% enddocs %}


{% docs column_daily_stop_arrivals %}

Scheduled stop arrivals are scheduled stop times. See `num_stop_times`.
The count of stop arrivals, the count of scheduled stop arrivals, per day.
For longer periods, it is the total stop arrivals / n_service_dates for the period.

{% enddocs %}

{% docs column_stop_arrivals_per_hour %}

Number of arrivals per hour (total stop arrivals / n_hours) for each time-of-day in 
`owl`, `early_am`, `am_peak`, `midday`, `pm_peak`, `evening`, `peak`, `offpeak`

This normalized metric provides a useful comparison across time-of-day values.
* early_am, am_peak: 3 hours
* owl, evening: 4 hours
* midday, pm_peak: 5 hours
* peak = 8 hours
* offpeak = 16 hours

See macro: https://dbt-docs.dds.dot.ca.gov/#!/macro/macro.calitp_warehouse.generate_time_of_day_hours 

{% enddocs %}


{% docs column_stop_arrivals_by_time_of_day %}

Total arrivals during the time-of-day.

In a 24 hour period:
* hours 0-3: owl
* hours 4-6: early_am
* hours 7-9: am_peak
* hours 10-14: midday
* hours 15-19: pm_peak
* hours 20-23: evening
* peak = am_peak + pm_peak 
* offpeak = owl + early_am + midday + evening
* all_day: 24 hours

See macro: https://dbt-docs.dds.dot.ca.gov/#!/macro/macro.calitp_warehouse.generate_time_of_day_column     
{% enddocs %}


{% docs column_daily_trips_by_time_of_day %}

Daily trips by for each time-of-day in 
`owl`, `early_am`, `am_peak`, `midday`, `pm_peak`, `evening`, `peak`, `offpeak`

For daily tables, it is number of trips on that service_date.
For monthly tables, it is the average daily number of trips calculated over the service_dates in that month.

{% enddocs %}


{% docs column_frequency_trips_per_hour %}

Number of trips per hour (n_trips / n_hours) by for each time-of-day in 
`owl`, `early_am`, `am_peak`, `midday`, `pm_peak`, `evening`, `peak`, `offpeak`

This normalized metric provides a useful comparison across time-of-day values.
* early_am, am_peak: 3 hours
* owl, evening: 4 hours
* midday, pm_peak: 5 hours
* peak = 8 hours
* offpeak = 16 hours

{% enddocs %}


{% docs column_n_tu_trips %}

Count of distinct trip_instance_keys from the trip updates dataset.

pct_tu_trips is the percent of scheduled trips with trip updates.
pct_tu_trips = n_tu_trips / n_scheduled_trips

daily_tu_trips is the average daily number of trips with trip updates over this 
period (up to a month).
daily_tu_trips = n_tu_trips / n_service_dates.

{% enddocs %}


{% docs column_n_vp_trips %}

Count of distinct trip_instance_keys from the vehicle positions dataset.

pct_vp_trips is the percent of scheduled trips with vehicle positions.
pct_vp_trips = n_vp_trips / n_scheduled_trips

daily_vp_trips is the average daily number of trips with vehicle positions over this 
period (up to a month).
daily_vp_trips = n_vp_trips / n_service_dates.

{% enddocs %}


{% docs column_rt_messages_per_minute %}

The `num_distinct_updates` number of distinct updates is the 
count of how many messages per minute this entity was present for,
which can help give a sense for how continuously this entity was updated.
This number should be equal to `num_distinct_message_keys`.

If you divide this value by `extract_duration_minutes`, you would get a count of 
how many messages per minute this entity was present for, which can help give a 
sense for how continuously this entity was updated.

See `num_distinct_extract_ts` and `num_distinct_message_keys`.
{% enddocs %}
