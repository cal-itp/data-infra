# ---
# python_callable: run_check
# provide_context: true
# ---
import re
import sys
from datetime import timedelta

import pendulum
from calitp.storage import get_fs
from pydantic import BaseModel, constr
from pydantic.dataclasses import dataclass
from tabulate import tabulate

hive_table_regex = r"(?:gs://)?(?P<bucket>[\w-]+)/(?P<table>\w+)/"
# TODO: this should really use removeprefix()
hive_dt_regex = hive_table_regex.replace("gs://", "") + "dt=(?P<dt>[0-9T:-]+)"
hive_hour_regex = hive_dt_regex + r"(?:/[\w-=]+)+/(?P<hour>[0-9]+)"


class FreshnessCheck(BaseModel):
    allowable: timedelta

    @property
    def entity(self):
        raise NotImplementedError

    @property
    def age(self):
        raise NotImplementedError


class GCSFreshnessCheck(FreshnessCheck):
    """
    Only usable on hive-partitioned tables with the first partition as a datetime.
    """

    prefix: constr(regex=hive_table_regex + r".*")  # noqa: F722

    def __init__(self, **kwargs):
        super(GCSFreshnessCheck, self).__init__(**kwargs)

    @property
    def entity(self):
        return self.prefix

    # TODO: use cached_property when we upgrade python enough
    @property
    def age(self) -> timedelta:
        subpaths = get_fs().ls(self.prefix)
        partitions = [re.match(hive_dt_regex, p).group("dt") for p in subpaths]

        return pendulum.now() - max(
            pendulum.parse(partition) for partition in partitions
        )

    def run(self):
        if self.age > self.allowable:
            raise FreshnessError(self)


class BigQueryFreshnessCheck(FreshnessCheck):
    """
    This class is useful for situations where regular dbt source freshness
    does not work well; for example, with massive data sets.
    """

    table: str
    field: str

    @property
    def entity(self):
        return f"{self.table}.{self.field}"


@dataclass
class FreshnessError(Exception):
    check: FreshnessCheck

    def __str__(self):
        return f"FreshnessError: {self.check.entity} is {self.check.age} old"

    def __iter__(self):
        yield self.check.entity
        yield self.check.age.in_words()


def run_check(task_instance, execution_date, **kwargs):
    checks = []

    # RT tables
    checks.extend(
        GCSFreshnessCheck(allowable=timedelta(days=1), prefix=f"gs://rt-parsed/{typ}/")
        for typ in ("service_alerts", "trip_updates", "vehicle_positions")
    )

    errors = []

    for check in checks:
        try:
            check.run()
        except FreshnessError as e:
            errors.append(e)

    if errors:
        print(f"{len(errors)} freshness checks failed")
        print(tabulate(errors, headers=("entity", "age")))
        sys.exit(1)


if __name__ == "__main__":
    run_check(None, None)
