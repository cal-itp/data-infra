from typing import Dict

from airflow.hooks.base import BaseHook
from airflow.hooks.http_hook import HttpHook

TRANSITLAND_FEED_FLAVORS: Dict[str, str] = {
    "gbfs_auto_discovery": "general_bikeshare_feed_specification",
    "mds_provider": "mobility_data_specification",
    "realtime_alerts": "service_alerts",
    "realtime_trip_updates": "trip_updates",
    "realtime_vehicle_positions": "vehicle_positions",
    "static_current": "schedule",
    "static_historic": "schedule",
    "static_planned": "schedule",
}


class TransitlandPage:
    _results: dict

    def __init__(self, results: dict) -> None:
        self._results: dict = results

    def after(self) -> str | None:
        if "meta" in self._results and "after" in self._results["meta"]:
            return self._results["meta"]["after"]
        return None

    def rows(self) -> list:
        rows = []
        for feed in self._results["feeds"]:
            for flavor, urls in feed["urls"].items():
                for i, url in enumerate([urls] if isinstance(urls, str) else urls):
                    rows.append(
                        {
                            "key": f"{feed['id']}_{flavor}_{i}",
                            "name": feed["name"],
                            "feed_url_str": url,
                            "feed_type": TRANSITLAND_FEED_FLAVORS[flavor],
                            "raw_record": {flavor: urls},
                        }
                    )
        return rows


class TransitlandHook(BaseHook):
    _http_hook: HttpHook

    def __init__(self, conn_id: str = "http_transitland"):
        super().__init__()
        self._http_hook: HttpHook = HttpHook(method="GET", http_conn_id=conn_id)

    def run(self, pages: int, parameters: dict) -> HttpHook:
        data = parameters.copy()
        rows = []
        for _ in range(0, pages):
            results = self._http_hook.run(data=data).json()
            page = TransitlandPage(results=results)
            rows.extend(page.rows())
            if not page.after():
                break
            data["after"] = page.after()
        return rows
