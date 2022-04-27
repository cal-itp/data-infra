# What is an `agency`?
`agency` is a term that is used often across the Cal-ITP project but can have varying definitions depending on the context of it's use.

This section of the documentation seeks to help analysts determine how to translate the use of the word `agency` in research requests depending on the the are of focus that the research request falls into.

| Area of Focus | How to Identify `agency` |
| -------- | -------- |
| **GTFS** | For both GTFS static and real-time, it is often easier to think of agencies as unique feed publishers. To identify unique feed publishers: <ul><li>Remove `calitp_itp_id`: `200` (this is a regional reporter publishing duplicated of the smaller feeds inside it)</li><li>Deduplicate</li></ul>
| **DLA** | Unique list of organizations that can be found in . |
| **DRMT / 5311** | Unique list of organizations that can be found in . |
