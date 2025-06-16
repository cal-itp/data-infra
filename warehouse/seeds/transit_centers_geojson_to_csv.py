"""
This script reads a GeoJSON file containing transit facility data, processes it to standardize column names
and formats, and then exports the relevant data to a CSV file for import as a seed."""
import geopandas as gpd
from shapely.geometry import mapping

geojson_file_path = "data-analyses_ntd_ntd_transit_facilities_facilities_inventory_2025-04-14T22_50_45.496931+00_00.geojson"

gdf = gpd.read_file(geojson_file_path)
gdf.columns = gdf.columns.str.lower().str.replace(" ", "_").str.replace("/", "_")

gdf["geojson_geometry"] = gdf["geometry"].apply(mapping)

columns_to_keep = [
    "ntd_id",
    "agency_name",
    "facility_id",
    "facility_type",
    "facility_name",
    "geometry",
    "geojson_geometry",
]

gdf[columns_to_keep].to_csv(
    "transit_centers.csv", index=True, index_label="id", encoding="utf-8"
)
