(creating-new-views)=
# Creating New Tables (Views)

| operator | description | example |
| -------- | ----------- | ------- |
| AirtableToWarehouseOperator | Extract the contents of a table in Airtable into a new Big Query dataset and optionally also archiving as a CSV in Google Cloud Storage. | (https://github.com/cal-itp/data-infra/blob/main/airflow/dags/sandbox/op_airtable_to_warehouse.yml) |
| CsvToWarehouseOperator  | Load a CSV (or google sheet) from a URL | [`transitstacks.fares`](https://github.com/cal-itp/data-infra/blob/main/airflow/dags/transitstacks_loader/fares.yml) |
| PythonToWarehouseOperator | Load data using python and the calitp library. This is a very flexible approach. It's useful when you want to do a small amount of processing before loading. | [`gtfs_loader.validation_code_descriptions`](https://github.com/cal-itp/data-infra/blob/main/airflow/dags/gtfs_loader/validation_code_descriptions.py) |
| SqlToWarehouseOperator | Create a new table from a SQL query. | |
| SqlQueryOperator | Run arbitrary SQL (e.g. `CREATE EXTERNAL TABLE ...`) | |

## Syntax overview

Below is an example file for the SqlToWarehouseOperator that uses gusty syntax. This file is similar to the one used to create `views.transitstacks`. A number of other operators have variations on this that is currently best learned about by either looking at examples or the underlying operator source code.

```yaml
# What operator to use. This determines the options available, and how the
# pipeline executes this task.
operator: operators.SqlToWarehouseOperator

# Name of the table to load into the warehouse. For some operators this might be `table_name`.
dst_table_name: "views.dim_date"

# Column descriptions to put into warehouse
fields:
  id: The ID Column
  full_date: The full date (e.g. "2021-01-01")
  year: The year component (e.g. 2021)

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

As shown in the above section, you can specify tests in your task files, by adding a `tests` field.

Note that there are currently 3 options for testing.

* check_null: test that each column listed does not have NULL values.
* check_unique: test that each column listed has all unique values.
* check_composite_unique: test that the combination of all columns listed is unique.

## Walkthrough

<div style="position: relative; padding-bottom: 62.5%; height: 0;"><iframe src="https://www.loom.com/embed/8873e9e3d01746e280e575898795d49f" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe></div>
