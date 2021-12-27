# ---
# operator: operators.PythonToWarehouseOperator
# table_name: "sandbox.python_to_warehouse"
# fields:
#   g: The g field python
#   x: The x field python
# doc_md: |
#   This is an example of the PythonOperator.
#
# dependencies:
#   - create_dataset
# ---

import pandas as pd
from calitp import write_table

df = pd.DataFrame({"g": ["a", "b"], "x": [1, 2]})

write_table(df, "sandbox.python_to_warehouse")
