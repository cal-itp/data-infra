(publishing-metabase)=

# Metabase

Interactive charts should be displayed in Metabase. Using Voila on Jupyter Notebooks works locally, but doesn't allow for sharing with external stakeholders. The data cleaning and processing should still be done within Python scripts or Jupyter notebooks. The processed dataset backing the dashboard should be exported to a Google Cloud Storage bucket.

An [Airflow DAG](https://github.com/cal-itp/data-infra/tree/main/airflow/dags) needs to be set up to copy the processed dataset into the data warehouse. Metabase can only source data from the data warehouse. The dashboard visualizations can be set up in Metabase, remain interactive, and easily shared to external stakeholders.

Any tweaks to the data processing steps are easily done in scripts and notebooks, and it ensures that the visualizations in the dashboard remain updated with little friction.

Ex: [Payments Dashboard](https://dashboards.calitp.org/dashboard/3-payments-performance-dashboard?transit_provider=mst)

## Metabase Training Guide 2024

Please see the [Cal-ITP Metabase Training Guide](https://docs.google.com/document/d/1ag9qmSDWF9d30lGyKcvAAjILt1sCIJhK7wuUYkfAals/edit?tab=t.0#heading=h.xdjzmfck1e7) to see how to utilize the data warehouse to create meaningful and effective visuals and analyses.
