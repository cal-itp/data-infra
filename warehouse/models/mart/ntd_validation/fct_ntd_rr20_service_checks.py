import pandas as pd
import datetime
import logging

##### TO_DO: see if the missing data check can still work or did we already fill it with zeros

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


def check_rr20_ratios(df, variable, threshold, this_year, last_year, logger):
    '''Validation checks where a ratio must be within a certain threshold limit
    compared to the previous year.'''
    agencies = df['organization'].unique()
    output = []
    for agency in agencies:
        agency_df = df[df['organization']==agency]
        logger.info(f"Checking {agency} for {variable} info.")
        if len(agency_df) > 0:
            
            # Check whether data for both years is present
            if (len(agency_df[agency_df['fiscal_year']==this_year]) > 0) \
                & (len(agency_df[agency_df['fiscal_year']==last_year]) > 0): 

                for mode in agency_df[(agency_df['fiscal_year']==this_year)]['mode'].unique():
                    value_thisyr = (round(agency_df[(agency_df['mode']==mode)
                                          & (agency_df['fiscal_year'] == this_year)]
                                  [variable].unique()[0], 2))
                    if len(agency_df[(agency_df['mode']==mode) & (agency_df['fiscal_year'] == last_year)][variable]) == 0:
                        value_lastyr = 0
                    else:
                        value_lastyr = (round(agency_df[(agency_df['mode']==mode)
                                          & (agency_df['fiscal_year'] == last_year)]
                                  [variable].unique()[0], 2))
                    
                    if (value_lastyr == 0) and (abs(value_thisyr - value_lastyr) >= threshold):
                        result = "fail"
                        check_name = f"{variable}"
                        mode = mode
                        description = (f"The {variable} for {mode} has changed from last year by > = {threshold*100}%, please provide a narrative justification.")
                    elif (value_lastyr != 0) and abs((value_lastyr - value_thisyr)/value_lastyr) >= threshold:
                        result = "fail"
                        check_name = f"{variable}"
                        mode = mode
                        description = (f"The {variable} for {mode} has changed from last year by {round(abs((value_lastyr - value_thisyr)/value_lastyr)*100, 1)}%, please provide a narrative justification.")
                    else:
                        result = "pass"
                        check_name = f"{variable}"
                        mode = mode
                        description = ""

                    output_line = {"Organization": agency,
                                   "name_of_check" : check_name,
                                   "mode": mode,
                                   "value_checked": f"{this_year} = {value_thisyr}, {last_year} = {value_lastyr}",
                                   "check_status": result,
                                   "Description": description}
                    output.append(output_line)
        else:
            logger.info(f"There is no data for {agency}")
    checks = pd.DataFrame(output).sort_values(by="Organization")
    return checks


def check_single_number(df, variable, this_year, last_year, logger, threshold=None,):
    '''Validation checks where a single number must be within a certain threshold limit
    compared to the previous year.'''
    agencies = df['organization'].unique()
    output = []
    for agency in agencies:

        if len(df[df['organization']==agency]) > 0:
            logger.info(f"Checking {agency} for {variable} info.")
            # Check whether data for both years is present, if so perform prior yr comparison.
            if (len(df[(df['organization']==agency) & (df['fiscal_year']==this_year)]) > 0) \
                & (len(df[(df['organization']==agency) & (df['fiscal_year']==last_year)]) > 0): 

                for mode in df[(df['organization'] == agency) & (df['fiscal_year']==this_year)]['mode'].unique():
                    value_thisyr = (round(df[(df['organization'] == agency) 
                                          & (df['mode']==mode)
                                          & (df['fiscal_year'] == this_year)]
                                  [variable].unique()[0], 2))
                    # If there's no data for last yr:
                    if len(df[(df['organization'] == agency) 
                                          & (df['mode']==mode)
                                          & (df['fiscal_year'] == last_year)][variable]) == 0:
                        value_lastyr = 0
                    else:
                        value_lastyr = (round(df[(df['organization'] == agency) 
                                          & (df['mode']==mode)
                                          & (df['fiscal_year'] == last_year)]
                                  [variable].unique()[0], 2))
                    
                    if (round(value_thisyr)==0 and round(value_lastyr) != 0) | (round(value_thisyr)!=0 and round(value_lastyr) == 0):
                        result = "fail"
                        check_name = f"{variable}"
                        mode = mode
                        description = (f"The {variable} for {mode} has changed either from or to zero compared to last year. Please provide a narrative justification.")
                    # run only the above check on whether something changed from zero to non-zero, if no threshold is given
                    elif threshold==None:
                        result = "pass"
                        check_name = f"{variable}"
                        mode = mode
                        description = ""
                        pass
                    # also check for pct change, if a threshold parameter is passed into function
                    elif (value_lastyr == 0) and (abs(value_thisyr - value_lastyr) >= threshold):
                        result = "fail"
                        check_name = f"{variable}"
                        mode = mode
                        description = (f"The {variable} for {mode} was 0 last year and has changed by > = {threshold*100}%, please provide a narrative justification.")
                    elif (value_lastyr != 0) and abs((value_lastyr - value_thisyr)/value_lastyr) >= threshold:
                        result = "fail"
                        check_name = f"{variable}"
                        mode = mode
                        description = (f"The {variable} for {mode} has changed from last year by {round(abs((value_lastyr - value_thisyr)/value_lastyr)*100, 1)}%; please provide a narrative justification.")                        
                    else:
                        result = "pass"
                        check_name = f"{variable}"
                        mode = mode
                        description = ""

                    output_line = {"Organization": agency,
                           "name_of_check" : check_name,
                                   "mode": mode,
                            "value_checked": f"{this_year} = {value_thisyr}, {last_year} = {value_lastyr}",
                            "check_status": result,
                            "Description": description}
                    output.append(output_line)
        else:
            logger.info(f"There is no data for {agency}")
    checks = pd.DataFrame(output).sort_values(by="Organization")
    return checks


