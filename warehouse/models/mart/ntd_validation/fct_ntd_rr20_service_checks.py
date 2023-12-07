import datetime
import logging

import pandas as pd

# TO_DO: see if the missing data check can still work or did we already fill it with zeros


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


def check_rr20_ratios(df, variable, threshold, this_year, last_year, logger):
    """Validation checks where a ratio must be within a certain threshold limit
    compared to the previous year."""
    agencies = df["organization"].unique()
    output = []
    for agency in agencies:
        agency_df = df[df["organization"] == agency]
        logger.info(f"Checking {agency} for {variable} info.")
        if len(agency_df) > 0:
            # Check whether data for both years is present
            if (len(agency_df[agency_df["fiscal_year"] == this_year]) > 0) & (
                len(agency_df[agency_df["fiscal_year"] == last_year]) > 0
            ):
                for mode in agency_df[(agency_df["fiscal_year"] == this_year)][
                    "mode"
                ].unique():
                    value_thisyr = round(
                        agency_df[
                            (agency_df["mode"] == mode)
                            & (agency_df["fiscal_year"] == this_year)
                        ][variable].unique()[0],
                        2,
                    )
                    if (
                        len(
                            agency_df[
                                (agency_df["mode"] == mode)
                                & (agency_df["fiscal_year"] == last_year)
                            ][variable]
                        )
                        == 0
                    ):
                        value_lastyr = 0
                    else:
                        value_lastyr = round(
                            agency_df[
                                (agency_df["mode"] == mode)
                                & (agency_df["fiscal_year"] == last_year)
                            ][variable].unique()[0],
                            2,
                        )

                    if (value_lastyr == 0) and (
                        abs(value_thisyr - value_lastyr) >= threshold
                    ):
                        result = "fail"
                        check_name = f"{variable}"
                        mode = mode
                        description = f"The {variable} for {mode} has changed from last year by > = {threshold * 100}%, please provide a narrative justification."
                    elif (value_lastyr != 0) and abs(
                        (value_lastyr - value_thisyr) / value_lastyr
                    ) >= threshold:
                        result = "fail"
                        check_name = f"{variable}"
                        mode = mode
                        description = f"The {variable} for {mode} has changed from last year by {round(abs((value_lastyr - value_thisyr) / value_lastyr) * 100, 1)}%, please provide a narrative justification."
                    else:
                        result = "pass"
                        check_name = f"{variable}"
                        mode = mode
                        description = ""

                    output_line = {
                        "Organization": agency,
                        "name_of_check": check_name,
                        "mode": mode,
                        "value_checked": f"{this_year} = {value_thisyr}, {last_year} = {value_lastyr}",
                        "check_status": result,
                        "Description": description,
                    }
                    output.append(output_line)
        else:
            logger.info(f"There is no data for {agency}")
    checks = pd.DataFrame(output).sort_values(by="Organization")
    return checks


