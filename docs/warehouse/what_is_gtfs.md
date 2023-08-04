(what-is-gtfs)=
# What's GTFS, anyway

Lots of information in the warehouse comes from the General Transit Feed Specification, or GTFS.

## Video Introduction

### [Start by watching this amazing video that Laurie made!](https://www.youtube.com/watch?v=Us6j5GYoLtk)

### Video Notes

* Laurie mentions downloading an example feed to look at the files. This is a great idea! But when working with our data warehouse remember that you don't have to interact with raw GTFS feeds directly (lots of important work has been done for you!). Still, we reccomend taking a look at an example feed to understand what it looks like. Here's one from [Big Blue Bus](http://gtfs.bigbluebus.com/current.zip).
* We don't really use Partridge, but here's a link to their [repo](https://github.com/remix/partridge) in case you want to see where that handy diagram came from. Notice how trips are central to a GTFS feed.
* Ignore references to `calitp_url_number`, `calitp_extracted_at`, or `calitp_deleted_at`. These refer to an older version of our warehouse. Learn about our current data warehouse [here](warehouse-starter-kit-page).
* A "route" is a somewhat ambiguous concept! Transit providers have a lot of flexibility in branding their services. The same route can, and often does, have some trips following one path and some trips following another. GTFS has another concept of a "shape" which describes a path through physical space that one or more trips can follow.

## Further GTFS Resources

* [slides](https://docs.google.com/presentation/d/1fqIeXevb18T5s5k6XPxFbVEMHBPybeV29rFoFXROCw8/) from the video
* [GTFS Specification](https://gtfs.org)