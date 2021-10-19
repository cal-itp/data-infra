# SQL Snippets

## Fetching historical data for specific dates

Some tables in the warehouse--like those in `gtfs_schedule_type2`--capture the full
history of data, as it existed every day in the past. In order to do this, they
don't save copies of the full data every day, but log changes to the data using
a `calitp_extracted_at`, and `calitp_deleted_at` column.

In order to get the data for a given day, you need to filter to keep data where..

* `calitp_extracted_at` was earlier than or on the target date.
* `calitp_deleted_at` is later than the target date.

## A single date

```SQL
SELECT *
FROM `gtfs_schedule_type2.feed_info`
WHERE
    calitp_extracted_at >= "2021-06-01"
    AND COALESCE(calitp_deleted_at, "2099-01-01") < "2021-06-01"
```

Note that `COALESCE` lets us fill in NULL deleted at values to be far in the future.
This is used because when deleted at is missing, it reflects the most recent data
(i.e. data that hasn't been deleted yet).
Because `NULL < "2021-06-01"` is `false`, we need to fill it in with a far-future date,
so it evaluates to `true`.

## Multiple dates

In order to do it for a range of dates, you can use a JOIN. This is shown below.

```SQL
SELECT *
FROM `gtfs_schedule_type2.feed_info` FI
JOIN `views.dim_date` D
    ON FI.calitp_extracted_at <= D.full_date
        AND COALESCE(FI.calitp_deleted_at, "2099-01-01") > D.full_date
WHERE
    D.full_date BETWEEN ("2021-06-01", "2021-06-07")
```
