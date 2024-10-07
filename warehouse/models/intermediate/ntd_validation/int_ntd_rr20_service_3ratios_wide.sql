{% set this_year = run_started_at.year %}
{% set last_year = this_year - 1 %}

with longform as (
    select
    organization,
    fiscal_year,
    mode,
    VOMX,
    Annual_VRM,
    Annual_VRH,
    Annual_UPT,
    cost_per_hr,
    miles_per_veh,
    fare_rev_per_trip,
    rev_speed,
    trips_per_hr
    from {{ ref('int_ntd_rr20_service_2ratioslong') }}
  ),

  cph as (
    select * from
    (select organization, fiscal_year, mode,cost_per_hr from longform)
    PIVOT(AVG(cost_per_hr) FOR fiscal_year IN ({{last_year}} AS _last_year, {{this_year}} AS _this_year)) as cost_per_hr
        ORDER BY organization
  ),

  mpv as (
    select * from
    (select organization, fiscal_year, mode, miles_per_veh from longform)
    PIVOT(AVG(miles_per_veh) FOR fiscal_year IN ({{last_year}} AS _last_year, {{this_year}} AS _this_year)) as miles_per_veh
        ORDER BY organization
  ),

  frpt as (
    select * from
    (select organization, fiscal_year, mode, fare_rev_per_trip from longform)
    PIVOT(AVG(fare_rev_per_trip) FOR fiscal_year IN ({{last_year}} AS _last_year, {{this_year}} AS _this_year)) as fare_rev_per_trip
        ORDER BY organization
  ),

rev_speed as (
  select * from
    (select organization, fiscal_year, mode, rev_speed from longform)
    PIVOT(AVG(rev_speed) FOR fiscal_year IN ({{last_year}} AS _last_year, {{this_year}} AS _this_year)) as rev_speed
        ORDER BY organization
),

tph as (
  select * from
    (select organization, fiscal_year, mode, trips_per_hr from longform)
    PIVOT(AVG(trips_per_hr) FOR fiscal_year IN ({{last_year}} AS _last_year, {{this_year}} AS _this_year)) as trips_per_hr
        ORDER BY organization
),

voms as (
  select * from
    (select organization, fiscal_year, mode, VOMX from longform)
    PIVOT(AVG(VOMX) FOR fiscal_year IN ({{last_year}} AS _last_year, {{this_year}} AS _this_year)) as VOMX
        ORDER BY organization
),

 vrm as (
  select * from
    (select organization, fiscal_year, mode, Annual_VRM from longform)
    PIVOT(AVG(Annual_VRM) FOR fiscal_year IN ({{last_year}} AS _last_year, {{this_year}} AS _this_year)) as Annual_VRM
        ORDER BY organization
 ),

 vrh as (
    select * from
    (select organization, fiscal_year, mode, Annual_VRH from longform)
    PIVOT(AVG(Annual_VRH) FOR fiscal_year IN ({{last_year}} AS _last_year, {{this_year}} AS _this_year)) as Annual_VRH
        ORDER BY organization
 ),

 upt as (
    select * from
    (select organization, fiscal_year, mode, Annual_UPT from longform)
    PIVOT(AVG(Annual_UPT) FOR fiscal_year IN ({{last_year}} AS _last_year, {{this_year}} AS _this_year)) as Annual_UPT
        ORDER BY organization
 )

select distinct cph.organization,
  cph.mode,
  cph._last_year as cph_last_year,
  cph._this_year as cph_this_year,
  mpv._last_year as mpv_last_year,
  mpv._this_year as mpv_this_year,
  frpt._last_year as frpt_last_year,
  frpt._this_year as frpt_this_year,
  rev_speed._last_year as rev_speed_last_year,
  rev_speed._this_year as rev_speed_this_year,
  tph._last_year as tph_last_year,
  tph._this_year as tph_this_year,
  voms._last_year as voms_last_year,
  voms._this_year as voms_this_year,
  vrm._last_year as vrm_last_year,
  vrm._this_year as vrm_this_year,
  vrh._last_year as vrh_last_year,
  vrh._this_year as vrh_this_year,
  upt._last_year as upt_last_year,
  upt._this_year as upt_this_year
 from cph
 FULL OUTER JOIN mpv
  on cph.organization = mpv.organization
  AND cph.mode = mpv.mode
 FULL OUTER JOIN frpt
  on cph.organization = frpt.organization
  AND cph.mode = frpt.mode
FULL OUTER JOIN rev_speed
  on cph.organization = rev_speed.organization
  AND cph.mode = rev_speed.mode
FULL OUTER JOIN tph
  on cph.organization = tph.organization
  AND cph.mode = tph.mode
FULL OUTER JOIN voms
  on cph.organization = voms.organization
  AND cph.mode = voms.mode
FULL OUTER JOIN vrm
  on cph.organization = vrm.organization
  AND cph.mode = vrm.mode
FULL OUTER JOIN vrh
  on cph.organization = vrh.organization
  AND cph.mode = vrh.mode
FULL OUTER JOIN upt
  on cph.organization = upt.organization
  AND cph.mode = upt.mode
ORDER BY organization
