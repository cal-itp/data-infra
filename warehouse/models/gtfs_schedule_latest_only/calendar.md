
{% docs gtfs_calendar__service_id %}
Uniquely identifies a set of dates when service is available for one or more routes. Each service_id value can appear at most once in a calendar.txt file.
{% enddocs %}

{% docs gtfs_calendar__monday %}
Indicates whether the service operates on all Mondays in the date range specified by the start_date and end_date fields. Note that exceptions for particular dates may be listed in calendar_dates.txt. Valid options are:

1 - Service is available for all Mondays in the date range.
0 - Service is not available for Mondays in the date range.
{% enddocs %}

{% docs gtfs_calendar__tuesday %}
Functions in the same way as monday except applies to Tuesdays
{% enddocs %}

{% docs gtfs_calendar__wednesday %}
Functions in the same way as monday except applies to Wednesdays
{% enddocs %}

{% docs gtfs_calendar__thursday %}
Functions in the same way as monday except applies to Thursdays
{% enddocs %}

{% docs gtfs_calendar__friday %}
Functions in the same way as monday except applies to Fridays
{% enddocs %}

{% docs gtfs_calendar__saturday %}
Functions in the same way as monday except applies to Saturdays.
{% enddocs %}

{% docs gtfs_calendar__sunday %}
Functions in the same way as monday except applies to Sundays.
{% enddocs %}

{% docs gtfs_calendar__start_date %}
Start service day for the service interval.
{% enddocs %}

{% docs gtfs_calendar__end_date %}
End service day for the service interval. This service day is included in the interval.
{% enddocs %}
