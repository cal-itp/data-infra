SELECT 
  organization,
  reportstatus as api_report_status,
  TIMESTAMP_MILLIS(reportlastmodifieddate) as api_report_last_modified_date,
  reportperiod as api_report_period,
  ntdreportingrr20_rural_data.id as id,
  ntdreportingrr20_rural_data.ReportId as report_id,
  ntdreportingrr20_rural_data.Item as item,
  ntdreportingrr20_rural_data.Revenue as revenue,
  ntdreportingrr20_rural_data.Type as type,
  ntdreportingrr20_rural_data.CSSClass as css_class,
  ntdreportingrr20_rural_data.OperationsExpended as operations_expended,
  ntdreportingrr20_rural_data.CapitalExpended as capital_expended,
  ntdreportingrr20_rural_data.Description as description,
  ntdreportingrr20_rural_data.AnnualVehicleRevMiles as annual_vehicle_rev_miles,
  ntdreportingrr20_rural_data.AnnualVehicleRevHours as annual_vehicle_rev_hours,
  ntdreportingrr20_rural_data.AnnualUnlinkedPassTrips as annual_unlinked_pass_trips,
  ntdreportingrr20_rural_data.AnnualVehicleMaxService as annual_vehicle_max_service,
  ntdreportingrr20_rural_data.SponsoredServiceUPT as sponsored_service_upt,
  ntdreportingrr20_rural_data.Quantity as quantity,
  ntdreportingrr20_rural_data.LastModifiedDate as last_modified_date
FROM `cal-itp-data-infra-staging.external_blackcat.all_2023_ntdreports`
, UNNEST (`ntdreportingrr20_rural_data`) as `ntdreportingrr20_rural_data`