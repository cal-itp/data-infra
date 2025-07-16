SELECT
  organization,
  reportstatus as api_report_status,
  reportlastmodifieddate as api_report_last_modified_date,
  reportperiod as api_report_period,
  a10.id as id,
  a10.ReportId as report_id,
  a10.ServiceMode as service_mode,
  a10.PTOwnedByServiceProvider as pt_owned_by_service_provider,
  a10.PTOwnedByPublicAgency as pt_owned_by_public_agency,
  a10.PTLeasedByPublicAgency as pt_leased_by_public_agency,
  a10.PTLeasedByServiceProvider as pt_leased_by_service_provider,
  a10.DOOwned as do_owned,
  a10.DOLeasedByPublicAgency as do_leased_by_public_agency,
  a10.DOLeasedFromPrivateEntity as do_leased_from_private_entity,
  a10.LastModifiedDate as last_modified_date
FROM {{ source('ntd_report_validation', 'all_ntdreports') }},
 UNNEST(`ntdreportingstationsandmaintenance_data`) as `a10`
