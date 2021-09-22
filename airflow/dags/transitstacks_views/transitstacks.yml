operator: operators.SqlToWarehouseOperator
dst_table_name: "views.transitstacks"
external_dependencies:
  - transitstacks_loader: all
sql: |
  WITH

  provider_county AS (

    -- note that this overview sheet links to other tables, EXCEPT for its county
    -- column, so we need to get just key columns and county out of it
    SELECT transit_provider, itp_id, ntd_id, modes, county
    FROM `transitstacks.overview`

  )

  SELECT *
  FROM
    `{{ "transitstacks.provider_info" | table }}`
    LEFT JOIN provider_county USING(transit_provider, itp_id, ntd_id,	modes)
    LEFT JOIN `{{ "transitstacks.fares" | table }}` USING(transit_provider, itp_id, ntd_id,	modes)
    LEFT JOIN `{{ "transitstacks.ntd_finances" | table }}` USING(transit_provider, itp_id, ntd_id,	modes)
    LEFT JOIN `{{ "transitstacks.ntd_stats" | table }}` USING(transit_provider, itp_id, ntd_id,	modes)
