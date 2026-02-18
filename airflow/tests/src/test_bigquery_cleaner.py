from src.bigquery_cleaner import BigQueryCleaner


class TestBigQueryCleaner:
    def test_cleaning_a_standard_row(self):
        rows = [{"id": "abc123", "fields": ""}]
        cleaner = BigQueryCleaner(rows)
        assert cleaner.clean() == [{"id": "abc123"}]

    def test_fixing_column_names(self):
        rows = [{"2010": "abc123"}, {" fields ": "green", "@super": "happy"}]
        cleaner = BigQueryCleaner(rows)
        assert cleaner.clean() == [
            {"_2010": "abc123"},
            {"_fields_": "green", "_super": "happy"},
        ]

    def test_cleaning_a_none_value(self):
        rows = [{"id": "abc123", "fields": None}]
        cleaner = BigQueryCleaner(rows)
        assert cleaner.clean() == [{"id": "abc123"}]

    def test_cleaning_numeric_values(self):
        rows = [{"id": 0, "score": -2, "amount": 123.000555555555, "total": 0.5}]
        cleaner = BigQueryCleaner(rows)
        assert cleaner.clean() == [
            {"id": 0, "score": -2, "amount": 123.00055556, "total": 0.5}
        ]
