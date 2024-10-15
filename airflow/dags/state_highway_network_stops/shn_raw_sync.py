# ---
# python_callable: main
# ---

import logging
from typing import ClassVar, List, Literal, Union

import geopandas as gpd  # type: ignore
import pandas as pd  # type: ignore
import pendulum  # type: ignore
import shapely  # type: ignore

# need this siuba import to do type hint in functions
import siuba  # type: ignore
from calitp_data_analysis.tables import tbls  # type: ignore
from calitp_data_infra.storage import PartitionedGCSArtifact, get_fs  # type: ignore
from siuba import *  # type: ignore

# import os

SPA_MAP_SITE = "https://embeddable-maps.calitp.org/"
SPA_MAP_BUCKET = "calitp-map-tiles/"

unique_stop_cols = ["agency", "stop_id", "stop_name", "route_type", "date"]


CALITP_BUCKET__STATE_HIGHWAY_NETWORK_STOPS = "gs://calitp-state-highway-network-stops"
# CALITP_BUCKET__STATE_HIGHWAY_NETWORK_STOPS = os.environ["CALITP_BUCKET__STATE_HIGHWAY_NETWORK_STOPS"]


def sjoin_shs(stops: gpd.GeoDataFrame, shn):
    stops_on_shn = gpd.sjoin(
        stops,
        shn[["Route", "RouteType", "geometry_buffered"]].set_geometry(
            "geometry_buffered"
        ),
        how="inner",
        predicate="intersects",
    ).drop(columns="index_right")

    print(stops_on_shn[unique_stop_cols].drop_duplicates().shape)
    return stops_on_shn


def process_for_export(stops: gpd.GeoDataFrame):
    # Export / rename columns for clarity / get it as csv so back out lat/lon
    stops_for_export = (
        stops[unique_stop_cols + ["Route", "RouteType", "geometry"]]
        .rename(columns={"Route": "shn_route", "RouteType": "shn_route_type"})
        .drop_duplicates()
        .reset_index(drop=True)
    )

    stops_for_export = stops_for_export.assign(
        x=stops_for_export.geometry.x,
        y=stops_for_export.geometry.y,
    ).drop(columns="geometry")

    return stops_for_export


def schedule_daily_feed_to_gtfs_dataset_name(
    selected_date: Union[str, pendulum.Date],
    keep_cols: list[str] = [],
    get_df: bool = True,
    feed_option: Literal[
        "customer_facing",
        "use_subfeeds",
        "current_feeds",
        "include_precursor",
        "include_precursor_and_future",
    ] = "use_subfeeds",
) -> Union[pd.DataFrame, siuba.sql.verbs.LazyTbl]:
    """
    Select a date, find what feeds are present, and
    merge in organization name

    Analyst would manually include or exclude feeds based on any of the columns.
    Custom filtering doesn't work well, with all the NaNs/Nones/booleans.

    As we move down the options, generally, more rows should be returned.

    * customer_facing: when there are multiple feeds for an organization,
            favor the customer facing one.
            Applies to: Bay Area 511 combined feed favored over subfeeds

    * use_subfeeds: when there are multiple feeds for an organization,
            favor the subfeeds.
            Applies to: Bay Area 511 subfeeds favored over combind feed

    * current_feeds: all current feeds (combined and subfeeds present)

    * include_precursor: include precursor feeds
                Caution: would result in duplicate organization names

    * include_precursor_and_future: include precursor feeds and future feeds.
                Caution: would result in duplicate organization names
    """
    # Get GTFS schedule datasets from Airtable
    dim_gtfs_datasets = filter_dim_gtfs_datasets(
        keep_cols=["key", "name", "type", "regional_feed_type"],
        custom_filtering={"type": ["schedule"]},
        get_df=False,
    )

    # Merge on gtfs_dataset_key to get organization name
    fact_feeds = (
        tbls.mart_gtfs.fct_daily_schedule_feeds()
        >> filter(_.date == selected_date)
        >> inner_join(
            _, dim_gtfs_datasets, on=["gtfs_dataset_key", "gtfs_dataset_name"]
        )
    ) >> rename(name="gtfs_dataset_name")

    if get_df:
        fact_feeds = (
            fact_feeds
            >> collect()
            # apparently order matters - if this is placed before
            # the collect(), it filters out wayyyy too many
            >> filter_feed_options(feed_option)
        )

    return fact_feeds >> subset_cols(keep_cols)


def check_operator_feeds(operator_feeds: list[str]):
    if len(operator_feeds) == 0:
        raise ValueError("Supply list of feed keys or operator names!")


