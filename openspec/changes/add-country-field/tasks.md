## 1. Schema and domain model

- [ ] 1.1 Add nullable `country` columns to `prospects` and `customers` and update schema snapshots
- [ ] 1.2 Update Prospect and Customer model tests and factories to cover the optional country attribute
- [ ] 1.3 Update `ConvertProspectService` and its tests so prospect conversion copies `country` to the created Customer

## 2. Manual record flows

- [ ] 2.1 Update Prospect and Customer strong params to accept `country`
- [ ] 2.2 Add `country` to the Prospect and Customer create/edit forms
- [ ] 2.3 Display `country` on the Prospect and Customer detail pages
- [ ] 2.4 Add controller or integration coverage for creating and updating Prospects and Customers with and without country values

## 3. Import mapping and verification

- [ ] 3.1 Update customer CSV parsing to map `País/es` to `country` while continuing to ignore `País facturador`
- [ ] 3.2 Update customer import execution to persist the parsed `country` value
- [ ] 3.3 Add parser and execution tests covering populated, blank, and ignored billing-country import cases
- [ ] 3.4 Run `bin/ci` to verify the full change