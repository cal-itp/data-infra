# calitp-data-analysis

Functionality for querying notebooks. The most important functionality is
probably the `AutoTable` accessible via `from calitp_data_analysis.tables import tbls` which
provides siubar access to the BigQuery warehouse data models (tables or views).
`get_engine()` underlies most functions that interact with the warehouse but can
also be used directly to interact with BigQuery.
