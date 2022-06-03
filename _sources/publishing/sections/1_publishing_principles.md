(publishing-principles=)
# Data Publishing Principles

## Follow prior art
The [California Open Data Publisher's Handbook](https://docs.data.ca.gov/california-open-data-publishers-handbook/)
is the inspiration for much of this process. Its sections include a
[pre-publishing checklist (including descriptions of ownership roles)](https://docs.data.ca.gov/california-open-data-publishers-handbook/1.-review-the-pre-publishing-checklist)
and [best practices for creating metadata](https://docs.data.ca.gov/california-open-data-publishers-handbook/3.-create-metadata-and-data-dictionary).

## Assume the data must stand on its own
Once out in the wild, we don't really have much control over how data will
be used or who may rely on it. The documentation should reflect this; we
should include as much information as possible while maintaining
backreferences to the data's source.

## Publish the right amount of data
Pick an appropriate subset of the data to publish, based on volume, expected
usage, and refresh/update frequency. For example, GTFS Schedule is fairly low
volume and slow to change, so updating weekly or monthly is more than
sufficient.
