# Update Expired Airtable Issues (Airflow DAG)

## Overview

This Airflow DAG replaces the previous:

Cloud Scheduler → Cloud Function → BigQuery → Airtable

architecture with a fully Airflow-native workflow.

The DAG:

1. Queries BigQuery for expired Transit Data Quality issues  
2. Updates corresponding records in Airtable  
3. Sends an HTML email summary of updated records  
4. Logs any batch failures  

This implementation removes the HTTP-triggered Cloud Function and centralizes orchestration inside Composer.

---

## Schedule

Runs every Friday at 6:00 AM
