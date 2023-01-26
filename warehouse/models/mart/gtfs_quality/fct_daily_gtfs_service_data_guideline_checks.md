{% docs fct_daily_gtfs_service_data_guideline_checks %}

Each row represents a date/guideline check/GTFS service data combination, with pass/fail
information indicating whether that feed complied with that check on that date.
Only contains checks that are performed at the GTFS service data level.


Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
| Static and RT feeds are representative of all fixed-route transit services under the transit providers’ purview | Fixed-Route Completeness | All fixed-route routes represented on the agency website are represented in the GTFS feeds. |
| Static and RT feeds are representative of all demand-responsive transit services under the transit providers’ purview | Demand-Responsive Completeness | All demand-responsive routes represented on the agency website are represented in the GTFS feeds. |
{% enddocs %}
