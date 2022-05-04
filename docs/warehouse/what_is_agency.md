# What is an `agency`?
`agency` is a term that is used often across the Cal-ITP project but depending on the context of it's use it can have varying meanings when conducting an analysis.

This section of the documentation seeks to help analysts determine how to translate the use of the word `agency` in research requests depending on the area of focus that the research request falls into.

| <span style="white-space: nowrap;">Area of Focus</span> | How to Identify `agency` |
| -------- | -------- |
| **GTFS Datasets** | For both GTFS Static and GTFS Real-Time data, when trying to analyze GTFS datasets it is easiest to think of `agency` as "unique feed publisher", with the exception of feed `calitp_itp_id` == `200` as it is a regional reporter that publishes duplicates of other feeds that we also consume. To identify unique feed publishers: <ul><li>Exclude `calitp_itp_id`== `200`</li><li>Deduplicate feeds</li></ul> |
| **GTFS-Provider-Service Relationships** | In Airtable, this is the relationship between `organizations` and the `services` they manage. <br/>This is not an exhaustive list of all services managed by that provider, only those that we are targeting to get into GTFS reporting.<br/>Relevant data:<br/>`California Transit` Airtable<br/>Table: `organizations`<ul><li>Column: `Name`</li><li>line 2</li><br/>Table: `gtfs service data` <ul><li>Column: `Services`</li><li>Each record defines a transit service and its properties.</li><li>While there are a small number of exceptions (e.g. Solano Express, which is jointly managed by Solano and Napa), generally each transit service is managed by a single organization.</li></ul> |
