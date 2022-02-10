# This is a helper to generate SqlToWarehouse operator tasks
# to create mapping tables for Airtable data

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
    if pd.isnull(table2) or table2 == "":
        # for self join, new column name & id are generated
        # from the self-join key column's name
        if col1[-1:] == "s":
            name2 = col1[:-1] + "_name"
            id2 = col1[:-1] + "_id"
        else:
            name2 = col1 + "_name"
            id2 = col1 + "_id"
        sql = SELF_JOIN_SQL_TEMPLATE.format(
            table=table1, col=col1, name1=name1, id1=id1, name2=name2, id2=id2,
        )
    else:
        if table2[-1:] == "s":
            name2 = table2[:-1] + "_name"
            id2 = table2[:-1] + "_id"
        else:
            name2 = table2 + "_name"
            id2 = table2 + "_id"
        sql = TWO_TABLE_SQL_TEMPLATE.format(
            table1=table1,
            table2=table2,
            table1_col=col1,
            table2_col=col2,
            id1=id1,
            id2=id2,
            name1=name1,
            name2=name2,
        )
    return sql


# sql templates -- one for two different tables, other for self-join

TWO_TABLE_SQL_TEMPLATE = """
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

SELF_JOIN_SQL_TEMPLATE = """
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
