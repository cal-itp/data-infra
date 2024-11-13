import gzip

# import json
import logging
from typing import ClassVar, List  # , Optional

import pandas as pd  # type: ignore
import pendulum
import requests
from calitp_data_infra.storage import PartitionedGCSArtifact, get_fs  # type: ignore
from pydantic import HttpUrl, parse_obj_as

from airflow.models import BaseOperator  # type: ignore

# switch before merge
API_BUCKET = "gs://calitp-state-geoportal-scrape"
# API_BUCKET = os.environ["CALITP_BUCKET__STATE_GEOPORTAL_DATA_PRODUCTS"]


class StateGeoportalAPIExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str]
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]
    root_url: str
    service: str
    product: str
    where: str
    outFields: str
    f: str
    resultRecordCount: int

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
            # Set up the parameters for the request
            url = self.root_url + self.service
            validated_url = parse_obj_as(HttpUrl, url)

            params = {
                "where": self.where,  # You can change this to filter data
                "outFields": self.outFields,  # Specify the fields to return
                "f": self.f,  # Format of the response
                "resultRecordCount": self.resultRecordCount,  # Maximum number of rows per request
            }

            all_features = []  # To store all retrieved rows
            offset = 0

            while True:
                # Update the resultOffset for each request
                params["resultOffset"] = offset

                # Make the request
                response = requests.get(validated_url, params=params)
                # response = requests.get(url, params=params)
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
# break out into own parse operator afterwards, which then reads the raw data in the bucket, and
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
    template_fields = (
        "root_url",
        "service",
        "product",
        "where",
        "outFields",
        "f",
        "resultRecordCount",
    )

    def __init__(
        self,
        root_url,
        service,
        product,
        where,
        outFields,
        f,
        resultRecordCount,
        **kwargs,
    ):
        self.root_url = root_url
        self.service = service
        self.product = product
        self.where = where
        self.outFields = outFields
        self.f = f
        self.resultRecordCount = resultRecordCount

        """An operator that extracts and saves JSON data from the State Geoportal
            and saves it as one JSONL file, hive-partitioned by date in Google Cloud
        """

        # Save JSONL files to the bucket
        self.extract = JSONExtract(
            root_url=self.root_url,
            service=self.service,
            product=f"{self.product}_data",
            where=self.where,
            outFields=self.outFields,
            f=self.f,
            resultRecordCount=self.resultRecordCount,
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
