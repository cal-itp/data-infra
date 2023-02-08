{% docs fct_daily_gtfs_dataset_guideline_checks %}

Each row represents a date/guideline check/gtfs dataset combination, with pass/fail information indicating whether that feed complied with that check on that date. Only contains checks that are performed at the gtfs_dataset level. Some checks apply to all 4 feed types, while some apply only to the schedule feed.


Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
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


{% enddocs %}
