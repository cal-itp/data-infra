import gzip

# import json
import logging
from typing import ClassVar, List  # , Optional

import pandas as pd  # type: ignore
import pendulum
import requests
from calitp_data_infra.storage import PartitionedGCSArtifact, get_fs  # type: ignore

from airflow.models import BaseOperator  # type: ignore

# from pydantic import HttpUrl, parse_obj_as

API_BUCKET = "gs://calitp-state-geoportal-scrape"
# API_BUCKET = os.environ["CALITP_BUCKET__STATE_GEOPORTAL_DATA_PRODUCTS"]


class StateGeoportalAPIExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str]
    product: str
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    root_url: str
    endpoint_id: str
    query: str
    file_format: str
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]

    @property
    def table(self) -> str:
        return self.product

    @property
    def filename(self) -> str:
        return self.table

    class Config:
        arbitrary_types_allowed = True

    def fetch_from_state_geoportal(self):
        """ """

        logging.info(f"Downloading state geoportal data for {self.product}.")

        try:
            # url = self.root_url + self.endpoint_id + self.query + self.file_format

            # validated_url = parse_obj_as(HttpUrl, url)

            # response = requests.get(validated_url).content

            # Set up the parameters for the request
            url = "https://caltrans-gis.dot.ca.gov/arcgis/rest/services/CHhighway/SHN_Lines/FeatureServer/0/query"
            params = {
                "where": "1=1",  # You can change this to filter data
                "outFields": "*",  # Specify the fields to return
                "f": "geojson",  # Format of the response
                "resultRecordCount": 2000,  # Maximum number of rows per request
            }

            all_features = []  # To store all retrieved rows
            offset = 0

            while True:
                # Update the resultOffset for each request
                params["resultOffset"] = offset

                # Make the request
                response = requests.get(url, params=params)
                data = response.json()

                # Break the loop if there are no more features
                if "features" not in data or not data["features"]:
                    break

                # Append the retrieved features
                all_features.extend(data["features"])

                # Increment the offset
                offset += params["resultRecordCount"]

            if all_features is None or len(all_features) == 0:
                logging.info(
                    f"There is no data to download for {self.product}. Ending pipeline."
                )

                pass
            else:
                logging.info(
                    f"Downloaded {self.product} data with {len(all_features)} rows!"
                )

                return all_features

        except requests.exceptions.RequestException as e:
            logging.info(f"An error occurred: {e}")

            raise


# # Function to convert coordinates to WKT format
def to_wkt(geometry_type, coordinates):
    if geometry_type == "LineString":
        # Format as a LineString
        coords_str = ", ".join([f"{lng} {lat}" for lng, lat in coordinates])
        return f"LINESTRING({coords_str})"
    elif geometry_type == "MultiLineString":
        # Format as a MultiLineString
        multiline_coords_str = ", ".join(
            f"({', '.join([f'{lng} {lat}' for lng, lat in line])})"
            for line in coordinates
        )
        return f"MULTILINESTRING({multiline_coords_str})"
    else:
        return None


class JSONExtract(StateGeoportalAPIExtract):
    bucket = API_BUCKET


class StateGeoportalAPIOperator(BaseOperator):
    template_fields = ("product", "root_url", "endpoint_id", "query", "file_format")

    def __init__(
        self,
        product,
        root_url,
        endpoint_id,
        query,
        file_format,
        **kwargs,
    ):
        self.product = product
        self.root_url = root_url
        self.endpoint_id = endpoint_id
        self.query = query
        self.file_format = file_format

        """An operator that extracts and saves JSON data from the State Geoportal
            and saves it as one JSONL file, hive-partitioned by date in Google Cloud
        """

        # Save JSONL files to the bucket
        self.extract = JSONExtract(
            product=f"{self.product}_data",
            root_url=self.root_url,
            endpoint_id=self.endpoint_id,
            query=self.query,
            file_format=self.file_format,
            filename=f"{self.product}_stops.jsonl.gz",
        )

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        api_content = self.extract.fetch_from_state_geoportal()

        df = pd.json_normalize(api_content)

        df = df[
            [
                "properties.Route",
                "properties.County",
                "properties.District",
                "properties.RouteType",
                "properties.Direction",
                "geometry.type",
                "geometry.coordinates",
            ]
        ]

        df = df.rename(
            columns={
                "properties.Route": "Route",
                "properties.County": "County",
                "properties.District": "District",
                "properties.RouteType": "RouteType",
                "properties.Direction": "Direction",
                "geometry.type": "type",
                "geometry.coordinates": "coordinates",
            }
        )

        # Apply function to create new column with WKT format
        df["wkt_coordinates"] = df.apply(
            lambda row: to_wkt(row["type"], row["coordinates"]), axis=1
        )

        df = df[
            [
                "Route",
                "County",
                "District",
                "RouteType",
                "Direction",
                "wkt_coordinates",
            ]
        ]

        self.gzipped_content = gzip.compress(
            df.to_json(orient="records", lines=True).encode()
        )

        self.extract.save_content(fs=get_fs(), content=self.gzipped_content)
