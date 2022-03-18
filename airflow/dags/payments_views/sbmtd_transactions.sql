---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.sbmtd_transactions"
dependencies:
  - dummy_staging

fields:
  littlepay_transaction_id: "From payments.device_transactions.littlepay_transaction_id"
  micropayment_id: "From payments.micropayments.micropayment_id"
  customer_id: "From payments.device_transactions.customer_id"
  location_name: "From payments.device_transactions.location_name"
  location_id: "From payments.device_transactions.location_id"
  is_shared_stop: "True if more than one route is served by the stop; else false"
  all_route_ids: "Comma-separated list of routes served by the stop"
  route_id_from_device: "From payments.device_transactions.route_id"
  likely_route_id:  "ID of the route that the transaction most likely performed on, based on the routes served by the stop and the routes that are part of the demonstration"
  likely_route_long_name: "Long name of the route that the transaction most likely performed on, based on the routes served by the stop and the routes that are part of the demonstration"
  likely_route_short_name: "Short name of the route that the transaction most likely performed on, based on the routes served by the stop and the routes that are part of the demonstration"
  vehicle_id: "From payments.device_transactions.vehicle_id"
  transaction_date_time_utc: "From payments.device_transactions.transaction_date_time_utc"
  transaction_date_time_pacific: "transaction_date_time_utc converted to pacific time"

tests:
  check_unique:
    - littlepay_transaction_id
    - micropayment_id
---

with

/*
  De-deuplicate source tables
*/

micropayments_dedupe AS (
    SELECT * FROM payments.stg_enriched_micropayments
    WHERE calitp_dupe_number = 1
),

device_transactions_dedupe AS (
    SELECT * FROM payments.stg_enriched_device_transactions
    WHERE calitp_dupe_number = 1
),

micropayment_device_transactions_dedupe AS (
    SELECT * FROM payments.stg_enriched_micropayment_device_transactions
    WHERE calitp_dupe_number = 1
),

/*
  All the unique routes and stops across SBMTD
*/
dated_route_stops as (
    select distinct
        route_id,
        stop_id,
        case
          when ((st.calitp_extracted_at >= t.calitp_extracted_at) and
            (st.calitp_extracted_at >= r.calitp_extracted_at))
            then st.calitp_extracted_at
          when ((t.calitp_extracted_at >= st.calitp_extracted_at) and
            (t.calitp_extracted_at >= r.calitp_extracted_at))
            then t.calitp_extracted_at
          when ((r.calitp_extracted_at >= st.calitp_extracted_at) and
            (r.calitp_extracted_at >= t.calitp_extracted_at))
            then r.calitp_extracted_at
        end
        as calitp_extracted_at,

        case
          when ((st.calitp_deleted_at <= t.calitp_deleted_at) and
            (st.calitp_deleted_at <= r.calitp_deleted_at))
            then st.calitp_deleted_at
          when ((t.calitp_deleted_at <= st.calitp_deleted_at) and
            (t.calitp_deleted_at <= r.calitp_deleted_at))
            then t.calitp_deleted_at
          when ((r.calitp_deleted_at <= st.calitp_deleted_at) and
            (r.calitp_deleted_at <= t.calitp_deleted_at))
            then r.calitp_deleted_at
        end
        as calitp_deleted_at
    from views.gtfs_schedule_dim_stop_times as st
    join views.gtfs_schedule_dim_trips as t using (calitp_itp_id, calitp_url_number, trip_id)
    join views.gtfs_schedule_dim_routes as r using (calitp_itp_id, calitp_url_number, route_id)
    where calitp_itp_id = 293
    and calitp_url_number = 0
),

route_stops as (
  select *
  from dated_route_stops
  where calitp_extracted_at < calitp_deleted_at
),

/*
  Stats for each stop, such as:
    * How many routes stop at each?
    * What are the IDs of the routes that stop at each?
    * Are the routes in the demonstration (12X, 24X) served by the stop?
*/
stop_stats as (
    select
        stop_id,
        calitp_extracted_at,
        calitp_deleted_at,
        count(*) as num_routes_for_stop,
        string_agg(route_id, ', ') as all_route_ids,
        '12X' in unnest(array_agg(route_id)) as serves_12x,
        '24X' in unnest(array_agg(route_id)) as serves_24x
    from route_stops
    group by
      stop_id,
      calitp_extracted_at,
      calitp_deleted_at
),

/*
  Device transactions joined with the stop stats data
*/
transactions as (
    select
        littlepay_transaction_id,
        micropayment_id,
        customer_id,
        dt.location_name,
        dt.location_id,
        stat.num_routes_for_stop > 1 as is_shared_stop,
        stat.all_route_ids,
        dt.route_id as route_id_from_device,
        case
            when dt.route_id is not null then dt.route_id
            when stat.num_routes_for_stop = 1 then stat.all_route_ids
            when stat.serves_12x and not stat.serves_24x then '12X'
            when stat.serves_24x and not stat.serves_12x then '24X'
            else null
        end as likely_route_id,
        dt.vehicle_id,
        dt.latitude,
        dt.longitude,
        dt.transaction_date_time_utc
    from micropayments_dedupe as m
    join micropayment_device_transactions_dedupe using (micropayment_id)
    join device_transactions_dedupe as dt using (littlepay_transaction_id, customer_id, participant_id)
    join stop_stats as stat
      on stat.stop_id = trim(dt.location_id)
      and datetime(timestamp(dt.transaction_date_time_utc)) >= stat.calitp_extracted_at
      and datetime(timestamp(dt.transaction_date_time_utc)) < stat.calitp_deleted_at
    where participant_id = 'sbmtd'
      and m.type = 'DEBIT'
)

select
    t.littlepay_transaction_id,
    t.micropayment_id,
    t.customer_id,
    t.location_name,
    t.location_id,
    t.is_shared_stop,
    t.all_route_ids,
    t.route_id_from_device,
    trim(t.likely_route_id) as likely_route_id,
    r.route_long_name as likely_route_long_name,
    r.route_short_name as likely_route_short_name,
    t.vehicle_id,
    t.transaction_date_time_utc,
    DATETIME(TIMESTAMP(transaction_date_time_utc), "America/Los_Angeles") as transaction_date_time_pacific
from transactions as t
left join views.gtfs_schedule_dim_routes as r
    on r.calitp_itp_id = 293
        and r.calitp_url_number = 0
        and r.route_id = trim(t.likely_route_id)
        and datetime(timestamp(t.transaction_date_time_utc)) >= r.calitp_extracted_at
        and datetime(timestamp(t.transaction_date_time_utc)) < r.calitp_extracted_at
order by t.likely_route_id nulls last
