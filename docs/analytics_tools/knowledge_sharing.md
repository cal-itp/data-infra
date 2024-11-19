(knowledge-sharing)=

# Helpful Links

Here are some resources data analysts have collected and referenced, that will hopefully help you out in your work.

- [Data Analysis](#data-analysis)
  - [Python](#python)
  - [Pandas](#pandas)
  - [Summarizing](#summarizing)
  - [Merging](#merging)
  - [Dates](#dates)
  - [Monetary Values](#monetary-values)
- [Visualizations](#visualization)
  - [Charts](#charts)
  - [Maps](#maps)
  - [DataFrames](#dataframes)
  - [Ipywidgets](#ipywidgets)
  - [Markdown](#markdown)
  - [ReviewNB](#reviewNB)

(data-analysis)=

## Data Analysis

(python)=

### Python

- [Composing Programs: comprehensive Python course](https://www.composingprograms.com/)
- [Intermediate Python: tips for improving your programs](https://book.pythontips.com/en/latest/index.html)
- [Stop Python from executing code when a module is imported.](https://stackoverflow.com/questions/6523791/why-is-python-running-my-module-when-i-import-it-and-how-do-i-stop-it)
- [Loop through 2 lists with zip in parallel.](https://stackoverflow.com/questions/1663807/how-to-iterate-through-two-lists-in-parallel)
- [Find the elements that are in one list, but not in another list.](https://stackoverflow.com/questions/41125909/python-find-elements-in-one-list-that-are-not-in-the-other)
- [What does += do?](https://stackoverflow.com/questions/4841436/what-exactly-does-do)

(pandas)=

### Pandas

- [Turn columns into dummy variables.](https://pandas.pydata.org/docs/reference/api/pandas.get_dummies.html)
- [Export multiple dataframes into their own sheets to a single Excel workbook.](https://xlsxwriter.readthedocs.io/example_pandas_multiple.html)
- [Display multiple dataframes side by side.](https://stackoverflow.com/questions/38783027/jupyter-notebook-display-two-pandas-tables-side-by-side)
- [Display all rows or columns of a dataframe in the notebook](https://pandas.pydata.org/pandas-docs/stable/user_guide/options.html)

(summarizing)=

### Summarizing

- [Groupby and calculate a new value, then use that value within your DataFrame.](https://stackoverflow.com/questions/35640364/python-pandas-max-value-in-a-group-as-a-new-column)
- [Explanation of the split-apply-combine paradigm.](https://stackoverflow.com/questions/30244952/how-do-i-create-a-new-column-from-the-output-of-pandas-groupby-sum)
- [Pandas profiling tool: creates html reports from DataFrames.](https://github.com/ydataai/pandas-profiling)
  - [Examples](https://pandas-profiling.ydata.ai/examples/master/census/census_report.html)

(merging)=

### Merging

- When working with data sets where the "merge on" column is a string data type, it can be difficult to get the DataFrames to join. For example, df1 lists <i>County of Sonoma, Human Services Department, Adult and Aging Division</i>, but df2 references the same department as: <i>County of Sonoma (Human Services Department) </i>.
  - Potential Solution #1: [fill in a column in one DataFrame that has a partial match with the string values in another one.](https://stackoverflow.com/questions/61811137/based-on-partial-string-match-fill-one-data-frame-column-from-another-dataframe)
  - Potential Solution #2: [use the package fuzzymatcher. This will require you to carefully comb through for any bad matches.](https://pbpython.com/record-linking.html)
  - Potential Solution #3: [if you don't have too many values, use a dictionary.](https://github.com/cal-itp/data-analyses/blob/main/drmt_grants/TIRCP_functions.py#:~:text=%23%23%23%20RECIPIENTS%20%23%23%23,%7D)

(dates)=

### Dates

- [Use shift to calculate the number of days between two dates.](https://towardsdatascience.com/all-the-pandas-shift-you-should-know-for-data-analysis-791c1692b5e)

```python
df['n_days_between'] = (df['prepared_date'] - df.shift(1)['prepared_date']).dt.days
```

- [Assign fiscal year to a date.](https://stackoverflow.com/questions/59181855/get-the-financial-year-from-a-date-in-a-pandas-dataframe-and-add-as-new-column)

```python
# Make sure your column is a date time object
df['financial_year'] = df['base_date'].map(lambda x: x.year if x.month > 3 else x.year-1)
```

(monetary-values)=

### Monetary Values

- [Reformat values that are in scientific notation into millions or thousands.](https://github.com/d3/d3-format)
  - [Example in notebook.](https://github.com/cal-itp/data-analyses/blob/30de5cd2fed3a37e2c9cfb661929252ad76f6514/dla/e76_obligated_funds/_dla_utils.py#L221)

```python
    x=alt.X("Funding Amount", axis=alt.Axis(format="$.2s", title="Obligated Funding ($2021)"))
```

- [Reformat values from 19000000 to $19.0M.](https://stackoverflow.com/questions/41271673/format-numbers-in-a-python-pandas-dataframe-as-currency-in-thousands-or-millions)
- Adjust for inflation.

```python
# Must install and import cpi package for the function to work.
def adjust_prices(df):
    cols =  ["total_requested",
           "fed_requested",
           "ac_requested"]

    def inflation_table(base_year):
        cpi.update()
        series_df = cpi.series.get(area="U.S. city average").to_dataframe()
        inflation_df = (series_df[series_df.year >= 2008]
                        .pivot_table(index='year', values='value', aggfunc='mean')
                        .reset_index()
                       )
        denominator = inflation_df.value.loc[inflation_df.year==base_year].iloc[0]

        inflation_df = inflation_df.assign(
        inflation = inflation_df.value.divide(denominator)
        )

        return inflation_df

    ##get cpi table
    cpi = inflation_table(2021)
    cpi.update
    cpi = (cpi>>select(_.year, _.value))
    cpi_dict = dict(zip(cpi['year'], cpi['value']))


    for col in cols:
        multiplier = df["prepared_y"].map(cpi_dict)

        ##using 270.97 for 2021 dollars
        df[f"adjusted_{col}"] = ((df[col] * 270.97) / multiplier)
    return df
```

(visualization)=

## Visualization

(charts)=

### Charts

#### Altair

- [Manually concatenate a bar chart and line chart to create a dual axis graph.](https://github.com/altair-viz/altair/issues/1934)
- [Adjust the time units of a datetime column for an axis.](https://altair-viz.github.io/user_guide/transform/timeunit.html)
- [Label the lines on a line chart.](https://stackoverflow.com/questions/61194028/adding-labels-at-end-of-line-chart-in-altair)
- [Layer altair charts, lose color with no encoding, workaround to get different colors to appear on legend.](https://github.com/altair-viz/altair/issues/1099)
- [Add regression line to scatterplot.](https://stackoverflow.com/questions/61447422/quick-way-to-visualise-multiple-columns-in-altair-with-regression-lines)
- [Adjust scales for axes to be the min and max values.](https://stackoverflow.com/questions/62281179/how-to-adjust-scale-ranges-in-altair)
- [Resolving the error 'TypeError: Object of type 'Timestamp' is not JSON serializable'](https://github.com/altair-viz/altair/issues/1355)
- [Manually sort a legend.](https://github.com/cal-itp/data-analyses/blob/460e9fc8f4311e90d9c647e149a23a9e38035394/Agreement_Overlap/Visuals.ipynb)
- Add tooltip to chart functions.

```python
def add_tooltip(chart, tooltip1, tooltip2):
    chart = (
        chart.encode(tooltip= [tooltip1,tooltip2]))
    return chart
```

(maps)=

### Maps

- [Quick interactive maps with Geopandas.gdf.explore()](https://geopandas.org/en/stable/docs/reference/api/geopandas.GeoDataFrame.explore.html)

(dataframes)=

### DataFrames

- [Styling dataframes with HTML.](https://pandas.pydata.org/pandas-docs/stable/user_guide/style.html)
- [After styling a DataFrame, you will have to access the underlying data with .data](https://stackoverflow.com/questions/56647813/perform-operations-after-styling-in-a-dataframe).

(ipywidgets)=

### ipywidgets

#### Tabs

- Create tabs to switch between different views.
- [Stack Overflow Help.](https://stackoverflow.com/questions/50842160/how-to-display-matplotlib-plots-in-a-jupyter-tab-widget)
  - [Notebook example.](https://github.com/cal-itp/data-analyses/blob/main/dla/e76_obligated_funds/charting_function_work.ipynb?short_path=1c01de9#L302333)
  - [Example on Ipywidgets docs page.](https://ipywidgets.readthedocs.io/en/latest/examples/Widget%20List.html#Tabs)

(markdown)=

### Markdown

- [Create a markdown table.](https://www.pluralsight.com/guides/working-tables-github-markdown)
- [Add a table of content that links to headers throughout a markdown file.](https://stackoverflow.com/questions/2822089/how-to-link-to-part-of-the-same-document-in-markdown)
- [Add links to local files.](https://stackoverflow.com/questions/32563078/how-link-to-any-local-file-with-markdown-syntax?rq=1)
- [Direct embed an image.](https://datascienceparichay.com/article/insert-image-in-a-jupyter-notebook/)

(reviewNB)=

### ReviewNB on GitHub

- [Tool designed to facilitate reviewing Jupyter Notebooks in a collaborative setting on GitHub](https://www.reviewnb.com/)
- [Shows side-by-side diffs of Jupyter Notebooks, including changes to both code cells and markdown cells and allows reviewers to comment on specific cells](https://www.reviewnb.com/#faq)
