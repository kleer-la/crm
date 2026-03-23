## Example: OpenSpec Test Coverage Analysis

**Change:** initial-feature-set
**Scope:** groups 1-8
**Test Suite:** 206 tests, 576 assertions, 100% pass rate

### Requirements Coverage Summary
- ✅ **Well Covered**: 32 requirements (78%)
- ⚠️ **Partial Coverage**: 6 requirements (15%)
- ❌ **Missing Coverage**: 3 requirements (7%)

### Detailed Analysis by Group

#### Group 3: Authentication & Authorization
**Status:** EXCELLENT (100% coverage)

**✅ Covered Requirements:**
- Requirement: Google OAuth login with self-registration
  - ✅ Scenario: First-time Google sign-in (test: `oauth callback creates new user as pending`)
  - ✅ Scenario: Returning user with assigned role (test: `oauth callback signs in existing active user`)
  - ✅ Scenario: Returning user still pending (test: `oauth callback redirects pending user to pending page`)
  - ✅ Scenario: Deactivated user signs in (test: `oauth callback rejects deactivated user`)

- Requirement: Pending users have no app access
  - ✅ Scenario: Pending user attempts to access a page (test: `pending user is redirected to pending approval from protected pages`)

#### Group 5: Shared Layout & Components
**Status:** MINIMAL (20% coverage)

**❌ Missing Requirements:**
- Requirement: Reusable form partials
  - ❌ Scenario: Text input, select, multi-select, date picker, currency input, URL input with validation
- Requirement: Reusable sortable/filterable table partial
  - ❌ Scenario: Table with Stimulus controller for filter controls
- Requirement: Activity log timeline partial
  - ❌ Scenario: Chronological entries display

#### Group 6: Activity Log System
**Status:** EXCELLENT (95% coverage)

**✅ Covered Requirements:**
- Requirement: Automatic system event logging
  - ✅ Scenario: Status change logged (tests: `prospect status change auto-logs`, `customer status change auto-logs`)
  - ✅ Scenario: Record creation logged (tests: `prospect creation auto-logs`, `customer creation auto-logs`)
  - ✅ Scenario: Assignment change logged (tests: `responsible consultant change auto-logs`)

**⚠️ Partially Covered Requirements:**
- Requirement: Activity log immutability
  - ✅ Scenario: Attempt to edit an activity log entry (test: `immutable after persisted - cannot update`)
  - ❌ Scenario: Attempt to delete an activity log entry (missing test)

### Test Quality Assessment

**Strengths:**
- Comprehensive model validation testing
- Integration tests for critical workflows
- Good edge case coverage
- Consistent factory usage

**Gaps:**
- No view/component tests for UI elements
- Missing system-level integration tests
- Limited error handling edge case testing

### Recommendations

**High Priority:**
1. Add view tests for shared components (forms, tables, timeline)
2. Implement system tests for complete user journeys
3. Add tests for activity log deletion prevention

**Medium Priority:**
1. Add performance tests for search and filtering
2. Implement accessibility testing
3. Add mobile responsiveness verification