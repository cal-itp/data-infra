from calitp_data_infra.storage import get_fs, make_name_bq_safe
from airflow.models import BaseOperator
from pydantic import BaseModel
from typing import Optional
import pandas as pd
import pendulum
import requests
import logging
import gzip
import os
import re

def write_to_log(logfilename):
    '''
    Creates a logger object that outputs to a log file, to the filename specified,
    and also streams to console.
    '''
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter(f'%(asctime)s:%(levelname)s: %(message)s',
                                  datefmt='%y-%m-%d %H:%M:%S')
    file_handler = logging.FileHandler(logfilename)
    file_handler.setFormatter(formatter)
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)

    if not logger.hasHandlers():
        logger.addHandler(file_handler)
        logger.addHandler(stream_handler)

    return logger


class BlackCatApiExtract(BaseModel):
    api_url: str
    form: str
    api_tablename: str
    bq_table_name: str
    data: Optional[pd.DataFrame]
    logger: Optional[logging.Logger]
    extract_time: Optional[pendulum.DateTime]

    logger = write_to_log('load_bc_apidata_output.log')
    extract_time = pendulum.now()
    
    # pydantic doesn't know dataframe type
    # see https://stackoverflow.com/a/69200069
    class Config:
        arbitrary_types_allowed = True
    
    def fetch_from_bc_api(self):
        """Download a BlackCat table as a DataFrame.

        Note that BlackCat API reports have rows structured as follows:
        [{'ReportId': <id>,
        'Organization': <organization>,
        'ReportPeriod': <year>,
        'ReportStatus': <status>,
        'ReportLastModifiedDate': <timestamp>,
        '<table_name>': {'Data': [{colname: value, ...}, {colname: value, ...} ...]}},
        {'ReportId': <id>, ...etc. to the next organization}]

        This function applies renames in the following order.
            1. rename column names from snakecase to names utilizing underscores
            2. rename fields
            3. apply column prefix (to columns not renamed by 1 or 2)
        """
        
        self.logger.info(
            f"Downloading BlackCat data for {self.extract_time.format('YYYY')}_{self.bq_table_name}."
        )
        response = requests.get(self.api_url, verify=False)
        blob = response.json()  
        
        raw_df = pd.json_normalize(blob)
        raw_df['ReportLastModifiedDate'] = raw_df['ReportLastModifiedDate'].astype('datetime64[ns]')

        self.data = raw_df.rename(make_name_bq_safe, axis="columns")
        self.logger.info(
            f"Downloaded {self.extract_time.format('YYYY')}_{self.bq_table_name} data with {len(self.data)} rows!"
        )

    def make_hive_path(self, form: str, bucket: str):
        if not self.extract_time:
            raise ValueError(
                "An extract time must be set before a hive path can be generated."
            )
        bq_form_name = (
            str.lower(form).replace("-", "")
        )
        return os.path.join(
            bucket,
            f"{bq_form_name}_{self.api_tablename}",
            f"dt={self.extract_time.to_date_string()}",
            f"ts={self.extract_time.to_iso8601_string()}",
            f"{bq_form_name}_{self.bq_table_name}.jsonl.gz",
        )

    def save_to_gcs(self, fs, bucket):
        hive_path = self.make_hive_path(self.form, bucket)
        self.logger.info(f"Uploading to GCS at {hive_path}")
        if len(self.data) == 0:
            self.logger.info(f"There is no data for {self.api_tablename}, not saving anything. Pipeline exiting.")
            pass
        else:
            fs.pipe(
                hive_path,
                gzip.compress(self.data.to_json(orient="records", lines=True).encode()),
            )
        return hive_path


class BlackCatApiToGCSOperator2(BaseOperator):
    template_fields = ("bucket",)

    def __init__(
        self,
        bucket,
        api_url,
        form,
        api_tablename,
        bq_table_name,
        **kwargs,
    ):
        """An operator that downloads all data from a BlackCat API
            and saves it as one JSON file hive-partitioned by date in Google Cloud
            Storage (GCS). Each org's data will be in 1 row, and for each separate table in the API, 
            a nested column will hold all of it's data. 

        Args:
            bucket (str): GCS bucket where the scraped BlackCat report will be saved.
            api_url (str): The URL to hit that gets the data.
            api_tablename (str): The table that should be extracted from the BlackCat API. 
                MUST MATCH THE API JSON EXACTLY
            bq_table_name (str): The table name that will be given in BigQuery. Appears in the GCS bucket path and the filename.
            form: the NTD form that this report belongs to. E.g., RR-20, A-10, etc.                
        """
        self.bucket = bucket
        # Instantiating an instance of the BlackCatApiExtract()
        self.extract = BlackCatApiExtract(
            api_url=api_url,
            form=form,
            api_tablename=api_tablename,
            bq_table_name=bq_table_name,
        )

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        fs = get_fs()
        self.extract.fetch_from_bc_api()
        # inserts into xcoms
        return self.extract.save_to_gcs(fs, self.bucket)
