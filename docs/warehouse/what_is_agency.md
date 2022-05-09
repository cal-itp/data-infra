# What is an `agency`?
`agency` is a term that is used often across the Cal-ITP project but depending on the context of it's use it can have varying meanings when conducting an analysis.

This section of the documentation seeks to help analysts determine how to translate the use of the word `agency` in research requests depending on the area of focus that the research request falls into.

| <span style="white-space: nowrap;">Area of Focus</span> | How to Identify `agency` |
| -------- | -------- |
| **GTFS Datasets** | For both GTFS Static and GTFS Real-Time data, when trying to analyze GTFS datasets it is easiest to think of `agency` as "unique feed publisher", with the exception of feed `calitp_itp_id` == `200` as it is a regional reporter that publishes duplicates of other feeds that we also consume.<br/><br/>To identify unique feed publishers:<ul><li>Exclude `calitp_itp_id`== `200`</li><li>Deduplicate feeds</li></ul> |
| **GTFS-Provider-Service Relationships** | In the warehouse, this is the relationship between `organizations` and the `services` they manage. <br/><br/>This is not an exhaustive list of all services managed by providers, only those that we are targeting to get into GTFS reporting.<br/><br/>Each record defines an organization and one of it's services. For the most part, each service is managed by a single organization with a small number of exceptions (e.g. Solano Express, which is jointly managed by Solano and Napa).<br/><br/>**Relevant data**:<br/>Table: `cal-itp-data-infra.views.airtable_california_transit_map_organizations_mobility_services_managed_x_services_provider`<ul><li>Column: `organization_name`</li><li>Column: `service_name`</li><br/>
