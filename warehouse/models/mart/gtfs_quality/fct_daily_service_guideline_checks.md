{% docs fct_daily_service_guideline_checks %}

Each row represents a date/guideline check/service combination, with pass/fail
information indicating whether that feed complied with that check on that date.
Only contains checks that are performed at the service level.

Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
| GTFS Schedule feed ingested by Google Maps and/or a combination of Apple Maps, Transit App, Bing Maps, Moovit or local Open Trip Planner services. | Compliance (Schedule) | Transit riders are able to access the trip schedule within commonly-used trip planning apps. |
| Realtime feeds ingested by Google Maps and/or a combination of Apple Maps, Transit App, Bing Maps, Moovit or local Open Trip Planner services. | Compliance (RT) | Transit riders are able to access live trip statuses within commonly-used trip planning apps. |
| 100% of scheduled trips on a given day are represented within the Trip updates feed | Fixed-Route Completeness | 100% of scheduled trips on a given day are represented within the Trip Updates feed. This includes canceled trips, which should be accounted for by either marking a trip as canceled or adjusting the estimated arrival times. |
| 100% of trips marked as “Scheduled”, “Canceled”, or “Added” within the Trip updates feed are represented within the Vehicle positions feed | Fixed-Route Completeness | 100% of trips marked as “Scheduled”, “Canceled”, or “Added” within the Trip updates feed are represented within the Vehicle positions feed. |
| A schedule feed is listed | Compliance (Schedule) | A schedule feed is listed for this service. |
| A Vehicle positions feed is listed | Compliance (RT) | A Vehicle positions feed is listed for this service. |
| A Trip updates feed is listed | Compliance (RT) | A Trip updates feed is listed for this service. |
| A Service alerts feed is listed | Compliance (RT) | A Service alerts feed is listed for this service. |
{% enddocs %}
