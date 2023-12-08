from siuba.sql import LazyTbl  # type: ignore[import]
from sqlalchemy.engine.reflection import Inspector

from .sql import get_engine


class AttributeDict:
    def __init__(self):
        self._d = {}

    def __getattr__(self, k):
        if k in self._d:
            return self._d[k]

        raise AttributeError("No attribute %s" % k)

    def __setitem__(self, k, v):
        self._d[k] = v

    def __dir__(self):
        return list(self._d.keys())


class AutoTable:
    def __init__(self, engine, table_formatter=None, table_filter=None):
        self._engine = engine
        self._table_formatter = table_formatter
        self._table_filter = table_filter
        self._table_names = tuple()
        self._accessors = {}

    def __getattr__(self, k):
        if k in self._accessors:
            return self._accessors[k]

        raise AttributeError("No such attribute %s" % k)

    def __dir__(self):
        return list(self._accessors.keys())

    def _init(self):
        # remove any previously initialized attributes ----
        prev_table_names = self._table_names
        for k in prev_table_names:
            del self.__dict__[k]

        # initialize ----
        insp = Inspector(self._engine)
        self._table_names = tuple(insp.get_table_names()) + tuple(insp.get_view_names())

        mappings = {}
        for name in self._table_names:
            if self._table_filter is not None and not self._table_filter(name):
                continue

            fmt_name = self._table_formatter(name)
            if fmt_name in mappings:
                raise Exception("multiple tables w/ formatted name: %s" % fmt_name)
            mappings[fmt_name] = name

        self._attach_mappings(mappings)

    def _attach_mappings(self, mappings):
        for k, v in mappings.items():
            schema, table = k.split(".")

            if schema not in self._accessors:
                self._accessors[schema] = AttributeDict()

            self._accessors[schema][table] = self._table_factory(v)

    def _table_factory(self, table_name):
        return TableFactory(self._engine, table_name)


class TableFactory:
    def __init__(self, engine, table_name):
        self.engine = engine
        self.table_name = table_name

    def __call__(self):
        return self._create_table()

    def _create_table(self):
        return LazyTbl(self.engine, self.table_name)

    def _row_html(self, col):
        """Return formatted HTML for a single row of the doc table.

        Result will be for a column and its description.
        """

        return f"<tr><td>{col.name}</td><td>{col.type}</td><td>{col.comment}</td></tr>"

    def _repr_html_(self):
        tbl = self._create_table()

        row_html = [self._row_html(col) for col in tbl.tbl.columns]
        table_body_html = "\n".join(row_html)

        return f"""
            <h3> {tbl.tbl.name} </h3>
            <p> {tbl.tbl.comment} </p>
            <table>
                <tr>
                    <th>name</th>
                    <th>type</th>
                    <th>description</th>
                </tr>
                {table_body_html}
            </table>
            """  # noqa: E221,E222


tbls = AutoTable(
    get_engine(),
    lambda s: s,  # s.replace(".", "_"),
)

tbls._init()
