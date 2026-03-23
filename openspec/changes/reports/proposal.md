## Why

The team needs reporting capabilities to analyze pipeline performance, win/loss trends, consultant workload, and customer revenue. Currently this data exists in the CRM but there is no way to generate summarized views or export data for stakeholder presentations.

## What Changes

- Add Proposals by Status report: count and total USD value grouped by status, filterable by date range and consultant
- Add Won vs Lost breakdown report: count, value, and win/loss reason summaries over a selected period
- Add Pipeline by Consultant report: open proposal count and total estimated value per consultant
- Add Customer Revenue Summary report: total won proposal value per customer, sortable
- All reports support date range filtering
- All reports exportable to CSV with monetary values in USD
- Report data reflects live database state at generation time

## Capabilities

### New Capabilities
- `reporting`: Four reports (proposals by status, won vs lost, pipeline by consultant, customer revenue), date range and consultant filters, CSV export

### Modified Capabilities

_None._

## Impact

- **Controllers**: New `ReportsController` with actions for each report type
- **Views**: Report pages with filter controls and tabular data display
- **CSV export**: ActionController `respond_to` with CSV format using Ruby CSV library
- **No new models**: Reports query existing Proposal, Customer, and User data via scopes/aggregations
- **Routes**: New `/reports` namespace with sub-routes for each report
