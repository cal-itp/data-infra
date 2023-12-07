import logging


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


def model(dbt, session):
    # Set up the logger object
    logger = write_to_log("rr20_servicechecks_log.log")

    # Load data from BigQuery - pass in the dbt model that we draw from.
    allyears = dbt.ref("int_ntd_rr20_service_alldata")
    allyears = allyears.toPandas()
    logger.info("Service data loaded!")

    # Calculate needed ratios, added as new columns
    numeric_columns = allyears.select_dtypes(include=["number"]).columns
    allyears[numeric_columns] = allyears[numeric_columns].fillna(
        value=0, inplace=False, axis=1
    )

    # Cost per hr
    allyears2 = (
        allyears.groupby(["organization", "mode", "fiscal_year"], dropna=False)
        .apply(
            lambda x: x.assign(
                cost_per_hr=x["Total_Annual_Expenses_By_Mode"] / x["Annual_VRH"]
            )
        )
        .reset_index(drop=True)
    )
    # Miles per vehicle
    allyears2 = (
        allyears2.groupby(["organization", "mode", "fiscal_year"], dropna=False)
        .apply(
            lambda x: x.assign(
                miles_per_veh=lambda x: x["Annual_VRM"].sum() / x["VOMX"]
            )
        )
        .reset_index(drop=True)
    )
    # Fare revenues
    allyears2 = (
        allyears2.groupby(["organization", "mode", "fiscal_year"], dropna=False)
        .apply(
            lambda x: x.assign(
                fare_rev_per_trip=lambda x: x["Fare_Revenues"].sum() / x["Annual_UPT"]
            )
        )
        .reset_index(drop=True)
    )
    # Revenue Speed
    allyears2 = (
        allyears2.groupby(["organization", "mode", "fiscal_year"], dropna=False)
        .apply(
            lambda x: x.assign(rev_speed=lambda x: x["Annual_VRM"] / x["Annual_VRH"])
        )
        .reset_index(drop=True)
    )
    # Trips per hr
    allyears2 = (
        allyears2.groupby(["organization", "mode", "fiscal_year"], dropna=False)
        .apply(
            lambda x: x.assign(trips_per_hr=lambda x: x["Annual_UPT"] / x["Annual_VRH"])
        )
        .reset_index(drop=True)
    )

    logger.info("Ratios calculated!")

    return allyears
