# calitp-data-analysis

Functionality for querying notebooks.

[Documentation](https://docs.calitp.org/data-infra/analytics_tools/python_libraries.html#calitp-data-analysis)

## Migration steps needed for upgrading to 2025.9.22 or higher

`tbls` was removed with version 2025.9.22. Instead of `AutoTable` or the `tbls`
instance, use `query_sql()` from `calitp_data_analysis.sql` to connect to and query a SQL database. See the [`query_sql()`section](https://docs.calitp.org/data-infra/analytics_tools/python_libraries.html#calitp-data-analysis-query-sql) from the documentation.
