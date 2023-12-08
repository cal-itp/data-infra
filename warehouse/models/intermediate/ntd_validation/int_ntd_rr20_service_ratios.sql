---- NOTE this only works because there is ONE row per org, year, mode.
---- If this ever changes or gets duplicated upstream, then these calculations will be off.

SELECT
    *,
    Total_Annual_Expenses_By_Mode / NULLIF(Annual_VRH,0) as cost_per_hr,
    Annual_VRM / NULLIF(VOMX,0) as miles_per_veh,
    Fare_Revenues / NULLIF(Annual_UPT,0) as fare_rev_per_trip,
    Annual_VRM / NULLIF(Annual_VRH,0) as rev_speed,
    Annual_UPT / NULLIF(Annual_VRH,0) as trips_per_hr
FROM {{ ref('int_ntd_rr20_service_alldata') }}
