# Wrapper for the MobilityData GTFS Schedule validator

This image exists to faciliate a pod operator executing a Java JAR which validates
GTFS Schedule zipfiles and outputs the resulting notices (i.e. violations). The
JARs in this folder are sourced from https://github.com/MobilityData/gtfs-validator/,
and our Python code automatically selects which version is relevant for an extract.

Note that unlike `gtfs-rt-parser`, this code does NOT include any parsing/unzipping
of the underlying data. The RT code was written prior to substantial changes to
`calitp-py` and therefore bundles together shared functionality that will eventually
live in `calitp-py`.

See [this PR](https://github.com/cal-itp/data-infra/pull/3238) for an example of how to
integrate new versions of the underlying MD-stewarded validator into our validation
process - note the addition of a new JAR file corresponding to the new validator version
being referenced (taken from the Assets section at the bottom of [the new validator version's release page](https://github.com/MobilityData/gtfs-validator/releases/tag/v4.2.0)),
and a corresponding list of rules and their short descriptions adopted from the canonical
validator [rules list](https://gtfs-validator.mobilitydata.org/rules.html).

In order to respect past validation outcomes, we don't re-validate old data using the latest
available version of the validator. Instead, we use extract dates to determine which
version of the validator was correct to use at the time the data was created. That way,
we don't "punish" older data for not conforming to expectations that changed in the time
since data creation.

## Upgrading the Schedule Validator Version tips
If you run into trouble when adding the new validator jar, it's because the default set for check-added-large-files in our pre-commit config which is a relatively low 500Kb. It's more meant as an alarm for local development than as an enforcement mechanism.
You can make one commit that adds the jar and temporarily adds a higher file size threshold to the pre-commit config [like this one](https://github.com/cal-itp/data-infra/pull/2893/commits/7d40c81f2f5a2622123d4ac5dbbb064eb35565c6) and then a second commit that removes the threshold modification [like this one](https://github.com/cal-itp/data-infra/pull/2893/commits/1ec4e4a1f30ac95b9c0edffcf1f2b12e53e40733). That'll get the file through.

Remember you need to rebuild and push the latest docker file to dhcr before changes will be reflected in airflow runs.

You will need to parse the rules.json from the mobility validator.  [Here is a gist to help](https://gist.github.com/vevetron/7d4bbebd2f1d524728d5349293906e3a).

Here is a command to test
docker-compose run airflow tasks test unzip_and_validate_gtfs_schedule_hourly validate_gtfs_schedule 2024-03-22T18:00:00
