from cloudevents.http.event import CloudEvent
import pytest
from main import handle_cloud_event

class TestGTFSRTArchiver():
  @pytest.fixture
  def cloud_event(self):
    attributes = {
        "specversion": "1.0",
        "id": "test",
        "source": "test",
        "type": "cloud_event",
        "time": "2026-03-03T00:00:00.000000",
    }
    data = {
      "authorization_url_parameter_name": "",
      "authorization_header_parameter_name": "",
      "schedule_to_use_for_rt_validation_gtfs_dataset_key": "",
      "name": "Test Vehicle Positions",
      "pipeline_url": "https://example.com",
      "type": "vehicle_positions",
      "key": "",
      "url_secret_key_name": "",
      "header_secret_key_name": "",
      "source_record_id": "",
    }
    return CloudEvent(attributes, data)

  def test_handle_cloud_event(self, cloud_event: CloudEvent):
    handle_cloud_event(cloud_event=cloud_event)
    assert True == True
