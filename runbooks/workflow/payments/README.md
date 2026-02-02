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
- [Monitor Pipeline Health](how-to/monitor-pipeline-health.md)

### 📖 [Reference](reference/) - Information-Oriented
Technical descriptions and specifications. Consult these for detailed information.

- [Payments Data Pipeline Architecture](reference/architecture.md)
- [Littlepay Data Schema](reference/littlepay-schema.md)
- [Enghouse Data Schema](reference/enghouse-schema.md)
- [Elavon Data Schema](reference/elavon-schema.md)
- [dbt Models Reference](reference/dbt-models.md)
- [Airflow DAGs Reference](reference/airflow-dags.md)
- [Service Accounts & Permissions](reference/service-accounts.md)
- [GCS Buckets & Storage](reference/gcs-buckets.md)
- [Metabase Configuration](reference/metabase-config.md)
- [API Endpoints & Integrations](reference/api-endpoints.md)

### 💡 [Explanation](explanation/) - Understanding-Oriented
Conceptual discussions to deepen your understanding. Read these to understand the "why" behind the system.

- [Payments Ecosystem Overview](explanation/ecosystem-overview.md)
- [Why Diátaxis for Documentation](explanation/why-diataxis.md)
- [Data Security & Row-Level Access](explanation/data-security.md)
- [Vendor Integration Patterns](explanation/vendor-integration.md)
- [Fare Types & Calculations](explanation/fare-types.md)
- [Settlement & Reconciliation](explanation/settlement-reconciliation.md)
- [Design Decisions & Trade-offs](explanation/design-decisions.md)

## Quick Links

### For New Team Members
1. Start with [Getting Started Tutorial](tutorials/01-getting-started.md)
2. Read [Payments Ecosystem Overview](explanation/ecosystem-overview.md)
3. Review [Data Pipeline Architecture](reference/architecture.md)

### For Onboarding a New Agency
1. Review [Understanding the Data Flow](tutorials/02-understanding-data-flow.md)
2. Follow the appropriate onboarding guide:
   - [Onboard a New Littlepay Agency](how-to/onboard-littlepay-agency.md)
   - [Onboard a New Enghouse Agency](how-to/onboard-enghouse-agency.md)
   - [Onboard a New Elavon Agency](how-to/onboard-elavon-agency.md)
3. Follow [Create Agency Metabase Dashboards](how-to/create-metabase-dashboards.md)

### For Troubleshooting
1. Check [Troubleshoot Data Sync Issues](how-to/troubleshoot-sync-issues.md)
2. Review [Monitor Pipeline Health](how-to/monitor-pipeline-health.md)
3. Consult [Airflow DAGs Reference](reference/airflow-dags.md)

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
