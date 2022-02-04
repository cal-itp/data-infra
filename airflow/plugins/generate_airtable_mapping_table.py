# This is a little helper to generate SqlToWarehouse operator tasks
# to create mapping tables for Airtable data

# To run, start IPython within the airflow/plugins directory:
# `python3 -m IPython` or similar
# `import generate_airtable_mapping_table`
# `generate_airtable_mapping_table.process_csv(
#   '<path to CSV file>',
#  '<path to directory to write outputs
#   (should probably be airflow/dags/airtable_views)>')`

# the CSV file should have four fields: table1, table2, col1, col2
# where table1 and table2 are warehouse (not raw Airtable) table names
# and col1 and col2 are the corresponding (warehouse) column names
# that define the linked record relationship
# in cases of self-joins, leave table2 and col2 blank
# and just define the table in table1 and the foreign key column in col1
# (for example, services.paratransit_for)

import pandas as pd


def generate_sql(table1, table2, col1, col2):
    # fill in SQL template -- first construct name and id column names

    if table1[-1:] == "s":
        name1 = table1[:-1] + "_name"
        id1 = table1[:-1] + "_id"
    else:
        name1 = table1 + "_name"
        id1 = table1 + "_id"

    # check if self-join (if self-join, table2 is null)
    if pd.isnull(table2):
        # for self join, new column name & id are generated
        # from the self-join key column's name
        table_name = "california_transit_map_{table1}_{col1}_x_self".format(
            table1=table1, col1=col1
        )
        if col1[-1:] == "s":
            name2 = col1[:-1] + "_name"
            id2 = col1[:-1] + "_id"
        else:
            name2 = col1 + "_name"
            id2 = col1 + "_id"
        sql = SELF_JOIN_SQL_TEMPLATE.format(
            table_name=table_name,
            table=table1,
            col=col1,
            name1=name1,
            id1=id1,
            name2=name2,
            id2=id2,
        )
    else:
        table_name = "california_transit_map_{table1}_{col1}_x_{table2}_{col2}".format(
            table1=table1, col1=col1, table2=table2, col2=col2
        )
        if table2[-1:] == "s":
            name2 = table2[:-1] + "_name"
            id2 = table2[:-1] + "_id"
        else:
            name2 = table2 + "_name"
            id2 = table2 + "_id"
        sql = TWO_TABLE_SQL_TEMPLATE.format(
            table_name=table_name,
            table1=table1,
            table2=table2,
            table1_col=col1,
            table2_col=col2,
            id1=id1,
            id2=id2,
            name1=name1,
            name2=name2,
        )
    return table_name, sql


def write_file(directory, table1, table2, col1, col2):
    table_name, sql = generate_sql(table1, table2, col1, col2)
    filepath = directory + table_name + ".sql"
    with open(filepath, "w") as f:
        print("writing to {}".format(filepath))
        f.write(sql)


def process_csv(input_csv, directory="../dags/airtable_views/"):
    csv = pd.read_csv(input_csv)
    for row in csv.itertuples(index=False, name="row"):
        print("Processing: {}".format(row))
        write_file(directory, row.table1, row.table2, row.col1, row.col2)


# sql templates -- one for two different tables, other for self-join

TWO_TABLE_SQL_TEMPLATE = """---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_{table_name}

description: Mapping table for the GTFS {table1} table, {table1_col}
column and the {table2} table, {table2_col} column in the
California Transit Airtable base. Each row represents a
relationship between a {table1} record and a {table2} record.

fields:
  {id1}: Internal Airtable ID for a {table1} record
  {id2}: Internal Airtable ID for a {table2} record
  {name1}: {table1} record name
  {name2}: {table2} record name

tests:
  check_null:
    - {id1}
    - {id2}
    - {name1}
    - {name2}
  check_composite_unique:
    - {id1}
    - {id2}

external_dependencies:
- airtable_loader: california_transit_{table1}
- airtable_loader: california_transit_{table2}
---

-- follow the sandbox example for unnesting airtable data

WITH
unnested_t1 AS (
    SELECT
        T1.{id1}
        , T1.name as {name1}
        , CAST({table1_col} AS STRING) AS {id2}
    FROM
        `airtable.california_transit_{table1}` T1
        , UNNEST(JSON_VALUE_ARRAY({table1_col})) {table1_col}
),
unnested_t2 AS (
    SELECT
        T2.{id2}
        , T2.name as {name2}
        , CAST({table2_col} AS STRING) AS {id1}
    FROM
        `airtable.california_transit_{table2}` T2
        , UNNEST(JSON_VALUE_ARRAY({table2_col})) {table2_col}
)

SELECT *
FROM unnested_t1
FULL OUTER JOIN unnested_t2 USING({id1}, {id2})
"""

SELF_JOIN_SQL_TEMPLATE = """---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_{table_name}

description: Self-join mapping table for the GTFS {table} table, {col}
column in the California Transit Airtable base. Each row represents a
relationship between two {table} records.

fields:
  {id1}: Internal Airtable ID for a {table} record
  {id2}: Internal Airtable ID for a {table} record
  {name1}: {table} record name
  {name2}: {table} record name

tests:
  check_null:
    - {id1}
    - {id2}
    - {name1}
    - {name2}
  check_composite_unique:
    - {id1}
    - {id2}

external_dependencies:
- airtable_loader: california_transit_{table}
---

-- follow the sandbox example for unnesting airtable data

WITH

unnested_t1 AS (
    SELECT
        T1.{id1} as {id1}
        , T1.name as {name1}
        , CAST({col} AS STRING) AS {id2}
    FROM
        `airtable.california_transit_{table}` T1
        , UNNEST(JSON_VALUE_ARRAY({col})) {col}
),
t2 AS (
    SELECT
        T2.{id1} as {id2}
        , T2.name as {name2}
    FROM
        `airtable.california_transit_{table}` T2
)

SELECT *
FROM unnested_t1
LEFT JOIN t2 USING({id2})
"""
