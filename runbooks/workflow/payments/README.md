# Cal-ITP Payments Data Ecosystem Documentation

Welcome to the comprehensive documentation for the Cal-ITP payments data ecosystem. This documentation follows the [Diátaxis framework](https://diataxis.fr/) to provide different types of documentation for different needs.

## About This Documentation

The Cal-ITP payments data ecosystem allows transit agencies across California to utilize their contactless payments data for analytics and operations needs. This documentation covers the complete data pipeline from vendor data ingestion through to agency-facing dashboards.

## Documentation Structure

This documentation is organized according to the Diátaxis framework into four categories:

### 📚 [Tutorials](tutorials/) - Learning-Oriented
Step-by-step lessons to help you learn the payments ecosystem. Start here if you're new to the system.

- [Getting Started with the Payments Ecosystem](tutorials/01-getting-started.md)
- [Understanding the Data Flow](tutorials/02-understanding-data-flow.md)
- [Your First Agency Onboarding](tutorials/03-first-agency-onboarding.md)

### 🔧 [How-To Guides](how-to/) - Task-Oriented
Practical guides for accomplishing specific tasks. Use these when you need to get something done.

- [Onboard a New Littlepay Agency](how-to/onboard-littlepay-agency.md)
- [Onboard a New Enghouse Agency](how-to/onboard-enghouse-agency.md)
- [Onboard a New Elavon Agency](how-to/onboard-elavon-agency.md)
- [Create Agency Metabase Dashboards](how-to/create-metabase-dashboards.md)
- [Rotate Littlepay AWS Keys](how-to/rotate-littlepay-keys.md)
- [Troubleshoot Data Sync Issues](how-to/troubleshoot-sync-issues.md)
- [Update Row Access Policies](how-to/update-row-access-policies.md)

### 📖 Reference - Information-Oriented
*Coming soon: Technical descriptions and specifications for the payments ecosystem.*

### 💡 Explanation - Understanding-Oriented
*Coming soon: Conceptual discussions to deepen your understanding of the payments system.*

## Quick Links

### For New Team Members
1. Start with [Getting Started Tutorial](tutorials/01-getting-started.md)
2. Review [Understanding the Data Flow](tutorials/02-understanding-data-flow.md)
3. Explore the [How-To Guides](how-to/) for specific tasks

### For Onboarding a New Agency
1. Review [Understanding the Data Flow](tutorials/02-understanding-data-flow.md)
2. Follow the appropriate onboarding guide:
   - [Onboard a New Littlepay Agency](how-to/onboard-littlepay-agency.md)
   - [Onboard a New Enghouse Agency](how-to/onboard-enghouse-agency.md)
   - [Onboard a New Elavon Agency](how-to/onboard-elavon-agency.md)
3. Follow [Create Agency Metabase Dashboards](how-to/create-metabase-dashboards.md)

### For Troubleshooting
1. Check [Troubleshoot Data Sync Issues](how-to/troubleshoot-sync-issues.md)
2. Review the [Airflow DAGs Overview](../../airflow/dags/README.md)
3. Consult the [Warehouse Models](../../../warehouse/models/mart/payments/)

## System Components

The payments data ecosystem consists of:

- **Data Vendors**: 
  - **Fare Collection:** Littlepay OR Enghouse (each agency uses one)
  - **Payment Processing:** Elavon (used by all agencies)
- **Data Ingestion**: Airflow DAGs for syncing and parsing vendor data
- **Data Storage**: GCS buckets for raw and parsed data
- **Data Warehouse**: BigQuery with dbt transformations
- **Data Access**: Row-level security via service accounts
- **Visualization**: Metabase dashboards for agencies

## Contributing

When updating this documentation:
- Follow the Diátaxis framework principles
- Place content in the appropriate category
- Update this README if adding new documents
- Keep examples current and tested
- Include links to relevant code/resources

## Related Documentation

- [Main Data Infrastructure Documentation](https://docs.calitp.org/data-infra/)
- [Architecture Overview](https://docs.calitp.org/data-infra/architecture/data.html)
- [Airflow DAGs Overview](../../airflow/dags/README.md)
- [Warehouse Models](../../../warehouse/models/mart/payments/)
