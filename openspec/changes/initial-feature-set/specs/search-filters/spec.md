## ADDED Requirements

### Requirement: Global search across entities
The system SHALL provide a global search that searches across Prospects, Customers, and Proposals by name/title simultaneously. Results SHALL show the record type and linked company. Search SHALL match partial strings.

#### Scenario: Search by partial company name
- **WHEN** a user searches for "acme"
- **THEN** the results include Prospects and Customers with "acme" in the company name (e.g., "Acme Corp") and Proposals linked to those companies

#### Scenario: Search returns mixed entity types
- **WHEN** a user searches for a term that matches across entity types
- **THEN** results from all matching types are displayed together with record type labels (Prospect, Customer, Proposal)

#### Scenario: Search with no results
- **WHEN** a user searches for a term that matches no records
- **THEN** the system displays an empty state message

### Requirement: Module-level filtering and sorting
Each list view (Prospects, Customers, Proposals, Tasks) SHALL support filtering by any field and sorting by any column.

#### Scenario: Filter Prospects by status
- **WHEN** a user applies a status filter on the Prospects list view
- **THEN** only Prospects matching the selected status are displayed

#### Scenario: Sort Proposals by expected close date
- **WHEN** a user clicks the expected close date column header
- **THEN** the list is sorted by that column in ascending or descending order

#### Scenario: Combine filter and sort
- **WHEN** a user applies a filter and then sorts by a column
- **THEN** the filtered results are displayed in the selected sort order
