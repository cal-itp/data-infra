-- DECLARE check_period STRING;
-- SET check_period = CONCAT(EXTRACT(YEAR from CURRENT_DATE()), ", ", EXTRACT(YEAR from CURRENT_DATE()) - 1);

-- DECLARE query STRING;
-- SET query = CONCAT(
  with longform as (
    select
    organization,
    -- CAST(fiscal_year as STRING) as fiscal_year,
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
    -- PIVOT(AVG(cost_per_hr) FOR fiscal_year IN (', check_period, '))
    PIVOT(AVG(cost_per_hr) FOR fiscal_year IN (2022,2023,2024)) as cost_per_hr
        ORDER BY organization
  ),

  mpv as (
    select * from
    (select organization, fiscal_year, mode, miles_per_veh from longform)
    PIVOT(AVG(miles_per_veh) FOR fiscal_year IN (2022,2023,2024)) as miles_per_veh
        ORDER BY organization
  ),
  frpt as (
    select * from
    (select organization, fiscal_year, mode, fare_rev_per_trip from longform)
    PIVOT(AVG(fare_rev_per_trip) FOR fiscal_year IN (2022,2023,2024)) as fare_rev_per_trip
        ORDER BY organization
  ),
rev_speed as (
  select * from
    (select organization, fiscal_year, mode, rev_speed from longform)
    PIVOT(AVG(rev_speed) FOR fiscal_year IN (2022,2023,2024)) as rev_speed
        ORDER BY organization
),
tph as (
  select * from
    (select organization, fiscal_year, mode, trips_per_hr from longform)
    PIVOT(AVG(trips_per_hr) FOR fiscal_year IN (2022,2023,2024)) as trips_per_hr
        ORDER BY organization
),
voms as (
  select * from
    (select organization, fiscal_year, mode, VOMX from longform)
    PIVOT(AVG(VOMX) FOR fiscal_year IN (2022,2023,2024)) as VOMX
        ORDER BY organization
),
 vrm as (
  select * from
    (select organization, fiscal_year, mode, Annual_VRM from longform)
    PIVOT(AVG(Annual_VRM) FOR fiscal_year IN (2022,2023,2024)) as Annual_VRM
        ORDER BY organization
 ),
 vrh as (
    select * from
    (select organization, fiscal_year, mode, Annual_VRH from longform)
    PIVOT(AVG(Annual_VRH) FOR fiscal_year IN (2022,2023,2024)) as Annual_VRH
        ORDER BY organization
 ),
 upt as (
    select * from
    (select organization, fiscal_year, mode, Annual_UPT from longform)
    PIVOT(AVG(Annual_UPT) FOR fiscal_year IN (2022,2023,2024)) as Annual_UPT
        ORDER BY organization
 )

-- select * from mpv
select distinct cph.organization,
  cph.mode,
  cph._2022 as cph_2022,
  cph._2023 as cph_2023,
  cph._2024 as cph_2024,
  mpv._2022 as mpv_2022,
  mpv._2023 as mpv_2023,
  mpv._2024 as mpv_2024,
  frpt._2022 as frpt_2022,
  frpt._2023 as frpt_2023,
  frpt._2024 as frpt_2024,
  rev_speed._2022 as rev_speed_2022,
  rev_speed._2023 as rev_speed_2023,
  rev_speed._2024 as rev_speed_2024,
  tph._2022 as tph_2022,
  tph._2023 as tph_2023,
  tph._2024 as tph_2024,
  voms._2022 as voms_2022,
  voms._2023 as voms_2023,
  voms._2024 as voms_2024,
  vrm._2022 as vrm_2022,
  vrm._2023 as vrm_2023,
  vrm._2024 as vrm_2024,
  vrh._2022 as vrh_2022,
  vrh._2023 as vrh_2023,
  vrh._2024 as vrh_2024,
  upt._2022 as upt_2022,
  upt._2023 as upt_2023,
  upt._2024 as upt_2024
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
-- );

-- EXECUTE IMMEDIATE query;
