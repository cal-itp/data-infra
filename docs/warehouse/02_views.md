# Creating New Tables (Views)

| operator | description | example |
| -------- | ----------- | ------- |
| CsvToWarehouseOperator  | Load a CSV (or google sheet) from a URL | [`transitstacks.fares`](https://github.com/cal-itp/data-infra/blob/main/airflow/dags/transitstacks_loader/fares.yml) |
| PythonToWarehouseOperator | Load data using python and the calitp library. This is a very flexible approach. It's useful when you want to do a small amount of processing before loading. | [`views.validation_code_descriptions`](https://github.com/cal-itp/data-infra/blob/main/airflow/dags/gtfs_views/validation_code_descriptions.py) |
| SqlToWarehouseOperator | Create a new table from a SQL query. | [`views.transitstacks`](https://github.com/cal-itp/data-infra/blob/main/airflow/dags/gtfs_views/transitstacks.yml) |
| SqlQueryOperator | Run arbitrary SQL (e.g. `CREATE EXTERNAL TABLE ...`) | |

## Syntax overview

Below is a file similar to the one used to create `views.transitstacks`.

```yaml
# What operator to use. This determines the options available, and how the
# pipeline executes this task.
operator: operators.SqlToWarehouseOperator

# Name of the table to load into the warehouse
dst_table_name: "views.dim_date"

# Column descriptions to put into warehouse
fields:
  - id: The ID Column
  - full_date: The full date (e.g. "2021-01-01")
  - year: The year component (e.g. 2021)

# Specify tests to run over the data
# e.g. check_null to verify a column contains no nulls
# e.g. check_unique to verify no duplicate values in a column
tests:
  check_null:
    - id
  check_unique:
    - id
    - full_date

# Other tasks this depends on. For example, if it uses another SQL view, then
# that view should be a dependency
dependencies:
  - warehouse_loaded

# The actual SQL code to be run!
sql: |
  # from https://gist.github.com/ewhauser/d7dd635ad2d4b20331c7f18038f04817
  SELECT
    FORMAT_DATE('%F', d) as id,
    d AS full_date,
    EXTRACT(YEAR FROM d) AS year,
  FROM
    UNNEST(GENERATE_DATE_ARRAY('2001-01-01', '2050-01-01', INTERVAL 1 DAY)) d
```

## Testing Changes

## Walkthrough
