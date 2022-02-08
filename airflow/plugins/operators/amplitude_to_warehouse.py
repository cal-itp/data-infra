"""Module for exporting data from Amplitude and adding to the data warehouse"""
from airflow.models import BaseOperator


def amplitude_to_df():
    """Export data from Amplitude into a dataframe."""


class AmplitudeToWarehouseOperator(BaseOperator):
    """
    An operator that will download data from Amplitude and load it into
    the CalITP data warehouse.
    """

    def __init__(self, **kwargs):
        super().__init__(self, **kwargs)

    def execute(self, context):
        pass
