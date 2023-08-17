# Wrapper for the MobilityData GTFS Schedule validator

This image exists to faciliate a pod operator executing a Java JAR which validates
GTFS Schedule zipfiles and outputs the resulting notices (i.e. violations). The
JARs in this folder are sourced from https://github.com/MobilityData/gtfs-validator/,
and our Python code automatically selects which version is relevant for an extract.

Note that unlike `gtfs-rt-parser`, this code does NOT include any parsing/unzipping
of the underlying data. The RT code was written prior to substantial changes to
`calitp-py` and therefore bundles together shared functionality that will eventually
live in `calitp-py`.

See [this PR](https://github.com/cal-itp/data-infra/pull/2893) for an example of how
to integrate new versions of the underlying MD-stewarded validator into our validation
process - specifically, changes to [`gtfs_schedule_validator_hourly.py`](https://github.com/cal-itp/data-infra/pull/2893/files#diff-f970d61c9ce49b3899e7b309610f43fca51d29eaae4d5db192208540bc4da702) and
[the `Dockerfile`](https://github.com/cal-itp/data-infra/pull/2893/files#diff-de54f054016ca4e44544d4081d2798a21aa43790c3faea3967f6f5b255529f1a), and the
addition of [a new JAR file](https://github.com/cal-itp/data-infra/pull/2893/files#diff-628dcc44a01286366e42ab8fd440d213d764d8a76f41f268e378a14628e8447c)
corresponding to the new validator version being referenced (taken from the Assets
section at the bottom of [the new validator version's release page](https://github.com/MobilityData/gtfs-validator/releases/tag/v4.1.0)).

In order to respect past validation outcomes, we don't re-validate old data using the latest
available version of the validator. Instead, we use extract dates to determine which
version of the validator was correct to use at the time the data was created. That way,
we don't "punish" older data for not conforming to expectations that changed in the time
since data creation.