def filter_date(
    selected_date: Union[str, pendulum.Date],
    date_col: Literal["service_date", "activity_date"],
) -> siuba.dply.verbs.Pipeable:
    return filter(_[date_col] == selected_date)


def filter_operator(
    operator_feeds: list, include_name: bool = False
) -> siuba.dply.verbs.Pipeable:
    """
    Filter if operator_list is present.
    For trips table, operator_feeds can be a list of names or feed_keys.
    For stops, shapes, stop_times, operator_feeds can only be a list of feed_keys.
    """
    # in testing, using _.feed_key or _.name came up with a
    # siuba verb not implemented
    # https://github.com/machow/siuba/issues/407
    # put brackets around should work
    if include_name:
        return filter(
            _["feed_key"].isin(operator_feeds) | _["name"].isin(operator_feeds)
        )
    else:
        return filter(_["feed_key"].isin(operator_feeds))


def get_metrolink_feed_key(
    selected_date: Union[str, pendulum.Date], get_df: bool = False
) -> pd.DataFrame:
    """
    Get Metrolink's feed_key value.
    """
    metrolink_in_airtable = filter_dim_gtfs_datasets(
        keep_cols=["key", "name"],
        custom_filtering={"name": ["Metrolink Schedule"]},
        get_df=False,
    )

    metrolink_feed = (
        tbls.mart_gtfs.fct_daily_schedule_feeds()
        >> filter(_.date == selected_date)
        >> inner_join(
            _, metrolink_in_airtable, on=["gtfs_dataset_key", "gtfs_dataset_name"]
        )
        >> rename(name=_.gtfs_dataset_name)
        >> subset_cols(["feed_key", "name"])
        >> collect()
    )

    if get_df:
        return metrolink_feed
    else:
        return metrolink_feed.feed_key.iloc[0]


def filter_dim_gtfs_datasets(
    keep_cols: list[str] = [
        "key",
        "name",
        "type",
        "regional_feed_type",
        "uri",
        "base64_url",
    ],
    custom_filtering: dict = None,
    get_df: bool = True,
) -> Union[pd.DataFrame, siuba.sql.verbs.LazyTbl]:
    """ """
    if "key" not in keep_cols:
        raise KeyError("Include key in keep_cols list")

    dim_gtfs_datasets = (
        tbls.mart_transit_database.dim_gtfs_datasets()
        >> filter(_.data_quality_pipeline == True)  # if True, we can use
        >> filter_custom_col(custom_filtering)
        # >> gtfs_utils_v2.filter_custom_col(custom_filtering)
        >> subset_cols(keep_cols)
        # >> gtfs_utils_v2.subset_cols(keep_cols)
    )

    # rename columns to match our convention
    if "key" in keep_cols:
        dim_gtfs_datasets = dim_gtfs_datasets >> rename(gtfs_dataset_key="key")
    if "name" in keep_cols:
        dim_gtfs_datasets = dim_gtfs_datasets >> rename(gtfs_dataset_name="name")

    if get_df:
        dim_gtfs_datasets = dim_gtfs_datasets >> collect()

    return dim_gtfs_datasets


def filter_custom_col(filter_dict: dict) -> siuba.dply.verbs.Pipeable:
    """
    Unpack the dictionary of custom columns / value to filter on.
    Will unpack up to 5 other conditions...since we now have
    a larger fct_daily_trips table.

    Key: column name
    Value: list with values to keep

    Otherwise, skip.
    """
    if (filter_dict != {}) and (filter_dict is not None):
        keys, values = zip(*filter_dict.items())

        # Accommodate 3 filtering conditions for now
        if len(keys) >= 1:
            filter1 = filter(_[keys[0]].isin(values[0]))
            return filter1

        elif len(keys) >= 2:
            filter2 = filter(_[keys[1]].isin(values[1]))
            return filter1 >> filter2

        elif len(keys) >= 3:
            filter3 = filter(_[keys[2]].isin(values[2]))
            return filter1 >> filter2 >> filter3

        elif len(keys) >= 4:
            filter4 = filter(_[keys[3]].isin(values[3]))
            return filter1 >> filter2 >> filter3 >> filter4

        elif len(keys) >= 5:
            filter5 = filter(_[keys[4]].isin(values[4]))
            return filter1 >> filter2 >> filter3 >> filter4 >> filter5

    elif (filter_dict == {}) or (filter_dict is None):
        return filter()


