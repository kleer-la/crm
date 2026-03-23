## Context

The CRM has model tests, controller tests, and some integration tests for individual modules. Cross-cutting constraints (e.g., company_name must be unique across both Prospects and Customers) and multi-step lifecycle flows are not covered by existing tests.

## Goals / Non-Goals

**Goals:**
- Verify cross-model uniqueness constraints work correctly at the database and validation level
- Verify converted Prospect becomes read-only and its Proposals are properly re-linked to the new Customer
- Cover the complete lifecycle flow from Prospect creation through Customer conversion and Task completion via system tests

**Non-Goals:**
- Duplicate existing unit/controller test coverage
- UI-heavy system tests (focus on flow correctness, not pixel-perfect UI)
- Performance or load testing

## Decisions

### 1. Integration tests for constraint verification

**Decision:** Use `ActionDispatch::IntegrationTest` for cross-model constraint tests. These test at the model/database level, not through the full HTTP stack.

**Rationale:** Constraint tests need to verify database-level uniqueness and model validation interactions. Integration tests are the right level — they exercise the full model stack including callbacks and validations without the overhead of browser simulation.

### 2. System tests for lifecycle flows

**Decision:** Use `ActionDispatch::SystemTestCase` with headless Chrome (or Rack::Test for non-JS flows) for full lifecycle tests that walk through the complete Prospect → Customer → Proposal → Task flow via the web interface.

**Rationale:** Lifecycle tests should exercise the actual user flow including Turbo interactions, form submissions, and navigation. System tests verify the full stack end-to-end.

**Alternatives considered:**
- *Integration tests only*: Would miss Turbo/Stimulus interactions and view-level issues.
- *Capybara feature specs*: Rails system tests are the built-in equivalent and preferred in Rails 8.

## Risks / Trade-offs

- **System tests are slower** → Keep the number focused (1-2 lifecycle scenarios). Run separately from unit tests if needed.
- **Browser dependency** → System tests require a headless browser. Ensure CI has Chrome/Chromium available.
