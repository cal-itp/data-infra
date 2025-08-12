--------------------------------------------------------
-- (1) reproduce error in different count(trip_instance_key)
--------------------------------------------------------
WITH new_observed_trips AS (
    SELECT
        service_date,
        schedule_name,
        trip_instance_key,
        appeared_in_tu
    FROM `cal-itp-data-infra.mart_gtfs.fct_observed_trips`
    WHERE service_date >= "2025-06-15"
),

orig_observed_trips AS (
    SELECT
        service_date,
        schedule_name,
        trip_instance_key,
        appeared_in_tu
    FROM `cal-itp-data-infra.mart_gtfs.fct_observed_trips_8_5_2025`
    WHERE service_date >= "2025-06-15"
),

joined AS (
  SELECT
    new.service_date,
    new.schedule_name,
    new.schedule_base64_url,

    COUNTIF(new.appeared_in_tu IS TRUE) AS in_new,
    COUNTIF(orig.appeared_in_tu IS TRUE) AS in_old

    FROM new_observed_trips AS new
    FULL OUTER JOIN orig_observed_trips AS orig
        ON orig.service_date = new.service_date
        AND orig.schedule_name = new.schedule_name
        AND orig.schedule_base64_url = new.schedule_base64_url
        AND orig.trip_instance_key = new.trip_instance_key
    GROUP BY service_date, schedule_name, schedule_base64_url
)

-- ok yes, we have quite a few!
SELECT * FROM joined WHERE in_new != in_old


--------------------------------------------------------
-- (2) use trip_id/iteration_num instead and join, pick 1 operator
--------------------------------------------------------
-- looking at 1 operator for July dates, trip_instance_key has some interesting patterns:
-- (a) why does trip_instance_key appear in both the tables until 7/8;
-- (b) between 7/9 - 7/15, there are no trip_instance_keys in either table
-- (c) between 7/16 - 7/31, it's only in the new fct_observed_trips (so somehow this was backfilled, but it wasn't in our old one, presumably because errors already began)
-- full outer join makes this wonky
WITH new_observed_trips AS (
    SELECT
        service_date,
        schedule_name,
        trip_id,
        iteration_num,
        trip_instance_key,
        appeared_in_tu
    FROM `cal-itp-data-infra.mart_gtfs.fct_observed_trips`
    WHERE service_date >= "2025-07-01" AND service_date <= "2025-08-10" AND schedule_name = "Tracy Schedule"
),

orig_observed_trips AS (
    SELECT
        service_date,
        schedule_name,
        trip_id,
        iteration_num,
        trip_instance_key,
        appeared_in_tu
    FROM `cal-itp-data-infra.mart_gtfs.fct_observed_trips_8_5_2025`
    WHERE service_date >= "2025-07-01" AND service_date <= "2025-08-10" AND schedule_name = "Tracy Schedule"
),

joined AS (
    SELECT
        COALESCE(t1.service_date, t2.service_date) AS service_date,
        t2.schedule_name,
        t2.trip_id,
        t2.iteration_num,

        t1.trip_instance_key AS old_trip_key,
        t2.trip_instance_key AS new_trip_key,
        t1.appeared_in_tu AS in_old,
        t2.appeared_in_tu AS in_new

    FROM new_observed_trips AS t2
    FULL OUTER JOIN orig_observed_trips AS t1
        ON t1.service_date = t2.service_date
        AND t1.schedule_name = t2.schedule_name
        AND t1.trip_id = t2.trip_id
        AND t1.iteration_num = t2.iteration_num
    ORDER BY trip_id, service_date
)

SELECT * FROM joined
