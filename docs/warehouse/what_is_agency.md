# What is an `agency`?
`agency` is a term that is used often across the Cal-ITP project but can have varying definitions in terms of an analysis depending on the context of it's use.

This section of the documentation seeks to help analysts determine how to translate the use of the word `agency` in research requests depending on the area of focus that the research request falls into.

| <span style="white-space: nowrap;">Area of Focus</span> | How to Identify `agency` |
| -------- | -------- |
| **GTFS** | For both GTFS Static and GTFS Real-Time, it is easiest to think of `agency` as "unique feed publisher", with the exception of feed `calitp_itp_id` == `200` as it is a regional reporter that publishes duplicates of other feeds that we also consume. To identify unique feed publishers: <ul><li>Exclude `calitp_itp_id`== `200`</li><li>Deduplicate feeds</li></ul>
| **DLA** | Unique list of organizations that can be found in . |
| **DRMT / 5311** | Unique list of organizations that can be found in . |
