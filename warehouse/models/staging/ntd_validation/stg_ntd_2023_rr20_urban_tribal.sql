SELECT
  organization,
  reportstatus as api_report_status,
  TIMESTAMP_MILLIS(reportlastmodifieddate) as api_report_last_modified_date,
  reportperiod as api_report_period,
  ntdreportingrr20_urban_tribal_data.id as id,
  ntdreportingrr20_urban_tribal_data.ReportId as report_id,
  ntdreportingrr20_urban_tribal_data.ItemId as item_id,
  ntdreportingrr20_urban_tribal_data.Item as item,
  ntdreportingrr20_urban_tribal_data.OperationsExpended as operations_expended,
  ntdreportingrr20_urban_tribal_data.CapitalExpended as capital_expended,
  ntdreportingrr20_urban_tribal_data.Description as description,
  ntdreportingrr20_urban_tribal_data.LastModifiedDate as last_modified_date
FROM {{ source('ntd_report_validation', 'all_2023_ntdreports') }},
-- `cal-itp-data-infra-staging.external_blackcat.all_2023_ntdreports`
  UNNEST(`ntdreportingrr20_urban_tribal_data`) as `ntdreportingrr20_urban_tribal_data`
