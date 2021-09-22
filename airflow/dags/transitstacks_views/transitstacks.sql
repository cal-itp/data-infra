---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.transitstacks"
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

SELECT *
FROM
  `transitstacks.provider_info`
  LEFT JOIN provider_county USING(transit_provider, itp_id, ntd_id,	modes)
  LEFT JOIN `transitstacks.fares` USING(transit_provider, itp_id, ntd_id,	modes)
  LEFT JOIN `transitstacks.ntd_finances` USING(transit_provider, itp_id, ntd_id,	modes)
  LEFT JOIN `transitstacks.ntd_stats` USING(transit_provider, itp_id, ntd_id,	modes)
