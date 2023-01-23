{% docs fct_daily_service_guideline_checks %}

Each row represents a date/guideline check/service combination, with pass/fail
information indicating whether that feed complied with that check on that date.
A row will exist for every check, for every row from the index which is driven
by int_gtfs_quality__daily_assessment_candidate_services. Only contains checks that are performed at the sersvice
level.

Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
| 100% of trips marked as “Scheduled”, “Canceled”, or “Added” within the Trip updates feed are represented within the Vehicle positions feed | Fixed-Route Completeness | 100% of trips marked as “Scheduled”, “Canceled”, or “Added” within the Trip updates feed are represented within the Vehicle positions feed. |

{% enddocs %}
