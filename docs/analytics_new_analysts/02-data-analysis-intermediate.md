(pandas-intermediate)=

# Data Analysis: Intermediate

After polishing off the [intro tutorial](pandas-intro), you're ready to devour some more techniques to simplify your life as a data analyst.

- [Create a new column using a dictionary to map the values](#create-a-new-column-using-a-dictionary-to-map-the-values)
- [Loop over columns with a dictionary](#loop-over-columns-with-a-dictionary)
- [Loop over dataframes with a dictionary](#loop-over-dataframes-with-a-dictionary)

## Getting Started

```python
import numpy as np
import pandas as pd
import geopandas as gpd
```

(create-a-new-column-using-a-dictionary-to-map-the-values)=

### Create a New Column Using a Dictionary to Map the Values

Sometimes, you want to create a new column by converting one set of values into a different set of values. We could write a function or we could use the map function to add a new column. For our `df`, we want a new column that shows the state.

`df`: person and birthplace

| Person        | Birthplace           |
| ------------- | -------------------- |
| Leslie Knope  | Eagleton, Indiana    |
| Tom Haverford | South Carolina       |
| Ann Perkins   | Michigan             |
| Ben Wyatt     | Partridge, Minnesota |

### Write a Function

[Quick refresher on functions](pandas-intro)

```python
# Create a function called state_abbrev.
def state_abbrev(row):
    # The find function returns the index of where 'Indiana' is found in
    #the column. If it cannot find it, it returns -1.
    if row.Birthplace.find('Indiana') != -1:
        return 'IN'
    elif row.Birthplace.find('South Carolina') != -1:
        return 'SC'
    # For an exact match, we would write it this way.
    elif row.Birthplace == 'Michigan':
        return 'MI'
    elif row.Birthplace.find('Minnesota') != -1:
        return 'MI'

# Apply this function and create the State column.
df['State'] = df.apply(state_abbrev, axis = 1)
```

### Use a Dictionary to Map the Values

But, writing a function could take up a lot of space, especially with all the if-elif-else statements. Alternatively, a dictionary would also work. We could use a dictionary and map the four different city-state values into the state abbreviation.

```python
state_abbrev1 = {'Eagleton, Indiana': 'IN', 'South Carolina': 'SC',
                'Michigan': 'MI', 'Partridge, Minnesota': 'MN'}

df['State'] = df.Birthplace.map(state_abbrev1)
```

But, if we wanted to avoid writing out all the possible combinations, we would first extract the *state* portion of the city-state text. Then we could map the state's full name with its abbreviation.

```python
# The split function splits at the comma and expand the columns.
# Everything is stored in a new df called 'fullname'.
fullname = df['Birthplace'].str.split(",", expand = True)

# Add the City column into our df by extracting the first column (0) from fullname.
df['City'] = fullname[0]

# Add the State column by extracting the second column (1) from fullname.
df['State_full'] = fullname[1]


# Tom Haverford's birthplace is South Carolina. We don't have city information.
# So, the City column would be incorrectly filled in with South Carolina, and
# the State would say None.
# Fix these so the Nones actually display the state information correctly.

df['State_full'] = df.apply(lambda row: row.City if row.State == None else
                    row.State_full, axis = 1)

# Now, use a dictionary to map the values.
state_abbrev2 = {'Indiana': 'IN', 'South Carolina': 'SC',
                'Michigan': 'MI', 'Minnesota': 'MN'}

df['State'] = df.Birthplace.map(state_abbrev2)
```

All 3 methods would give us this `df`:

| Person        | Birthplace           | State |
| ------------- | -------------------- | ----- |
| Leslie Knope  | Eagleton, Indiana    | IN    |
| Tom Haverford | South Carolina       | SC    |
| Ann Perkins   | Michigan             | MI    |
| Ben Wyatt     | Partridge, Minnesota | MN    |

(loop-over-columns-with-a-dictionary)=

### Loop over Columns with a Dictionary

If there are operations or data transformations that need to be performed on multiple columns, the best way to do that is with a loop.

```python
columns = ['colA', 'colB', 'colC']

for c in columns:
    # Fill in missing values for all columns with zeros
    df[c] = df[c].fillna(0)
    # Multiply all columns by 0.5
    df[c] = df[c] * 0.5
```

(loop-over-dataframes-with-a-dictionary)=

### Loop over Dataframes with a Dictionary

It's easier and more efficient to use a loop to do the same operations over the different dataframes (df). Here, we want to find the number of Pawnee businesses and Tom Haverford businesses located in each Council District.

This type of question is perfect for a loop. Each df will be spatially joined to the geodataframe `council_district`, followed by some aggregation.

`business`: list of Pawnee stores

| Business      | longitude | latitude | Sales_millions | geometry      |
| ------------- | --------- | -------- | -------------- | ------------- |
| Paunch Burger | x1        | y1       | 5              | Point(x1, y1) |
| Sweetums      | x2        | y2       | 30             | Point(x2, y2) |
| Jurassic Fork | x3        | y3       | 2              | Point(x3, y3) |
| Gryzzl        | x4        | y4       | 40             | Point(x4, y4) |

`tom`: list of Tom Haverford businesses

| Business          | longitude | latitude | Sales_millions | geometry      |
| ----------------- | --------- | -------- | -------------- | ------------- |
| Tom's Bistro      | x1        | y1       | 30             | Point(x1, y1) |
| Entertainment 720 | x2        | y2       | 1              | Point(x2, y2) |
| Rent-A-Swag       | x3        | y3       | 4              | Point(x3, y3) |

```python
# Save our existing dfs into a dictionary. The business df is named
# 'pawnee"; the tom df is named 'tom'.
dfs = {'pawnee': business, 'tom': tom}

# Create an empty dictionary called summary_dfs to hold the results
summary_dfs = {}

# Loop over key-value pairs
## Keys: pawnee, tom (names given to dataframes)
## Values: business, tom (dataframes)

for key, value in dfs.items():
    # Use f string to define a variable join_df (result of our spatial join)
    ## join_{key} would be join_pawnee or join_tom in the loop
    join_df = "join_{key}"

    # Spatial join
    join_df = gpd.sjoin(value, council_district, how = 'inner', op = 'intersects')

    # Calculate summary stats with groupby, agg, then save it into summary_dfs,
    # naming it 'pawnee' or 'tom'.
    summary_dfs[key] = join.groupby('ID').agg(
        {'Business': 'count', 'Sales_millions': 'sum'})
```

Now, our `summary_dfs` dictionary contains 2 items, which are the 2 dataframes with everything aggregated.

```python
# To view the contents of this dictionary
for key, value in summary_dfs.items():
    display(key)
    display(value)

# To access the df
summary_dfs["pawnee"]
summary_dfs["tom"]
```

`join_tom`: result of spatial join between tom and council_district

| Business          | longitude | latitude | Sales_millions | geometry      | ID  |
| ----------------- | --------- | -------- | -------------- | ------------- | --- |
| Tom's Bistro      | x1        | y1       | 30             | Point(x1, y1) | 1   |
| Entertainment 720 | x2        | y2       | 1              | Point(x2, y2) | 3   |
| Rent-A-Swag       | x3        | y3       | 4              | Point(x3, y3) | 3   |

`summary_dfs["tom"]`: result of the counting number of Tom's businesses by CD

| ID  | Business | Sales_millions |
| --- | -------- | -------------- |
| 1   | 1        | 30             |
| 3   | 2        | 5              |

<br>
