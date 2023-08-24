{% docs fct_daily_rt_url_guideline_checks %}

Each row represents a date/guideline check/RT url combination, with pass/fail
information indicating whether that RT url complied with that check on that date.
A row will exist for every check, for every row from the index which is driven
by int_gtfs_rt\_\_daily_url_index. Only contains checks that are performed at the RT url
level.

Here is a list of currently-implemented checks:

| Check                                | Feature         | Description                                                                |
| ------------------------------------ | --------------- | -------------------------------------------------------------------------- |
| Vehicle positions RT feed is present | Compliance (RT) | The vehicle positions RT feed contains at least one file on the given day. |
| Trip updates RT feed is present      | Compliance (RT) | The trip updates RT feed contains at least one file on the given day.      |
| Service alerts RT feed is present    | Compliance (RT) | The service alerts RT feed contains at least one file on the given day.    |
| {% enddocs %}                        |                 |                                                                            |
