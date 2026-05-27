## MODIFIED Requirements

### Requirement: Auto-calculated total revenue

The system SHALL automatically calculate total revenue to date as the sum of estimated values from all Won proposals linked to the Customer. This field SHALL be read-only. The `final_value` field on proposals is removed.

#### Scenario: Proposal marked as Won
- **WHEN** a Proposal linked to a Customer is marked as Won
- **THEN** the Customer's total revenue to date is recalculated to include the proposal's estimated value

#### Scenario: Won Proposal status changed
- **WHEN** a Won Proposal's status is changed away from Won
- **THEN** the Customer's total revenue to date is recalculated to exclude that amount

## ADDED Requirements

### Requirement: Customer proposals section

The system SHALL display all linked Proposals for a Customer in a dedicated proposals section on the detail page, ordered by date asked descending, showing title (as link), status, estimated value, and expected close date.

#### Scenario: View Customer with proposals
- **WHEN** a user opens a Customer detail page that has linked Proposals
- **THEN** a dedicated Proposals section shows each Proposal with title (linked to its detail page), status badge, estimated value, and expected close date

#### Scenario: View Customer without proposals
- **WHEN** a user opens a Customer detail page that has no linked Proposals
- **THEN** the Proposals section shows "No proposals yet."
