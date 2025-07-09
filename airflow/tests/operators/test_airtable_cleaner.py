from operators.airtable_to_gcs_operator import AirtableCleaner


class TestAirtableCleaner:
    def test_cleaning_a_standard_row(self):
        airtable_rows = [{"id": "abc123", "fields": {"beans": "pinto"}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "beans": "pinto"}]

    def test_cleaning_a_key_with_spaces(self):
        airtable_rows = [{"id": "abc123", "fields": {"taco type": "beans"}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "taco_type": "beans"}]

    def test_cleaning_a_key_with_a_leading_digit(self):
        airtable_rows = [{"id": "abc123", "fields": {"1taco": "nope"}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "_1taco": "nope"}]

    def test_cleaning_a_numeric_key(self):
        airtable_rows = [{"id": "abc123", "fields": {1: "tortilla"}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "_1": "tortilla"}]

    def test_cleaning_a_standard_array(self):
        airtable_rows = [{"id": "abc123", "fields": {"beans": ["pinto", "black"]}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "beans": ["pinto", "black"]}]

    def test_cleaning_a_standard_dict(self):
        airtable_rows = [
            {"id": "abc123", "fields": {"toppings": {"cilantro": "fresh"}}}
        ]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "toppings": {"cilantro": "fresh"}}]

    def test_cleaning_a_string_array_with_none_values(self):
        airtable_rows = [{"id": "abc123", "fields": {"beans": ["pinto", None]}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "beans": ["pinto", ""]}]

    def test_cleaning_a_numeric_array_with_none_values(self):
        airtable_rows = [{"id": "abc123", "fields": {"servings": [1, None, 3]}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "servings": [1, -1, 3]}]

    def test_cleaning_a_dict_with_nested_none_values(self):
        airtable_rows = [
            {
                "id": "abc123",
                "fields": {"daily servings": {"monday": [1, None], "tuesday": [3]}},
            }
        ]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [
            {"id": "abc123", "daily_servings": {"monday": [1, -1], "tuesday": [3]}}
        ]
