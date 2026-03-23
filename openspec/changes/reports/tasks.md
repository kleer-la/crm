## 1. Reports Controller & Routes

- [ ] 1.1 Create ReportsController with index action (reports landing page listing available reports)
- [ ] 1.2 Add reports routes: GET /reports, GET /reports/proposals_by_status, GET /reports/won_vs_lost, GET /reports/pipeline_by_consultant, GET /reports/customer_revenue
- [ ] 1.3 Add Reports link to sidebar navigation

## 2. Report Implementations

- [ ] 2.1 Implement proposals_by_status action: group Proposals by status with count and sum(estimated_value), apply date range and consultant filters, render HTML table
- [ ] 2.2 Implement won_vs_lost action: query Won and Lost Proposals for date range, show counts, values, and win/loss reason summaries
- [ ] 2.3 Implement pipeline_by_consultant action: group open Proposals by responsible_consultant with count and sum(estimated_value)
- [ ] 2.4 Implement customer_revenue action: query Customers with sum of Won Proposal estimated_values, sortable by revenue amount

## 3. Report Views & Filters

- [ ] 3.1 Build shared report filter partial (date range picker, consultant selector) reused across report views
- [ ] 3.2 Build proposals_by_status view with status grouping table and filter form
- [ ] 3.3 Build won_vs_lost view with Won/Lost comparison table and reason breakdown
- [ ] 3.4 Build pipeline_by_consultant view with per-consultant table
- [ ] 3.5 Build customer_revenue view with sortable customer revenue table

## 4. CSV Export

- [ ] 4.1 Add respond_to CSV format to all four report actions using Ruby CSV library
- [ ] 4.2 Add "Export CSV" button to each report view linking to the same action with .csv format
