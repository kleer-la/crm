## Why

The CRM has comprehensive unit and controller tests for individual modules, but lacks cross-module integration tests that verify the full lifecycle flows and constraint enforcement across model boundaries. These tests will catch regressions in the interactions between Prospects, Customers, Proposals, and Tasks.

## What Changes

- Add cross-model uniqueness constraint tests (company_name uniqueness across Prospects and Customers, email uniqueness across Prospect contacts and Customer contacts)
- Add converted Prospect read-only verification tests (ensure converted Prospects cannot be edited, proposals are re-linked correctly)
- Add full lifecycle system tests: Prospect creation → qualification → Proposal creation → mark as Won → convert to Customer → Task creation and completion

## Capabilities

### New Capabilities
- `cross-model-constraints`: Tests verifying uniqueness and referential integrity constraints that span multiple models
- `lifecycle-tests`: End-to-end system tests covering the full Prospect → Customer → Proposal → Task lifecycle

### Modified Capabilities

_None._

## Impact

- **Test files only**: New test files in test/integration/ and test/system/ directories
- **No production code changes**: This change adds tests only
- **May uncover bugs**: If integration tests fail, they may reveal issues requiring fixes in existing code
