---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.sbmtd_transactions"
external_dependencies:
  - payments_loader: all

fields:
  littlepay_transaction_id: "From payments.device_transactions.littlepay_transaction_id"
  micropayment_id: "From payments.micropayments.micropayment_id"
  customer_id: "From payments.device_transactions.customer_id"
  location_name: "From payments.device_transactions.location_name"
  location_id: "From payments.device_transactions.location_id"
  is_shared_stop: "True if more than one route is served by the stop; else false"
  all_route_ids: "Comma-separated list of routes served by the stop"
  likely_route_name: "Name of the route that the transaction most likely performed on, based on the routes served by the stop and the routes that are part of the demonstration"
  likely_route_id:  "ID of the route that the transaction most likely performed on, based on the routes served by the stop and the routes that are part of the demonstration"
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
  All the unique routes and stops across SBMTD
*/
route_stops as (
    select distinct
        route_id,
        stop_id
    from gtfs_schedule.stop_times as st
    join gtfs_schedule.trips as t using (calitp_itp_id, calitp_url_number, trip_id)
    join gtfs_schedule.routes as r using (calitp_itp_id, calitp_url_number, route_id)
    where calitp_itp_id = 293
    and calitp_url_number = 0
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
        count(*) as num_routes_for_stop,
        string_agg(route_id, ', ') as all_route_ids,
        '12X' in unnest(array_agg(route_id)) as serves_12x,
        '24X' in unnest(array_agg(route_id)) as serves_24x
    from route_stops
    group by 1
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
        case
            when stat.num_routes_for_stop = 1 then stat.all_route_ids
            when stat.serves_12x and not stat.serves_24x then '12X'
            when stat.serves_24x and not stat.serves_12x then '24X'
            else null
        end as likely_route_id,
        dt.vehicle_id,
        dt.latitude,
        dt.longitude,
        dt.transaction_date_time_utc
    from payments.micropayments as m
    join payments.micropayment_device_transactions using (micropayment_id)
    join payments.device_transactions as dt using (littlepay_transaction_id, customer_id, participant_id)
    join stop_stats as stat on stat.stop_id = dt.location_id
    where participant_id = 'sbmtd'
)

select
    t.littlepay_transaction_id,
    t.micropayment_id,
    t.customer_id,
    t.location_name,
    t.location_id,
    t.is_shared_stop,
    t.all_route_ids,
    r.route_long_name as likely_route_name,
    t.likely_route_id,
    t.vehicle_id,
    t.transaction_date_time_utc,
    DATETIME(TIMESTAMP(transaction_date_time_utc), "America/Los_Angeles") as transaction_date_time_pacific
from transactions as t
left join gtfs_schedule.routes as r
    on r.calitp_itp_id = 293
        and r.calitp_url_number = 0
        and r.route_id = t.likely_route_id
order by t.likely_route_id nulls last
