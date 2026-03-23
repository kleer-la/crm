## 1. Cross-Model Constraint Tests

- [ ] 1.1 Write integration tests for company_name uniqueness across Prospects and Customers (both directions)
- [ ] 1.2 Write integration tests for email uniqueness across Prospect primary_contact_email and Customer Contact emails (both directions)
- [ ] 1.3 Write integration tests verifying converted Prospect is read-only (update rejected, show page displays correctly with link to Customer)

## 2. Conversion & Re-linking Tests

- [ ] 2.1 Write integration tests verifying Proposal re-linking on Prospect-to-Customer conversion (all Proposals transferred, linkable updated)
- [ ] 2.2 Write integration tests verifying Customer total_revenue calculation after conversion with Won Proposals

## 3. Full Lifecycle System Tests

- [ ] 3.1 Write system test for complete lifecycle: create Prospect → qualify → create Proposal → mark Won → convert to Customer → verify state
- [ ] 3.2 Write system test for Task lifecycle: create Task on Prospect → convert Prospect → complete Task → verify activity logs
- [ ] 3.3 Write system test for activity log continuity across Prospect conversion and Proposal status changes
