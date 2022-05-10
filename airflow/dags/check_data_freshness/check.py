# ---
# python_callable: run_check
# provide_context: true
# ---
import re
from datetime import timedelta

import pendulum
from calitp.storage import get_fs
from pydantic import BaseModel, constr

hive_table_regex = r"(?:gs://)?(?P<bucket>[\w-]+)/(?P<table>\w+)/"
# TODO: this should really use removeprefix()
hive_dt_regex = hive_table_regex.replace("gs://", "") + "dt=(?P<dt>[0-9T:-]+)"
hive_hour_regex = hive_dt_regex + r"(?:/[\w-=]+)+/(?P<hour>[0-9]+)"


class FreshnessError(Exception):
    pass


class FreshnessCheck(BaseModel):
    allowable: timedelta


class GCSFreshnessCheck(FreshnessCheck):
    """
    Only usable on hive-partitioned tables with the first partition as a datetime.
    """

    prefix: constr(regex=hive_table_regex + r".*")  # noqa: F722

    def __init__(self, **kwargs):
        print(kwargs)
        super(GCSFreshnessCheck, self).__init__(**kwargs)

    @property
    def latest(self) -> pendulum.DateTime:
        subpaths = get_fs().ls(self.prefix)
        print(subpaths)
        partitions = [re.match(hive_dt_regex, p).group("dt") for p in subpaths]

        return max(pendulum.parse(partition) for partition in partitions)

    def run(self):
        if pendulum.now() - self.allowable < self.latest:
            raise FreshnessError


class BigQueryFreshnessCheck(FreshnessCheck):
    """
    This class is useful for situations where regular dbt source freshness
    does not work well; for example, with massive data sets.
    """

    field: str


def run_check(task_instance, execution_date, **kwargs):
    checks = []

    # RT tables
    checks.extend(
        [
            GCSFreshnessCheck(
                allowable=timedelta(days=1), prefix=f"gs://rt-parsed/{typ}/"
            )
            for typ in ("service_alerts", "trip_updates", "vehicle_positions")
        ]
    )

    for check in checks:
        check.run()


if __name__ == "__main__":
    run_check(None, None)
