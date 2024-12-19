import gzip
import logging
import os
from typing import ClassVar, List

import pandas as pd  # type: ignore
import pendulum
import requests
from calitp_data_infra.storage import PartitionedGCSArtifact, get_fs  # type: ignore
from pydantic import HttpUrl, parse_obj_as

from airflow.exceptions import AirflowException
from airflow.models import BaseOperator  # type: ignore

API_BUCKET = os.environ["CALITP_BUCKET__STATE_GEOPORTAL_DATA_PRODUCTS"]


class StateGeoportalAPIExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str]
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]

    # The name to be used in the data warehouse to refer to the data
    # product.
    product: str

    # The root of the ArcGIS services. As of Nov 2024, this should
    # be "https://caltrans-gis.dot.ca.gov/arcgis/rest/services/".
    root_url: str

    # The name of the service being requested. In the feature service's
    # URL, this will be everything between the root and "/FeatureServer".
    # Don't include a leading or trailing slash.
    service: str

    # The layer to query. This will usually be "0", so that is the
    # default.
    layer: str = "0"

    # The query filter. By default, all rows will be returned from the
    # service. Refer to the ArcGIS documentation for syntax:
    # https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service-layer/#request-parameters
    where: str = "1=1"

    # A comma-separated list of fields to include in the results. Use
    # "*" (the default) to include all fields.
    outFields: str = "*"

    # The number of records to request for each API call (the operator
    # will request all data from the layer in batches of this size).
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
            url = f"{self.root_url}/{self.service}/FeatureServer/{self.layer}/query"
            validated_url = parse_obj_as(HttpUrl, url)

            params = {
                "where": self.where,
                "outFields": self.outFields,
                "f": "geojson",
                "resultRecordCount": self.resultRecordCount,
            }

            all_features = []  # To store all retrieved rows
            offset = 0

            while True:
                try:
                    # Update the resultOffset for each request
                    params["resultOffset"] = offset

                    # Make the request
                    response = requests.get(validated_url, params=params)
                    response.raise_for_status()  # Raises an HTTPError for bad responses
                    data = response.json()

                    # Break the loop if there are no more features
                    if "features" not in data or not data["features"]:
                        break

                    # Append the retrieved features
                    all_features.extend(data["features"])

                    # Increment the offset
                    offset += params["resultRecordCount"]

                except requests.exceptions.HTTPError as e:
                    logging.error(
                        f"HTTP error in batch request at offset {offset}: {e}"
                    )
                    raise AirflowException(f"HTTP error in geoportal request: {e}")
                except requests.exceptions.RequestException as e:
                    logging.error(f"Request error in batch at offset {offset}: {e}")
                    raise AirflowException(f"Request error in geoportal request: {e}")
                except Exception as e:
                    logging.error(f"Error processing batch at offset {offset}: {e}")
                    raise AirflowException(f"Error processing geoportal batch: {e}")

            if not all_features:
                logging.info(
                    f"There is no data to download for {self.product}. Ending pipeline."
                )
                return None

            logging.info(
                f"Downloaded {self.product} data with {len(all_features)} rows!"
            )
            return all_features

        except Exception as e:
            logging.error(f"Error in geoportal data fetch: {e}")
            raise AirflowException(f"Failed to fetch geoportal data: {e}")


# Function to convert coordinates to WKT format
def to_wkt(geometry_type, coordinates):
    try:
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
            logging.warning(f"Unsupported geometry type: {geometry_type}")
            return None
    except Exception as e:
        logging.error(f"Error converting coordinates to WKT: {e}")
        return None


class JSONExtract(StateGeoportalAPIExtract):
    bucket = API_BUCKET


class StateGeoportalAPIOperator(BaseOperator):
    template_fields = (
        "product",
        "root_url",
        "service",
        "layer",
        "resultRecordCount",
    )

    def __init__(
        self,
        product,
        root_url,
        service,
        layer,
        resultRecordCount,
        **kwargs,
    ):
        self.product = product
        self.root_url = root_url
        self.service = service
        self.layer = layer
        self.resultRecordCount = resultRecordCount

        """An operator that extracts and saves JSON data from the State Geoportal
            and saves it as one JSONL file, hive-partitioned by date in Google Cloud
        """

        # Save JSONL files to the bucket
        self.extract = JSONExtract(
            root_url=self.root_url,
            service=self.service,
            product=f"{self.product}_geodata",
            layer=self.layer,
            resultRecordCount=self.resultRecordCount,
            filename=f"{self.product}_geodata.jsonl.gz",
        )

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        try:
            api_content = self.extract.fetch_from_state_geoportal()
            if api_content is None:
                return None

            try:
                df = pd.json_normalize(api_content)
            except Exception as e:
                logging.error(f"Error normalizing JSON data: {e}")
                raise AirflowException(f"Failed to normalize geoportal data: {e}")

            if self.product == "state_highway_network":
                try:
                    # Select columns to keep, have to be explicit before renaming because there are duplicate values after normalizing
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

                    # Dynamically create a mapping by removing known prefixes
                    columns = {col: col.split(".")[-1] for col in df.columns}

                    # Rename columns using the dynamically created mapping
                    df = df.rename(columns=columns)

                    # Create new column with WKT format
                    df["wkt_coordinates"] = df.apply(
                        lambda row: to_wkt(row["type"], row["coordinates"]), axis=1
                    )
                except Exception as e:
                    logging.error(f"Error processing state highway network data: {e}")
                    raise AirflowException(
                        f"Failed to process state highway network data: {e}"
                    )

            # Compress the DataFrame content and save it
            try:
                self.gzipped_content = gzip.compress(
                    df.to_json(orient="records", lines=True).encode()
                )
                self.extract.save_content(fs=get_fs(), content=self.gzipped_content)
            except Exception as e:
                logging.error(f"Error saving processed data: {e}")
                raise AirflowException(f"Failed to save processed geoportal data: {e}")

        except Exception as e:
            logging.error(f"Error in geoportal operator execution: {e}")
            raise AirflowException(f"Geoportal operator execution failed: {e}")
