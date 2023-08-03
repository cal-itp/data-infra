"""
This file imports within each test so we can test with different environment variables.
"""

import pytest
from calitp_map_utils import Layer, State
from requests.exceptions import HTTPError

TEST_STATES = [
    {
        "layers": [
            {
                "name": "California High Quality Transit Areas - Areas",
                "url": "https://storage.googleapis.com/calitp-map-tiles/ca_hq_transit_areas.geojson.gz",
            },
        ],
        "lat_lon": [34.05, -118.25],
        "zoom": 10,
    },
    {
        "layers": [
            {
                "name": "California High Quality Transit Areas - Stops",
                "url": "https://storage.googleapis.com/calitp-map-tiles/ca_hq_transit_stops.geojson.gz",
            }
        ],
        "lat_lon": [34.05, -118.25],
        "zoom": 15,
        "basemap_config": {
            "url": "https://{s}.basemaps.cartocdn.com/{variant}/{z}/{x}/{y}{r}.png",
            "options": {
                "attribution": '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
                "subdomains": "abcd",
                "maxZoom": 20,
                "variant": "light_all",
            },
        },
    },
    {
        "layers": [
            {
                "name": "D7 State Highway Network",
                "url": "https://storage.googleapis.com/calitp-map-tiles/d7_shn.geojson.gz",
                "type": "state_highway_network",
            },
            {
                "name": "LA Metro Bus Speed Maps AM Peak",
                "url": "https://storage.googleapis.com/calitp-map-tiles/metro_am.geojson.gz",
                "type": "speedmap",
            },
        ],
        "bbox": [[34.1, -118.5], [33.9, -118]],
        "basemap_config": {
            "url": "https://{s}.basemaps.cartocdn.com/{variant}/{z}/{x}/{y}{r}.png",
            "options": {
                "attribution": '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
                "subdomains": "abcd",
                "maxZoom": 20,
                "variant": "dark_all",
            },
        },
    },
]


@pytest.mark.slow
def test_good_states_validate_layers():
    for state_dict in TEST_STATES:
        state = State(**state_dict)
        state.validate_layers(data=True)


def test_invalid_layers_throw_exception():
    with pytest.raises(HTTPError):
        State(
            layers=[
                Layer(
                    name="something",
                    url="https://storage.googleapis.com/calitp-map-tiles/THIS_DOES_NOT_EXIST",
                )
            ]
        ).validate_layers()


def test_iframe_url_works_with_env_var():
    with pytest.MonkeyPatch.context() as mp:
        mp.setattr("calitp_map_utils.MAP_APP_URL", "https://some.domain")

        assert "some.domain" in State(**TEST_STATES[0]).iframe_url()


def test_iframe_url_missing_env_throws_exception(monkeypatch):
    with pytest.MonkeyPatch.context() as mp:
        mp.setattr("calitp_map_utils.MAP_APP_URL", None)

        with pytest.raises(RuntimeError):
            _ = State(**TEST_STATES[0]).iframe_url()
