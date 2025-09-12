from src.bigquery_cleaner import BigQueryCleaner


class TestBigQueryCleaner:
    def test_cleaning_a_standard_row(self):
        rows = [{"id": "abc123", "fields": ""}]
        cleaner = BigQueryCleaner(rows)
        assert cleaner.clean() == [{"id": "abc123", "fields": ""}]

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
        assert cleaner.clean() == [{"id": "abc123", "fields": None}]

    def test_cleaning_numeric_values(self):
        rows = [
            {
                "id": 0,
                "score": -2,
                "amount": 123.000555555555,
                "total": 0.5,
                "total_amount": "123.000555555555",
                "hours": "5.",
            }
        ]
        cleaner = BigQueryCleaner(rows)
        print(cleaner.clean())
        assert cleaner.clean() == [
            {
                "id": 0,
                "score": -2,
                "amount": 123.00055556,
                "total": 0.5,
                "total_amount": 123.00055556,
                "hours": 5.0,
            }
        ]

    def test_cleaning_nested_columns(self):
        rows = [{"gps::position": {" altitude": "31.4567890004400", " 2010 ": "31"}}]
        cleaner = BigQueryCleaner(rows)
        print(cleaner.clean())
        assert cleaner.clean() == [
            {"gps__position": {" altitude": "31.4567891", "_2010_": "31"}}
        ]
