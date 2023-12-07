--- One-time data ingest of 2022 data, whose pattern  which will not be repeated in the future
--- We pull these tables in to use them in later int and fct models
-- TODO: enumerate columns
SELECT -- noqa: AM04
    *
FROM `cal-itp-data-infra.blackcat_raw.2022_rr20_expenses_by_mode`
