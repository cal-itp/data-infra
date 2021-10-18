---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.transitstacks"

tests:
  check_unique:
    - itp_id

external_dependencies:
  - transitstacks_loader: all
---

WITH

provider_county AS (

  -- note that this overview sheet links to other tables, EXCEPT for its county
  -- column, so we need to get just key columns and county out of it
  SELECT transit_provider, itp_id, ntd_id, modes, county
  FROM `transitstacks.overview`

)

SELECT
  PI.itp_id
  , PI.transit_provider
  , PI.ntd_id
  , PI.modes
  , * EXCEPT(itp_id, transit_provider, ntd_id, modes)
FROM
  `transitstacks.provider_info` PI
  LEFT JOIN provider_county USING(itp_id)
  LEFT JOIN `transitstacks.fares` USING(itp_id)
  LEFT JOIN `transitstacks.ntd_finances` USING(itp_id)
  LEFT JOIN `transitstacks.ntd_stats` USING(itp_id)
