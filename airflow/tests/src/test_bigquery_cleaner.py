from src.bigquery_cleaner import BigQueryCleaner


class TestBigQueryCleaner:
    def test_cleaning_a_standard_row(self):
        rows = [{"id": "abc123", "fields": ""}]
        cleaner = BigQueryCleaner(rows)
        assert cleaner.clean() == [{"id": "abc123", "fields": ""}]

    def test_fixing_column_names(self):
        rows = [{"2010": "abc123"}, {"  fields ": "green", "@super": "happy"}]
        cleaner = BigQueryCleaner(rows)
        assert cleaner.clean() == [
            {"_2010": "abc123"},
            {"__fields_": "green", "_super": "happy"},
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
                "total_amount": "1,123.000555555555",
                "average": "123.000555555555",
                "hours": "5.",
                "ip": "0.0.5",
                "latitude": "33.7561497",
                "longitude": "-117.8676613",
                "latlon": {"type": "Point", "coordinates": [-117.8676613, 33.7561497]},
            }
        ]
        cleaner = BigQueryCleaner(rows)

        # How about this value: "1,123.000555555555"????

        assert cleaner.clean() == [
            {
                "id": 0,
                "score": -2,
                "amount": 123.00055556,
                "total": 0.5,
                "total_amount": "1,123.000555555555",
                "average": 123.00055556,
                "hours": 5.0,
                "ip": "0.0.5",
                "latitude": 33.7561497,
                "longitude": "-117.8676613",
                "latlon": {"type": "Point", "coordinates": [-117.8676613, 33.7561497]},
            }
        ]

    def test_cleaning_nested_columns(self):
        rows = [{"gps::position": {"  altitude": "31.450000000001", " 2010 ": "35"}}]
        cleaner = BigQueryCleaner(rows)
        assert cleaner.clean() == [
            {"gps__position": {"__altitude": 31.45, "_2010_": "35"}}
        ]

    def test_cleaning_arrays(self):
        rows = [
            {
                "counts": [1, 31.450000000001, "31.450000000001"],
                "initials": ["a", "m", "e", "1"],
                "notes": "[2,4,5]",
                "subs": {"trips": [61.540000000001, "y"], "ages": "[2,4,5]"},
            }
        ]

        cleaner = BigQueryCleaner(rows)
        assert cleaner.clean() == [
            {
                "counts": [1, 31.45, "31.450000000001"],
                "initials": ["a", "m", "e", "1"],
                "notes": "[2,4,5]",
                "subs": {"trips": [61.54, "y"], "ages": "[2,4,5]"},
            }
        ]
