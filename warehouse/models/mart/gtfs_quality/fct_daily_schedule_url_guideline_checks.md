{% docs fct_daily_schedule_url_guideline_checks %}

Each row represents a date/guideline check/schedule url combination, with pass/fail
information indicating whether that feed complied with that check on that date.
A row will exist for every check, for every row from the index which is driven
by fct_schedule_feed_downloads. Only contains checks that are performed at the schedule url
level.

Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
| Schedule feed downloads successfully | Compliance (Schedule) | On the given date, the schedule feed was downloaded and parsed successfully. |
{% enddocs %}
