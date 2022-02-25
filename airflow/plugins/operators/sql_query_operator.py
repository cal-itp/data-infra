# TODO: can remove once execute method is implemented
# flake8: noqa

from airflow.models import BaseOperator
from calitp import get_engine
from sqlalchemy import sql


class SqlQueryOperator(BaseOperator):

    template_fields = ("sql",)

    def __init__(self, sql, **kwargs):
        super().__init__(**kwargs)

        self.sql = sql

    def execute(self, context):
        engine = get_engine()

        print(f"{engine}\n{self.sql}")
        engine.execute(sql.text(self.sql))