def model(dbt, session):
    # Set up the logger object
    logger = write_to_log('rr20_ftc_servicechecks_log.log')

    this_year=datetime.datetime.now().year
    last_year = this_year-1
    this_date=datetime.datetime.now().date().strftime('%Y-%m-%d') #for suffix on Excel files

    #Load data from BigQuery - pass in the dbt model that we draw from.
    allyears = dbt.ref("int_ntd_rr20_service_ratios")
    allyears = allyears.toPandas()

    # Run validation checks
    cph_checks = check_rr20_ratios(allyears, 'cost_per_hr', .30, this_year, last_year, logger)
    mpv_checks = check_rr20_ratios(allyears, 'miles_per_veh', .20, this_year, last_year, logger)
    vrm_checks = check_single_number(allyears, 'Annual_VRM', this_year, last_year, logger, threshold=.30)
    frpt_checks = check_rr20_ratios(allyears, 'fare_rev_per_trip', .25, this_year, last_year, logger)
    rev_speed_checks = check_rr20_ratios(allyears, 'rev_speed', .15, this_year, last_year, logger)
    tph_checks = check_rr20_ratios(allyears, 'trips_per_hr', .30, this_year, last_year, logger)
    voms0_check = check_single_number(allyears, 'VOMX', this_year, last_year, logger)

    # Combine checks into one table
    rr20_checks = pd.concat([cph_checks, mpv_checks, vrm_checks, 
                             frpt_checks, rev_speed_checks, 
                             tph_checks, voms0_check], 
                             ignore_index=True).sort_values(by="Organization")
    
    ## Part 1: save Excel file to GCS
    GCS_FILE_PATH_VALIDATED = f"gs://calitp-ntd-report-validation/validation_reports_{this_year}" 
    with pd.ExcelWriter(f"{GCS_FILE_PATH_VALIDATED}/rr20_service_check_report_{this_date}.xlsx") as writer:
        rr20_checks.to_excel(writer, sheet_name="rr20_checks_full", index=False, startrow=2)

        workbook = writer.book
        worksheet = writer.sheets["rr20_checks_full"]
        cell_highlight = workbook.add_format({
            'fg_color': 'yellow',
            'bold': True,
            'border': 1
        })
        report_title = "NTD Data Validation Report"
        title_format = workbook.add_format({
                'bold': True,
                'valign': 'center',
                'align': 'left',
                'font_color': '#1c639e',
                'font_size': 15
                })
        subtitle = "Reduced Reporting RR-20: Validation Warnings"
        subtitle_format = workbook.add_format({
            'bold': True,
            'align': 'left',
            'font_color': 'black',
            'font_size': 19
            })
        
        worksheet.write('A1', report_title, title_format)
        worksheet.merge_range('A2:C2', subtitle, subtitle_format)
        worksheet.write('G3', 'Agency Response', cell_highlight)
        worksheet.write('H3', 'Response Date', cell_highlight)
        worksheet.set_column(0, 0, 35) #col A width
        worksheet.set_column(1, 3, 22) #cols B-D width
        worksheet.set_column(4, 4, 11) #col D width
        worksheet.set_column(5, 6, 53) #col E-G width
        worksheet.freeze_panes('B4')

    logger.info(f"RR-20 service data checks conducted on {this_date} is complete!")

    ## Part 2: send table to BigQuery
    return rr20_checks

