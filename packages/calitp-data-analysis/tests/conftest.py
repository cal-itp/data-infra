import uuid

import pytest
from calitp_data_analysis.sql import get_engine, get_table

CI_SCHEMA_NAME = "calitp_py"


@pytest.fixture
def engine():
    yield get_engine(project="cal-itp-data-infra-staging")


@pytest.fixture
def tmp_name():
    from sqlalchemy.exc import NoSuchTableError

    # Code that runs before test ----
    # generate a random table name. ensure it does not start with a number.
    table_name = "t_" + str(uuid.uuid4()).replace("-", "_")
    schema_table = f"{CI_SCHEMA_NAME}.{table_name}"

    # pass the name of the temporary table into the test
    yield schema_table

    # Code that runs after test ----
    # delete table corresponding to temporary name, if it exists
    try:
        tbl = get_table(schema_table)
        tbl.drop()
    except NoSuchTableError:
        pass
