from siuba.sql import LazyTbl


class AutoTable:
    def __init__(self, engine, table_formatter=None, table_filter=None):
        self._engine = engine
        self._table_names = self._engine.table_names()

        mappings = {}
        for name in self._table_names:
            if table_filter is not None and not table_filter(name):
                continue

            fmt_name = table_formatter(name)
            if fmt_name in mappings:
                raise Exception("multiple tables w/ formatted name: %s" % fmt_name)
            mappings[fmt_name] = name

        self._attach_mappings(mappings)

    def _attach_mappings(self, mappings):
        for k, v in mappings.items():
            setattr(self, k, self._table_factory(v))

    def _table_factory(self, table_name):
        def loader():
            return self._load_table(table_name)

        return loader

    def _load_table(self, table_name):
        return LazyTbl(self._engine, table_name)


def autotable(engine=None, is_development=None):
    from calitp.sql import get_engine
    from calitp.utils import is_development

    engine = get_engine() if engine is None else engine
    is_development = is_development() if is_development is None else is_development

    def f_filter(s):
        if is_development:
            return "test_" in s and "__staging" not in s

        return "test_" not in s and "__staging" not in s

    tbl = AutoTable(
        engine, lambda s: s.replace(".", "_").replace("test_", ""), f_filter,
    )

    return tbl
