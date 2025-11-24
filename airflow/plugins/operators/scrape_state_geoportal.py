import gzip
import logging
import os
from typing import Any, ClassVar, Dict, List, Optional

import pandas as pd  # type: ignore
import pendulum
import requests
from calitp_data_infra.storage import PartitionedGCSArtifact, get_fs  # type: ignore
from pydantic.v1 import HttpUrl, parse_obj_as

from airflow.exceptions import AirflowException
from airflow.models import BaseOperator  # type: ignore

API_BUCKET = os.environ["CALITP_BUCKET__STATE_GEOPORTAL_DATA_PRODUCTS"]


class StateGeoportalAPIExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str]
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]

    # The name to be used in the data warehouse to refer to the data product.
    product: str

    # The root of the ArcGIS services.
    root_url: str

    # The name of the service being requested.
    service: str

    # The layer to query. This will usually be "0".
    layer: str = "0"

    # The query filter. By default, all rows will be returned.
    where: str = "1=1"

    # A comma-separated list of fields to include in the results.
    outFields: str = "*"

    # The number of records to request for each API call.
    resultRecordCount: int

    @property
    def table(self) -> str:
        return self.product

    @property
    def filename(self) -> str:
        return self.table

    class Config:
        arbitrary_types_allowed = True

    def _make_api_request(self, url: str, params: Dict[str, Any], offset: int) -> Dict:
        """Make API request with proper error handling."""
        try:
            params["resultOffset"] = offset
            response = requests.get(url, params=params)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            logging.error(f"HTTP error in batch request at offset {offset}: {e}")
            raise AirflowException(f"HTTP error in geoportal request: {e}")
        except requests.exceptions.RequestException as e:
            logging.error(f"Request error in batch at offset {offset}: {e}")
            raise AirflowException(f"Request error in geoportal request: {e}")
        except Exception as e:
            logging.error(f"Error processing batch at offset {offset}: {e}")
            raise AirflowException(f"Error processing geoportal batch: {e}")

    def _validate_features(self, data: Dict, offset: int) -> Optional[List]:
        """Validate features from API response."""
        if "features" not in data or not data["features"]:
            if offset == 0:
                logging.info(
                    f"There is no data to download for {self.product}. Ending pipeline."
                )
            return None
        return data["features"]

    def fetch_from_state_geoportal(self) -> Optional[List]:
        """Fetch data from state geoportal with proper error handling."""
        try:
            # Set up the request URL and parameters
            url = f"{self.root_url}/{self.service}/FeatureServer/{self.layer}/query"
            validated_url = parse_obj_as(HttpUrl, url)

            params = {
                "where": self.where,
                "outFields": self.outFields,
                "f": "geojson",
                "resultRecordCount": self.resultRecordCount,
            }

            all_features = []
            offset = 0

            while True:
                # Make API request for current batch
                data = self._make_api_request(validated_url, params, offset)

                # Validate and process features
                features = self._validate_features(data, offset)
                if features is None:
                    break

                all_features.extend(features)
                offset += params["resultRecordCount"]

            if not all_features:
                return None

            logging.info(
                f"Downloaded {self.product} data with {len(all_features)} rows!"
            )
            return all_features

        except AirflowException:
            # Re-raise AirflowExceptions as they already have proper error messages
            raise
        except Exception as e:
            logging.error(f"Error in geoportal data fetch: {e}")
            raise AirflowException(f"Failed to fetch geoportal data: {e}")


def to_wkt(geometry_type: str, coordinates: List) -> Optional[str]:
    """Convert coordinates to WKT format with proper error handling."""
    try:
        if geometry_type == "LineString":
            coords_str = ", ".join([f"{lng} {lat}" for lng, lat in coordinates])
            return f"LINESTRING({coords_str})"
        elif geometry_type == "MultiLineString":
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
        product: str,
        root_url: str,
        service: str,
        layer: str,
        resultRecordCount: int,
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

    def _normalize_json_data(self, api_content: List) -> pd.DataFrame:
        """Normalize JSON data with proper error handling."""
        try:
            return pd.json_normalize(api_content)
        except Exception as e:
            logging.error(f"Error normalizing JSON data: {e}")
            raise AirflowException(f"Failed to normalize geoportal data: {e}")

    def _process_highway_network(self, df: pd.DataFrame) -> pd.DataFrame:
        """Process state highway network data with proper error handling."""
        try:
            # Select columns to keep
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

            # Create dynamic column mapping
            columns = {col: col.split(".")[-1] for col in df.columns}
            df = df.rename(columns=columns)

            # Create WKT coordinates
            df["wkt_coordinates"] = df.apply(
                lambda row: to_wkt(row["type"], row["coordinates"]), axis=1
            )
            return df
        except Exception as e:
            logging.error(f"Error processing state highway network data: {e}")
            raise AirflowException(f"Failed to process state highway network data: {e}")

    def _save_dataframe(self, df: pd.DataFrame) -> None:
        """Save DataFrame as compressed JSONL with proper error handling."""
        try:
            gzipped_content = gzip.compress(
                df.to_json(orient="records", lines=True).encode()
            )
            self.extract.save_content(fs=get_fs(), content=gzipped_content)
        except Exception as e:
            logging.error(f"Error saving processed data: {e}")
            raise AirflowException(f"Failed to save processed geoportal data: {e}")

    def execute(self, **kwargs) -> None:
        """Execute the operator with proper error handling."""
        try:
            # Fetch API content
            api_content = self.extract.fetch_from_state_geoportal()
            if api_content is None:
                return None

            # Normalize JSON data
            df = self._normalize_json_data(api_content)

            # Process state highway network if applicable
            if self.product == "state_highway_network":
                df = self._process_highway_network(df)

            # Save processed data
            self._save_dataframe(df)

        except AirflowException:
            # Re-raise AirflowExceptions as they already have proper error messages
            raise
        except Exception as e:
            logging.error(f"Error in geoportal operator execution: {e}")
            raise AirflowException(f"Geoportal operator execution failed: {e}")
