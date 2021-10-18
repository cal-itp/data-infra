---
operator: operators.CsvToWarehouseOperator
table_name: "sandbox.csv_to_warehouse"
src_uri: "https://docs.google.com/spreadsheets/d/1Ed62uU-SJYoV7ecEQ61aT-9FzF1R5W2w-V1D7Bd_Ib4/export?gid=0&format=csv"
fields:
  g: The g field csv
  x: The x field csv

dependencies:
  - create_dataset
---
