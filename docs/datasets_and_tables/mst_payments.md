# MST Payments (WIP)

Currently, Payments data is hosted by Littlepay, who exposes the "Littlepay Data Model" as a set of files stored in an S3 bucket. To get a copy of the data docs, email hunter.

## Tables

| Tablename | Description | Notes |
|----- | -------- | -------|
| device_transactions | A list of every tap on the devices | * Cannot use for ridership stats because tap on / offs |
| micropayments | A list of every charge to a card | * T-2 delays because of charing rules |
| micropayments_devices_transactions | Join tables for two prior tables | |
| micropayment_adjustments | A list of amounts deducted from the `nominal_amount` to arrive at the `charge_amount` for a micropayment | A micropayment can include multiple adjustments candidates, but only one should have `applied=true`. |

## Views

The table best used for caculating ridership is `mst_ridership_materialized` table.

## DAGs Maintenance

You can find further information on DAGs maintenance for MST Payments data [on this page](mst-payments-dags).
