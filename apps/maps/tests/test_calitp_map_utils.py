import pytest
from calitp_map_utils import State

TEST_STATES = [
    {
        "name": "California High Quality Transit Areas - Areas",
        "url": "https://storage.googleapis.com/calitp-map-tiles/ca_hq_transit_areas.geojson.gz",
        "lat_lon": [34.05, -118.25],
        "zoom": 10,
    },
    {
        "name": "California High Quality Transit Areas - Stops",
        "url": "https://storage.googleapis.com/calitp-map-tiles/ca_hq_transit_stops.geojson.gz",
        "lat_lon": [34.05, -118.25],
        "zoom": 15,
    },
    {
        "name": "LA Metro Bus Speed Maps AM Peak",
        "url": "https://storage.googleapis.com/calitp-map-tiles/metro_am.geojson.gz",
        "bbox": [[34.1, -118.5], [33.9, -118]],
    },
]


def test_validate_good_states():
    for state_dict in TEST_STATES:
        state = State(**state_dict)
        state.validate_url(data=True)


def test_validate_invalid_state_url():
    with pytest.raises(FileNotFoundError):
        State(
            name="something",
            url="https://storage.googleapis.com/calitp-map-tiles/THIS_DOES_NOT_EXIST",
        ).validate_url()
