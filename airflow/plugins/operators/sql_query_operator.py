# TODO: can remove once execute method is implemented
# flake8: noqa

from airflow.models import BaseOperator
from calitp import get_engine
from sqlalchemy import sql


class SqlQueryOperator(BaseOperator):

    template_fields = ("sql",)

    def __init__(self, sql, post_hooks=[], **kwargs):
        super().__init__(**kwargs)

        self.sql = sql
        self.post_hooks = post_hooks

    def execute(self, context):
        engine = get_engine()

        print(f"{engine}\n{self.sql}")
        engine.execute(sql.text(self.sql))

        for hook in self.post_hooks:
            print(f"{engine}\n{hook}")
            engine.execute(sql.text(hook))