def check_single_number(
    df,
    variable,
    this_year,
    last_year,
    logger,
    threshold=None,
):
    """Validation checks where a single number must be within a certain threshold limit
    compared to the previous year."""
    agencies = df["organization"].unique()
    output = []
    for agency in agencies:
        if len(df[df["organization"] == agency]) > 0:
            logger.info(f"Checking {agency} for {variable} info.")
            # Check whether data for both years is present, if so perform prior yr comparison.
            if (
                len(
                    df[
                        (df["organization"] == agency)
                        & (df["fiscal_year"] == this_year)
                    ]
                )
                > 0
            ) & (
                len(
                    df[
                        (df["organization"] == agency)
                        & (df["fiscal_year"] == last_year)
                    ]
                )
                > 0
            ):
                for mode in df[
                    (df["organization"] == agency) & (df["fiscal_year"] == this_year)
                ]["mode"].unique():
                    value_thisyr = round(
                        df[
                            (df["organization"] == agency)
                            & (df["mode"] == mode)
                            & (df["fiscal_year"] == this_year)
                        ][variable].unique()[0],
                        2,
                    )
                    # If there's no data for last yr:
                    if (
                        len(
                            df[
                                (df["organization"] == agency)
                                & (df["mode"] == mode)
                                & (df["fiscal_year"] == last_year)
                            ][variable]
                        )
                        == 0
                    ):
                        value_lastyr = 0
                    else:
                        value_lastyr = round(
                            df[
                                (df["organization"] == agency)
                                & (df["mode"] == mode)
                                & (df["fiscal_year"] == last_year)
                            ][variable].unique()[0],
                            2,
                        )

                    if (round(value_thisyr) == 0 and round(value_lastyr) != 0) | (
                        round(value_thisyr) != 0 and round(value_lastyr) == 0
                    ):
                        result = "fail"
                        check_name = f"{variable}"
                        mode = mode
                        description = f"The {variable} for {mode} has changed either from or to zero compared to last year. Please provide a narrative justification."
                    # run only the above check on whether something changed from zero to non-zero, if no threshold is given
                    elif threshold is None:
                        result = "pass"
                        check_name = f"{variable}"
                        mode = mode
                        description = ""
                        pass
                    # also check for pct change, if a threshold parameter is passed into function
                    elif (value_lastyr == 0) and (
                        abs(value_thisyr - value_lastyr) >= threshold
                    ):
                        result = "fail"
                        check_name = f"{variable}"
                        mode = mode
                        description = f"The {variable} for {mode} was 0 last year and has changed by > = {threshold * 100}%, please provide a narrative justification."
                    elif (value_lastyr != 0) and abs(
                        (value_lastyr - value_thisyr) / value_lastyr
                    ) >= threshold:
                        result = "fail"
                        check_name = f"{variable}"
                        mode = mode
                        description = f"The {variable} for {mode} has changed from last year by {round(abs((value_lastyr - value_thisyr) / value_lastyr) * 100, 1)}%; please provide a narrative justification."  # noqa: E702
                    else:
                        result = "pass"
                        check_name = f"{variable}"
                        mode = mode
                        description = ""

                    output_line = {
                        "Organization": agency,
                        "name_of_check": check_name,
                        "mode": mode,
                        "value_checked": f"{this_year} = {value_thisyr}, {last_year} = {value_lastyr}",
                        "check_status": result,
                        "Description": description,
                    }
                    output.append(output_line)
        else:
            logger.info(f"There is no data for {agency}")
    checks = pd.DataFrame(output).sort_values(by="Organization")
    return checks


def model(dbt, session):
    # Set up the logger object
    logger = write_to_log("rr20_ftc_servicechecks_log.log")

    this_year = datetime.datetime.now().year
    last_year = this_year - 1
    this_date = (
        datetime.datetime.now().date().strftime("%Y-%m-%d")
    )  # for suffix on Excel files

    # Load data from BigQuery - pass in the dbt model that we draw from.
    allyears = dbt.ref("int_ntd_rr20_service_ratios")
    allyears = allyears.toPandas()

    # Run validation checks
    cph_checks = check_rr20_ratios(
        allyears, "cost_per_hr", 0.30, this_year, last_year, logger
    )
    mpv_checks = check_rr20_ratios(
        allyears, "miles_per_veh", 0.20, this_year, last_year, logger
    )
    vrm_checks = check_single_number(
        allyears, "Annual_VRM", this_year, last_year, logger, threshold=0.30
    )
    frpt_checks = check_rr20_ratios(
        allyears, "fare_rev_per_trip", 0.25, this_year, last_year, logger
    )
    rev_speed_checks = check_rr20_ratios(
        allyears, "rev_speed", 0.15, this_year, last_year, logger
    )
    tph_checks = check_rr20_ratios(
        allyears, "trips_per_hr", 0.30, this_year, last_year, logger
    )
    voms0_check = check_single_number(allyears, "VOMX", this_year, last_year, logger)

    # Combine checks into one table
    rr20_checks = pd.concat(
        [
            cph_checks,
            mpv_checks,
            vrm_checks,
            frpt_checks,
            rev_speed_checks,
            tph_checks,
            voms0_check,
        ],
        ignore_index=True,
    ).sort_values(by="Organization")

    logger.info(f"RR-20 service data checks conducted on {this_date} is complete!")

    # Send table to BigQuery
    return rr20_checks
