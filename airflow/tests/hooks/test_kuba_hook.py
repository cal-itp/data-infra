import pytest
from hooks.kuba_hook import KubaHook


class TestKubaHook:
    @pytest.fixture
    def hook(self) -> KubaHook:
        return KubaHook(method="GET", http_conn_id="http_kuba")

    @pytest.mark.vcr()
    def test_run(self, hook: KubaHook):
        result = hook.run(
            endpoint="monitoring/deviceproperties/v1/ForLocations/all?location_type=1"
        )
        assert result["Response_date_time"]
        assert len(result["List"]) > 0
        assert list(result["List"][0].keys()) == [
            "Device",
            "Device_replicator_info",
            "Device_monitor_info",
        ]
        assert list(result["List"][0]["Device"].keys()) == [
            "Fo_device_logical_id",
            "Fo_device_type",
            "Fo_device_type_model",
            "Fo_device_serial_number",
            "Fo_device_description",
            "Fo_device_location_id",
            "Fo_device_location",
            "Fo_device_last_connection",
        ]
        assert result["List"][0]["Device"]["Fo_device_logical_id"]
        assert result["List"][0]["Device"]["Fo_device_type"] == "Validator"
