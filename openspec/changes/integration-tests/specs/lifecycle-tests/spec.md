## ADDED Requirements

### Requirement: Full Prospect to Customer lifecycle
The system SHALL support the complete lifecycle: create Prospect → qualify → create Proposal → mark Proposal as Won → convert Prospect to Customer → verify Customer has Proposal and revenue.

#### Scenario: Complete lifecycle flow
- **WHEN** a user creates a Prospect, qualifies it, creates a Proposal linked to the Prospect, marks the Proposal as Won, and converts the Prospect to a Customer
- **THEN** the Customer exists with the Proposal re-linked, total_revenue reflects the Won Proposal value, and the original Prospect is read-only with a reference to the Customer

### Requirement: Task lifecycle on linked records
The system SHALL support creating Tasks linked to Prospects, Customers, and Proposals, and completing or cancelling them with proper status tracking.

#### Scenario: Task created on Prospect, completed after conversion
- **WHEN** a Task is created linked to a Prospect, the Prospect is converted to a Customer, and the Task is marked as Done
- **THEN** the Task retains its link to the original Prospect (not re-linked), has a completed_at timestamp, and activity is logged on both the Task and the Prospect

### Requirement: Activity log continuity across lifecycle
Activity logs SHALL maintain a continuous timeline across Prospect conversion, Proposal status changes, and Task completions.

#### Scenario: Activity timeline after full lifecycle
- **WHEN** a Prospect is created, a Proposal is added, the Proposal status changes, the Prospect is converted, and a Task is completed
- **THEN** each record's activity log contains all relevant system events in chronological order
