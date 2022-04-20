"""Macros for Operators"""

import pandas as pd
from calitp.config import is_development

# To add a macro, add its definition in the appropriate section
# And then add it to the dictionary at the bottom of this file

# Is Development ======================================================


def is_development_macro():
    """Make calitp-py's is_development function available via macro"""

    return is_development()


# Payments =============================================================


def sql_enrich_duplicates(schema_tbl, key_columns, order_by_columns):

    partition_keys = ", ".join(key_columns)
    order_keys = ", ".join(order_by_columns)

    return f"""
        WITH

        hashed AS (
            SELECT
                *,
                TO_BASE64(MD5(TO_JSON_STRING(T))) AS calitp_hash,
                _FILE_NAME AS calitp_file_name,
                REGEXP_EXTRACT(
                    _FILE_NAME,
                    '.*/[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}_(.*)_[0-9]{{12}}_.*'
                ) AS calitp_export_account,
                PARSE_DATETIME(
                    '%Y%m%d%H%M',
                    REGEXP_EXTRACT(_FILE_NAME, '.*_([0-9]{{12}})_.*')
                ) AS calitp_export_datetime
            FROM {schema_tbl} T
        ),

        hashed_duped AS (
            SELECT
                *,
                COUNT(*) OVER (partition by calitp_hash) AS calitp_n_dupes,
                COUNT(*) OVER (partition by {partition_keys}) AS calitp_n_dupe_ids,
                ROW_NUMBER()
                  OVER (
                      PARTITION BY {partition_keys}
                      ORDER BY {order_keys}
                  )
                  AS calitp_dupe_number
            FROM hashed

        )

        SELECT * FROM hashed_duped
    """


# Airtable =============================================================

# This is a helper to generate SqlToWarehouse operator tasks
# to create mapping tables for Airtable data


def airtable_mapping_generate_sql(table1, table2, col1, col2):
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
            table=table1,
            col=col1,
            name1=name1,
            id1=id1,
            name2=name2,
            id2=id2,
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

# ACTUALLY DEFINE MACROS =============================================================

# template must be added here to be accessed in dags.py
# key is alias that will be used to reference the template in DAG tasks
# value is name of function template as defined above

data_infra_macros = {
    "sql_enrich_duplicates": sql_enrich_duplicates,
    "sql_airtable_mapping": airtable_mapping_generate_sql,
    "is_development": is_development_macro,
}
