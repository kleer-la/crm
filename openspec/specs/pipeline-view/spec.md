## Purpose
Display a filterable list view of active Prospects and open Proposals with summary metrics, overdue highlighting, and direct navigation to records.

## Requirements

### Requirement: Pipeline list view
The system SHALL display a filterable list view of all active Prospects and open Proposals (excluding Won, Lost, Cancelled Proposals and Converted/Disqualified Prospects).

#### Scenario: View pipeline
- **WHEN** a user navigates to the Pipeline view
- **THEN** the system displays all Prospects with status New, Contacted, or Qualified and all Proposals with status Draft, Sent, or Under Review

#### Scenario: Won Proposal excluded
- **WHEN** a Proposal has status Won, Lost, or Cancelled
- **THEN** it does not appear in the Pipeline view

#### Scenario: Converted Prospect excluded
- **WHEN** a Prospect has been Converted or Disqualified
- **THEN** it does not appear in the Pipeline view

### Requirement: Pipeline filters
The system SHALL support filtering the Pipeline view by: responsible consultant, collaborating consultant, status, expected close date range, and estimated value range. Filters SHALL be combinable with AND logic.

#### Scenario: Filter by responsible consultant
- **WHEN** a user selects a responsible consultant filter
- **THEN** only items where that user is the responsible consultant are shown

#### Scenario: Combine multiple filters
- **WHEN** a user applies both a consultant filter and a date range filter
- **THEN** only items matching all active filters are displayed

### Requirement: Pipeline summary bar
The system SHALL display a summary bar showing: total pipeline value (sum of estimated values of open proposals), count of open proposals, and count of active prospects.

#### Scenario: View summary metrics
- **WHEN** a user views the Pipeline page
- **THEN** the summary bar displays the total pipeline value, open proposal count, and active prospect count reflecting current filters

### Requirement: Overdue close dates highlighted
The system SHALL visually highlight Proposals with expected close dates in the past.

#### Scenario: Overdue expected close date
- **WHEN** a Proposal's expected close date is before today
- **THEN** the date is visually highlighted in the Pipeline view

### Requirement: Pipeline item navigation
The system SHALL allow clicking any item in the Pipeline view to open the full detail record.

#### Scenario: Click a pipeline item
- **WHEN** a user clicks a Prospect or Proposal in the Pipeline view
- **THEN** the system navigates to that record's detail page
