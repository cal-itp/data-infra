# Getting Notebooks Ready for the Portfolio

## Narrative

- Narrative content can be done in Markdown cells or code cells.
  - Markdown cells should be used when there are no variables to inject.
  - Code cells should be used to write narrative whenever variables constructed from f-strings are used.
- For `papermill`, add a [parameters tag to the code cell](https://papermill.readthedocs.io/en/latest/usage-parameterize.html)
  Note: Our portfolio uses a custom `papermill` engine and we can skip this step.
- Markdown cells can inject f-strings if it's plain Markdown (not a heading) using `display(Markdown())` in a code cell.

```
from IPython.display import Markdown

display(Markdown(f"The value of {variable} is {value}."))
```

- **Use f-strings to fill in variables and values instead of hard-coding them**
  - Turn anything that runs in a loop or relies on a function into a variable.
  - Use functions to grab those values for a specific entity (operator, district), rather than hard-coding the values into the narrative.

```
n_routes = (df[df.calitp_itp_id == itp_id]
            .route_id.nunique()
            )


n_parallel = (df[
            (df.calitp_itp_id == itp_id) &
            (df.parallel==1)]
            .route_id.nunique()
            )

display(
    Markdown(
        f"**Bus routes in service: {n_routes}**"
        "<br>**Parallel routes** to State Highway Network (SHN): "
        f"**{n_parallel} routes**"
        )
)
```

- Stay away from loops if you need to use headers.
  - You will need to create Markdown cells for headers or else JupyterBook will not build correctly. For parameterized notebooks, this is an acceptable trade-off.
  - For unparameterized notebooks, you may want use `display(HTML())`.
  - Caveat: Using `display(HTML())` means you'll lose the table of contents navigation in the top right corner in the JupyterBook build.

## Writing Guide

These are a set of principles to adhere to when writing the narrative content in a Jupyter Notebook. Use your best judgment to decide when there are exceptions to these principles.

- Decimals less than 1, always prefix with a 0, for readability.

  - 0.05, not .05

- Integers when referencing dates, times, etc

  - 2020 for year, not 2020.0 (coerce to int64 or Int64 in `pandas`; Int64 are nullable integers, which allow for NaNs to appear alongside integers)
  - 1 hr 20 min, not 1.33 hr (use best judgment to decide what's easier for readers to interpret)

- Round at the end of the analysis. Use best judgment to decide on significant digits.

  - Too many decimal places give an air of precision that may not be present.
  - Too few decimal places may not give enough detail to distinguish between categories or ranges.
  - A good rule of thumb is to start with 1 extra decimal place than what is present in the other columns when deriving statistics (averages, percentiles), and decide from there if you want to round up.
    - An average of `$100,000.0` can simply be rounded to `$100,000`.
    - An average of 5.2 mi might be left as is.
  - National Institutes of Health [Rounding Rules](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4483789/table/ARCHDISCHILD2014) (full [article](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4483789/#:~:text=Ideally%20data%20should%20be%20rounded,might%20call%20it%20Goldilocks%20rounding.&text=The%20European%20Association%20of%20Science,2%E2%80%933%20effective%20digits%E2%80%9D.))

- Additional references: [American Psychological Association (APA) style](https://apastyle.apa.org/instructional-aids/numbers-statistics-guide.pdf), and [Purdue](https://owl.purdue.edu/owl/research_and_citation/apa_style/apa_formatting_and_style_guide/apa_numbers_statistics.html)

## Standard Names

- GTFS data in our warehouse stores information on operators, routes, and stops.
- Analysts should reference the operator name, route name, and Caltrans district the same way across analyses.
  - ITP ID: 182 is `Metro` (not LA Metro, Los Angeles County Metropolitan Transportation Authority, though those are all correct names for the operator)
  - Caltrans District: 7 is `07 - Los Angeles`
  - Between `route_short_name`, `route_long_name`, `route_desc`, which one should be used to describe `route_id`? Use `shared_utils.portfolio_utils`, which relies on regular expressions, to select the most human-readable route name.
- Before deploying your portfolio, make sure the operator name you're using is what's used in other analyses in the portfolio.
  - Use `shared_utils.portfolio_utils` to help you grab the right names to use.

    ```
    from shared_utils import portfolio_utils

    route_names = portfolio_utils.add_route_name()

    # Merge in the selected route name using route_id
    df = pd.merge(df,
                route_names,
                on = ["calitp_itp_id", "route_id"]
    )


    agency_names = portfolio_utils.add_agency_name()

    # Merge in the operator's name using calitp_itp_id
    df = pd.merge(df,
                agency_names,
                on = "calitp_itp_id"
    )
    ```
