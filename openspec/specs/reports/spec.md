## Purpose
Provide filterable, CSV-exportable reports for proposals by status, won vs lost breakdown, pipeline by consultant, and customer revenue summary.

## Requirements

### Requirement: Proposals by status report
The system SHALL provide a report showing count and total USD value of Proposals grouped by status, filterable by date range and consultant.

#### Scenario: Generate Proposals by status report
- **WHEN** a user generates the Proposals by status report with a date range
- **THEN** the system displays Proposal counts and total values grouped by status for the selected period

#### Scenario: Filter by consultant
- **WHEN** a user filters the report by a specific consultant
- **THEN** only Proposals where that consultant is responsible are included

### Requirement: Won vs Lost breakdown report
The system SHALL provide a report showing count and value of Won and Lost Proposals over a selected period, including a summary of win/loss reasons.

#### Scenario: Generate Won vs Lost report
- **WHEN** a user generates the Won vs Lost report for a date range
- **THEN** the system displays counts, values, and reason summaries for Won and Lost Proposals

### Requirement: Pipeline by consultant report
The system SHALL provide a report showing open Proposal count and total USD value per responsible consultant.

#### Scenario: Generate Pipeline by consultant report
- **WHEN** a user generates the Pipeline by consultant report
- **THEN** the system displays each consultant's open Proposal count and total estimated value

### Requirement: Customer revenue summary report
The system SHALL provide a report showing total Won Proposal USD value per Customer, sortable.

#### Scenario: Generate Customer revenue report
- **WHEN** a user generates the Customer revenue summary report
- **THEN** the system displays each Customer's total revenue from Won Proposals, sortable by amount

### Requirement: Reports filterable by date range
All reports SHALL support filtering by date range at minimum.

#### Scenario: Apply date range filter
- **WHEN** a user sets a date range on any report
- **THEN** only data within that range is included in the report

### Requirement: CSV export for all reports
All reports SHALL be exportable to CSV with monetary values in USD.

#### Scenario: Export report to CSV
- **WHEN** a user clicks the CSV export button on any report
- **THEN** the system downloads a CSV file containing the report data with values in USD

### Requirement: Reports reflect live data
Report data SHALL reflect the current state of the database at generation time.

#### Scenario: Report generated after data change
- **WHEN** a user generates a report immediately after a Proposal status change
- **THEN** the report includes the updated status