def subset_cols(cols: list) -> siuba.dply.verbs.Pipeable:
    """
    Select subset of columns, if column list is present.
    Otherwise, skip.
    """
    if cols:
        return select(*cols)
    elif not cols or len(cols) == 0:
        # Can't use select(), because we'll select no columns
        # But, without knowing full list of columns, let's just
        # filter out nothing
        return filter()


def filter_feed_options(
    feed_option: Literal[
        "customer_facing",
        "use_subfeeds",
        "current_feeds",
        "include_precursor",
    ]
) -> siuba.dply.verbs.Pipeable:
    exclude_precursor = filter(_.regional_feed_type != "Regional Precursor Feed")

    if feed_option == "customer_facing":
        return filter(_.regional_feed_type != "Regional Subfeed") >> exclude_precursor

    elif feed_option == "use_subfeeds":
        return (
            filter(
                _["name"] != "Bay Area 511 Regional Schedule"
            )  # keep VCTC combined because the combined feed is the only feed
            >> exclude_precursor
        )

    elif feed_option == "current_feeds":
        return exclude_precursor

    elif feed_option == "include_precursor":
        return filter()
    else:
        return filter()


def get_stops(
    selected_date: Union[str, pendulum.Date],
    operator_feeds: list[str] = [],
    stop_cols: list[str] = [],
    get_df: bool = True,
    crs: str = "EPSG:4326",
    custom_filtering: dict = None,
) -> Union[gpd.GeoDataFrame, siuba.sql.verbs.LazyTbl]:
    """
    Query fct_daily_scheduled_stops.

    Must supply a list of feed_keys or organization names returned from
    schedule_daily_feed_to_gtfs_dataset_name() or subset of those results.
    """
    check_operator_feeds(operator_feeds)

    # If pt_geom is not kept in the final, we still need it
    # to turn this into a gdf
    if (stop_cols) and ("pt_geom" not in stop_cols):
        stop_cols_with_geom = stop_cols + ["pt_geom"]
    else:
        stop_cols_with_geom = stop_cols[:]

    stops = (
        tbls.mart_gtfs.fct_daily_scheduled_stops()
        >> filter_date(selected_date, date_col="service_date")
        >> filter_operator(operator_feeds, include_name=False)
        >> filter_custom_col(custom_filtering)
        >> subset_cols(stop_cols_with_geom)
    )

    if get_df:
        stops = stops >> collect()

        geom = [shapely.wkt.loads(x) for x in stops.pt_geom]

        stops = (
            gpd.GeoDataFrame(stops, geometry=geom, crs="EPSG:4326")
            .to_crs(crs)
            .drop(columns="pt_geom")
        )

        return stops
    else:
        return stops >> subset_cols(stop_cols)


def get_trips(
    selected_date: Union[str, pendulum.Date],
    operator_feeds: list[str] = [],
    trip_cols: list[str] = [],
    get_df: bool = True,
    custom_filtering: dict = None,
) -> Union[pd.DataFrame, siuba.sql.verbs.LazyTbl]:
    """
    Query fct_scheduled_trips

    Must supply a list of feed_keys returned from
    schedule_daily_feed_to_gtfs_dataset_name() or subset of those results.
    """
    check_operator_feeds(operator_feeds)

    trips = (
        tbls.mart_gtfs.fct_scheduled_trips()
        >> filter_date(selected_date, date_col="service_date")
        >> filter_operator(operator_feeds, include_name=True)
        >> filter_custom_col(custom_filtering)
    )

    # subset of columns must happen after Metrolink fix...
    # otherwise, the Metrolink fix may depend on more columns that
    # get subsetted out
    if get_df:
        metrolink_feed_key_name_df = get_metrolink_feed_key(
            selected_date=selected_date, get_df=True
        )
        metrolink_empty = metrolink_feed_key_name_df.empty
        if not metrolink_empty:
            metrolink_feed_key = metrolink_feed_key_name_df.feed_key.iloc[0]
            metrolink_name = metrolink_feed_key_name_df.name.iloc[0]
        else:
            print(f"could not get metrolink feed on {selected_date}!")
        # Handle Metrolink when we need to
        if not metrolink_empty and (
            (metrolink_feed_key in operator_feeds) or (metrolink_name in operator_feeds)
        ):
            metrolink_trips = (
                trips >> filter(_.feed_key == metrolink_feed_key) >> collect()
            )
            not_metrolink_trips = (
                trips >> filter(_.feed_key != metrolink_feed_key) >> collect()
            )

            # Fix Metrolink trips as a pd.DataFrame, then concatenate
            # This means that LazyTbl output will not show correct results
            corrected_metrolink = fill_in_metrolink_trips_df_with_shape_id(
                metrolink_trips, metrolink_feed_key
            )

            trips = pd.concat(
                [not_metrolink_trips, corrected_metrolink], axis=0, ignore_index=True
            )[trip_cols].reset_index(drop=True)

        elif metrolink_empty or (metrolink_feed_key not in operator_feeds):
            trips = trips >> subset_cols(trip_cols) >> collect()

    return trips >> subset_cols(trip_cols)


class StateHighwayNetworkStopsExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CALITP_BUCKET__STATE_HIGHWAY_NETWORK_STOPS
    # bucket: ClassVar[str] = "gs://calitp-state-highway-network-stops"
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]

    @property
    def table(self) -> str:
        return "state_highway_network_stops"


def main():
    extract = StateHighwayNetworkStopsExtract(
        filename="state_highway_network_stops.json"
    )

    shn = gpd.read_parquet(
        "gs://calitp-analytics-data/data-analyses/shared_data/state_highway_network.parquet"
    )

    # 100 ft buffer around SHN
    shn = shn.assign(
        geometry_buffered=(
            shn.geometry.to_crs("EPSG:2229").buffer(100).to_crs("EPSG:4326")
        )
    )

    ca_stops = gpd.read_parquet(
        "gs://calitp-analytics-data/data-analyses/traffic_ops/ca_transit_stops.parquet"
    )

    ca_stops[
        "date"
    ] = "2024-08-14"  # rt_dates.DATES['aug2024'] #  change to match most recent open data upload...

    aug_shs_joined = sjoin_shs(ca_stops, shn=shn)

    # adding SBMTD
    # where'd it go?

    analysis_date = "2024-08-14"  # rt_dates.DATES['aug2024'] #  start with same date as open data run (Aug 14)

    sb = schedule_daily_feed_to_gtfs_dataset_name(selected_date=analysis_date)

    sb = sb >> filter(_.name.str.contains("SB"))

    sb_stops = get_stops(selected_date=analysis_date, operator_feeds=sb.feed_key)

    # ### classic upload with coverage gap (uploaded ~8/14, service in feed starts ~8/19)
    #
    # https://github.com/cal-itp/data-infra/issues/1300

    # ## here it is

    analysis_date = "2024-08-21"

    sb = schedule_daily_feed_to_gtfs_dataset_name(selected_date=analysis_date)
    sb = sb >> filter(_.name.str.contains("SB"))

    sb_stops = get_stops(selected_date=analysis_date, operator_feeds=sb.feed_key)

    sb_trips = get_trips(selected_date=analysis_date, operator_feeds=sb.feed_key)

    sb_trips.empty

    #  lifted from https://github.com/cal-itp/data-analyses/blob/main/open_data/create_stops_data.py
    export_stops_path = (
        "gs://calitp-analytics-data/data-analyses/traffic_ops/export/ca_transit_stops_"
    )

    analysis_date = "2024-07-17"  # rt_dates.DATES['jul2024']

    jul_stops = gpd.read_parquet(
        f"{export_stops_path}{analysis_date}.parquet",
        filters=[("agency", "==", "Santa Barbara Metropolitan Transit District")],
    )

    jul_stops["date"] = analysis_date

    # ## now B-Line

    analysis_date = "2024-03-13"  # rt_dates.DATES['mar2024']

    mar_stops = gpd.read_parquet(
        f"{export_stops_path}{analysis_date}.parquet",
        filters=[("agency", "==", "Butte County Association of Governments")],
    )
    mar_stops["date"] = analysis_date

    # ## now LBT

    analysis_date = "2024-05-22"  # rt_dates.DATES['may2024']

    may_stops = gpd.read_parquet(
        f"{export_stops_path}{analysis_date}.parquet",
        filters=[("agency", "==", "Long Beach Transit")],
    )

    may_stops["date"] = analysis_date

    ## concat and process

    stops_to_add = pd.concat([jul_stops, mar_stops, may_stops])

    additional_shs_joined = sjoin_shs(stops_to_add, shn=shn)

    # new combined export

    all_spatial = pd.concat([aug_shs_joined, additional_shs_joined])

    stops_for_export = process_for_export(all_spatial)

    logging.info(f"Downloaded stop data with {len(stops_for_export)} rows!")

    stop_content = stops_for_export.to_json(orient="records", lines=True).encode()

    extract.save_content(fs=get_fs(), content=stop_content)
