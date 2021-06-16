# TODO: can remove once execute method is implemented
# flake8: noqa

from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults

from calitp import get_engine
from sqlalchemy import sql


class SqlQueryOperator(BaseOperator):
    @apply_defaults
    def __init__(self, sql, **kwargs):
        self.sql = sql

    def execute(self, context):
        engine = get_engine()
        engine.execute(sql.text(self.sql))
