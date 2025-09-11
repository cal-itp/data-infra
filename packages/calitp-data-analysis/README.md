# calitp-data-analysis

Functionality for querying notebooks.

[Documentation](https://docs.calitp.org/data-infra/analytics_tools/python_libraries.html#calitp-data-analysis)

DEPRECATED: The most important functionality is
probably the `AutoTable` accessible via `from calitp_data_analysis.tables import tbls` which
provides siuba access to the BigQuery warehouse data models (tables or views).
`get_engine()` underlies most functions that interact with the warehouse but can
also be used directly to interact with BigQuery.
