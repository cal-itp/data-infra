(python-useful-links)=
# Helpful Links
Here are resources data analysts have carefully collected and referenced. To share your own bookmarks and links, create a new markdown file and add it [here](https://github.com/cal-itp/data-analyses/tree/main/example_report).

## Python
### Libraries
* [Stop Python from executing code when it's imported](https://stackoverflow.com/questions/6523791/why-is-python-running-my-module-when-i-import-it-and-how-do-i-stop-it)
* When working with data sets where the "merge on" column is a string, it can be difficult to get the DataFrames to join. For example, df1 lists <i>County of Sonoma, Human Services Department, Adult and Aging Division</i>, but df2 references the same department under a slightly different name: <i>County of Sonoma (Human Services Department) </i>.
* [Looping through 2 lists with zip.](https://stackoverflow.com/questions/1663807/how-to-iterate-through-two-lists-in-parallel)
* [Finding the elements that are in one list, but not in another list.](https://stackoverflow.com/questions/41125909/python-find-elements-in-one-list-that-are-not-in-the-other)
* [What exactly is += and what does it do?](https://stackoverflow.com/questions/4841436/what-exactly-does-do)
    * Potential Solution #1: [fill in a column in df1 that has a partial match with the string valuesin df2.](https://stackoverflow.com/questions/61811137/based-on-partial-string-match-fill-one-data-frame-column-from-another-dataframe)
    * Potential Solution #2: [use the package fuzzymatcher. This will require you to carefully comb through for any bad matches.](https://pbpython.com/record-linking.html)
    * Potential Solution #3: If doing this manually is within reason, you can use a dictionary.
    ```
    df['Organization_Name'] = df['Organization_Name'].replace({'Old_Name1':'New_Name1','Old_Name2':'New_Name2'})
    ```



## Pandas
* [Groupby and calculate a new value, then use that value within a group.](https://stackoverflow.com/questions/35640364/python-pandas-max-value-in-a-group-as-a-new-column)
* [Turn columns into dummy variables.](https://pandas.pydata.org/docs/reference/api/pandas.get_dummies.html)
* [Split-apply-combine paradigm.](https://stackoverflow.com/questions/30244952/how-do-i-create-a-new-column-from-the-output-of-pandas-groupby-sum)
* [Export multiple dataframes into their own sheets in an Excel workbook](https://xlsxwriter.readthedocs.io/example_pandas_multiple.html)
* [Display multiple dataframes side by side.](https://stackoverflow.com/questions/38783027/jupyter-notebook-display-two-pandas-tables-side-by-side)
* [Pandas profiling tool creates "html profiling reports from pandas DataFrames.](https://github.com/ydataai/pandas-profiling)
    * [Examples](https://pandas-profiling.ydata.ai/examples/master/census/census_report.html)

## Dates (Note to self: double check)
* [Calculating the number of days between two dates.](https://towardsdatascience.com/all-the-pandas-shift-you-should-know-for-data-analysis-791c1692b5e)
* [Grab the fiscal year from a date.](https://stackoverflow.com/questions/59181855/get-the-financial-year-from-a-date-in-a-pandas-dataframe-and-add-as-new-column)

```
# Make sure your column is a date time object
df['financial_year'] = df['base_date'].map(lambda x: x.year if x.month > 3 else x.year-1)
```

## Monetary Values
### Format currency
* [Reformat values that are in scientific notation into millions or thousands.](https://github.com/d3/d3-format)
    * [Example in Notebook](https://github.com/cal-itp/data-analyses/blob/30de5cd2fed3a37e2c9cfb661929252ad76f6514/dla/e76_obligated_funds/_dla_utils.py#L221)
* [Reformat values from 19000000 to $19.0M.](https://stackoverflow.com/questions/41271673/format-numbers-in-a-python-pandas-dataframe-as-currency-in-thousands-or-millions)

### Adjust for Inflation
* ADD SOMETHING HERE

## Charts
* Add tooltip to chart functions.
```
def add_tooltip(chart, tooltip1, tooltip2):
    chart = (
        chart.encode(tooltip= [tooltip1,tooltip2]))
    return chart
```
### Altair
* [Manually concatenate a bar chart and line chart to create a dual axis graph.](https://github.com/altair-viz/altair/issues/1934)
* [Use time units on an axis.](https://altair-viz.github.io/user_guide/transform/timeunit.html)
* [Add label to end of line on chart.](https://stackoverflow.com/questions/61194028/adding-labels-at-end-of-line-chart-in-altair)
* [Layer altair charts, lose color with no encoding, workaround to get different colors to appear on legend.](altair-viz/altair#1099)
* [Add regression line to scatterplot.](https://stackoverflow.com/questions/61447422/quick-way-to-visualise-multiple-columns-in-altair-with-regression-lines)
* Finish adding rest.

## Maps
* [Examples of folium, branca, and color maps.](https://nbviewer.org/github/python-visualization/folium/blob/v0.2.0/examples/Colormaps.ipynb)

## Customizing
### DataFrame
* [Styling dataframes with HTML.](https://pandas.pydata.org/pandas-docs/stable/user_guide/style.html)
* [After styling a DataFrame, you will have to access the underlying data with .data](https://stackoverflow.com/questions/56647813/perform-operations-after-styling-in-a-dataframe).

## Ipywidgets
Per the [docs](https://ipywidgets.readthedocs.io/en/latest/), ipywidgets are <i>"are interactive HTML widgets for Jupyter notebooks and the IPython kernel."</i>
### Create tabs
* [Stack Overflow Help.](https://stackoverflow.com/questions/50842160/how-to-display-matplotlib-plots-in-a-jupyter-tab-widget)
    * [Notebook example.](https://github.com/cal-itp/data-analyses/blob/main/dla/e76_obligated_funds/charting_function_work.ipynb?short_path=1c01de9#L302333)
