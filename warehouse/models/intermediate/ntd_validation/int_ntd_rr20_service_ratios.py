import logging

import pandas as pd  # noqa: F401
import pyspark  # noqa: F401
import pyspark.sql.functions as F  # noqa: F401


def write_to_log(logfilename):
    """
    Creates a logger object that outputs to a log file, to the filename specified,
    and also streams to console.
    """
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter(
        f"%(asctime)s:%(levelname)s: %(message)s",  # noqa: F541, E231
        datefmt="%y-%m-%d %H:%M:%S",  # noqa: F541, E231
    )
    file_handler = logging.FileHandler(logfilename)
    file_handler.setFormatter(formatter)
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)

    if not logger.hasHandlers():
        logger.addHandler(file_handler)
        logger.addHandler(stream_handler)

    return logger


def make_ratio_cols(df, numerator, denominator, col_name, logger, operation="sum"):
    if col_name is not None:
        # If a user specify a column name, use it
        # Raise error if the column already exists
        if col_name in df.columns:
            logger.info(f"Dataframe already has column '{col_name}'")
            raise ValueError(f"Dataframe already has column '{col_name}'")

        else:
            _col_name = col_name

    if operation == "sum":
        df = df.groupby(["organization", "mode", "fiscal_year"]).apply(
            lambda x: x.assign(
                **{_col_name: lambda x: x[numerator].sum() / x[denominator]}
            )
        )
    # else do not sum the numerator columns
    else:
        df = df.groupby(["organization", "mode", "fiscal_year"]).apply(
            lambda x: x.assign(**{_col_name: lambda x: x[numerator] / x[denominator]})
        )
    return df


def model(dbt, session):
    # Set up the logger object
    logger = write_to_log("rr20_servicechecks_log.log")

    # Load data from BigQuery - pass in the dbt model that we draw from.
    allyears = dbt.ref("int_ntd_rr20_service_alldata")
    allyears = allyears.toPandas()

    # Calculate needed ratios, added as new columns
    numeric_columns = allyears.select_dtypes(include=["number"]).columns
    allyears[numeric_columns] = allyears[numeric_columns].fillna(0)

    allyears = make_ratio_cols(
        allyears, "Total_Annual_Expenses_By_Mode", "Annual_VRH", "cost_per_hr", logger
    )
    allyears = make_ratio_cols(allyears, "Annual_VRM", "VOMX", "miles_per_veh", logger)
    allyears = make_ratio_cols(
        allyears,
        "Total_Annual_Expenses_By_Mode",
        "Annual_UPT",
        "fare_rev_per_trip",
        logger,
    )
    allyears = make_ratio_cols(
        allyears, "Annual_VRM", "Annual_VRH", "rev_speed", logger, operation="mean"
    )
    allyears = make_ratio_cols(
        allyears, "Annual_UPT", "Annual_VRH", "trips_per_hr", logger, operation="mean"
    )

    return allyears
