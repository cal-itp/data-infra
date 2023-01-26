{% docs fct_daily_gtfs_dataset_guideline_checks %}

Each row represents a date/guideline check/gtfs dataset combination, with pass/fail
information indicating whether that feed complied with that check on that date.
Only contains checks that are performed at the gtfs_dataset
level.


Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
| Shapes in shapes.txt are precise enough to show the right-of-way that the vehicle uses and not inaccurately exit the right-of-way | Accurate Service Data | All trip shapes match the right-of-way. |
| Includes an open license that allows commercial use | Compliance (Schedule) | The transit provider’s website includes an open license that allows commercial use of GTFS data. |
| GTFS RT feeds require easy (if any) authentication | Availability on Website | If an API key is required to access the any or all of the GTFS Realtime feeds, the registration process must be straightforward, quick, and transparent. |
| GTFS Schedule data is published at a stable URI (permalink) from which it can be “fetched” automatically by trip-planning applications | Compliance (Schedule) | The feed URL appears to be permanent (meaning the link is stable and does not change) for the foreseeable future. Common issues that would make a URL not permanent are that the URL has a date within it, or the URL includes a reference to a specific time of year, such as a season. |
| Passes Grading Scheme v1 | Accurate Service Data | The GTFS Schedule feed passes the manual Grading Scheme v1 process. |

{% enddocs %}
