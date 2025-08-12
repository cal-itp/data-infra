from src.kuba_cleaner import KubaCleaner


class TestKubaCleaner:
    def test_cleaning_a_standard_row(self):
        rows = [{"id": "abc123", "fields": ""}]
        cleaner = KubaCleaner(rows)
        assert cleaner.clean() == [{"id": "abc123"}]

    def test_cleaning_a_nested_row(self):
        rows = [
            {"id": "abc123", "fields": "", "nested": {"other": "", "keys": "jangly"}}
        ]
        rows = [
            {"id": "abc123", "fields": "", "nested": {"other": "", "keys": "jangly"}}
        ]
        cleaner = KubaCleaner(rows)
        assert cleaner.clean() == [{"id": "abc123", "nested": {"keys": "jangly"}}]

    def test_cleaning_a_kuba_json_row(self):
        rows = [{"id": "abc123", "gps::position": '{\\n    "altitude":"31"\\n}'}]
        cleaner = KubaCleaner(rows)
        assert cleaner.clean() == [
            {"id": "abc123", "gps__position": {"altitude": "31"}}
        ]
