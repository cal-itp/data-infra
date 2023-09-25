"""
Utility functions for geospatial data.
Some functions for dealing with census tract or other geographic unit dfs.
"""
from typing import Literal, Union, cast

import dask.dataframe as dd
import geopandas as gpd  # type: ignore
import pandas as pd
import shapely  # type: ignore

WGS84 = "EPSG:4326"
CA_StatePlane = "EPSG:2229"  # units are in feet
CA_NAD83Albers = "EPSG:3310"  # units are in meters

SQ_MI_PER_SQ_M = 3.86 * 10**-7
FEET_PER_MI = 5_280
SQ_FT_PER_SQ_MI = 2.788 * 10**7


# Laurie's example: https://github.com/cal-itp/data-analyses/blob/752eb5639771cb2cd5f072f70a06effd232f5f22/gtfs_shapes_geo_examples/example_shapes_geo_handling.ipynb
# have to convert to linestring
def make_linestring(x: str) -> shapely.geometry.LineString:
    # shapely errors if the array contains only one point
    if len(x) > 1:
        # each point in the array is wkt
        # so convert them to shapely points via list comprehension
        as_wkt = [shapely.wkt.loads(i) for i in x]
        return shapely.geometry.LineString(as_wkt)


def make_routes_gdf(
    df: pd.DataFrame,
    crs: str = "EPSG:4326",
) -> gpd.GeoDataFrame:
    """
    Parameters:

    crs: str, a projected coordinate reference system.
        Defaults to EPSG:4326 (WGS84)
    """
    # Use apply to use map_partitions
    # https://stackoverflow.com/questions/70829491/dask-map-partitions-meta-when-using-lambda-function-to-add-column
    ddf = dd.from_pandas(df, npartitions=1)

    ddf["geometry"] = ddf.pt_array.apply(make_linestring, meta=("geometry", "geometry"))
    shapes = ddf.compute()

    # convert to geopandas; re-project if needed
    gdf = gpd.GeoDataFrame(
        shapes.drop(columns="pt_array"), geometry="geometry", crs=WGS84
    ).to_crs(crs)

    return gdf


def create_point_geometry(
    df: pd.DataFrame,
    longitude_col: str = "stop_lon",
    latitude_col: str = "stop_lat",
    crs: str = WGS84,
) -> gpd.GeoDataFrame:
    """
    Parameters:
    df: pandas.DataFrame to turn into geopandas.GeoDataFrame,
        default dataframe in mind is gtfs_schedule.stops

    longitude_col: str, column name corresponding to longitude
                    in gtfs_schedule.stops, this column is "stop_lon"

    latitude_col: str, column name corresponding to latitude
                    in gtfs_schedule.stops, this column is "stop_lat"

    crs: str, coordinate reference system for point geometry
    """
    # Default CRS for stop_lon, stop_lat is WGS84
    df = df.assign(
        geometry=gpd.points_from_xy(df[longitude_col], df[latitude_col], crs=WGS84)
    )

    # ALlow projection to different CRS
    gdf = gpd.GeoDataFrame(df).to_crs(crs)

    return gdf


def create_segments(
    geometry: Union[
        shapely.geometry.linestring.LineString,
        shapely.geometry.multilinestring.MultiLineString,
    ],
    segment_distance: int,
) -> gpd.GeoSeries:
    """
    Splits a Shapely LineString into smaller LineStrings.
    If a MultiLineString passed, splits each LineString in that collection.

    Input a geometry column, such as gdf.geometry.

    Double check: segment_distance must be given in the same units as the CRS!
    """
    lines = []

    if hasattr(geometry, "geoms"):  # check if MultiLineString
        linestrings = geometry.geoms
    else:
        linestrings = [geometry]

    for linestring in linestrings:
        for i in range(0, int(linestring.length), segment_distance):
            lines.append(shapely.ops.substring(linestring, i, i + segment_distance))

    return lines


def cut_segments(
    gdf: gpd.GeoDataFrame,
    group_cols: list = ["calitp_itp_id", "calitp_url_number", "route_id"],
    segment_distance: int = 1_000,
) -> gpd.GeoDataFrame:
    """
    Cut segments from linestrings at defined segment lengths.
    Make sure segment distance is defined in the same CRS as the gdf.

    group_cols: list of columns.
                The set of columns that represents how segments should be cut.
                Ex: for transit route, it's calitp_itp_id-calitp_url_number-route_id
                Ex: for highways, it's Route-RouteType-County-District.

    Returns a gpd.GeoDataFrame where each linestring row is now multiple
    rows (each at the pre-defined segment_distance). A new column called
    `segment_sequence` is also created, which differentiates each
    new row created (since they share the same group_cols).
    """
    EPSG_CODE = gdf.crs.to_epsg()

    segmented = gpd.GeoDataFrame()

    gdf = gdf[group_cols + ["geometry"]].drop_duplicates().reset_index(drop=True)

    for row in gdf.itertuples():
        row_geom = getattr(row, "geometry")
        segment = create_segments(row_geom, int(segment_distance))

        to_append = pd.DataFrame()
        to_append["geometry"] = segment
        for c in group_cols:
            to_append[c] = getattr(row, c)

        segmented = pd.concat([segmented, to_append], axis=0, ignore_index=True)

        segmented = segmented.assign(
            temp_index=segmented.sort_values(group_cols).reset_index(drop=True).index
        )

    # Why would there be NaNs?
    # could this be coming from group_cols...one of the cols has a NaN in some rows?
    segmented = segmented[segmented.temp_index.notna()]

    segmented = (
        segmented.assign(
            segment_sequence=(
                segmented.groupby(group_cols)["temp_index"].transform("rank") - 1
            ).astype("int16")
        )
        .sort_values(group_cols)
        .reset_index(drop=True)
        .drop(columns="temp_index")
    )

    segmented2 = gpd.GeoDataFrame(segmented, crs=f"EPSG:{EPSG_CODE}")

    return segmented2


return_options = Literal[
    "point", "line", "polygon", "missing", "linearring", "geometry_collection"
]


def find_geometry_type(
    geometry,
) -> return_options:
    """
    Find the broad geometry type of a geometry value.

    shapely.get_type_id returns integers and differentiates between
    point/multipoint, linestring/multilinestring, etc.
    Sometimes, we just want a broader category.

    https://shapely.readthedocs.io/en/stable/reference/shapely.get_type_id.html
    """
    point_type_ids = [0, 4]
    line_type_ids = [1, 5]
    polygon_type_ids = [3, 6]

    if shapely.get_type_id(geometry) in point_type_ids:
        geo_type = "point"
    elif shapely.get_type_id(geometry) in line_type_ids:
        geo_type = "line"
    elif shapely.get_type_id(geometry) in polygon_type_ids:
        geo_type = "polygon"
    elif shapely.get_type_id(geometry) == -1:
        geo_type = "missing"
    elif shapely.get_type_id(geometry) == 2:
        geo_type = "linearring"
    elif shapely.get_type_id(geometry) == 7:
        geo_type = "geometry_collection"

    return cast(return_options, geo_type)
