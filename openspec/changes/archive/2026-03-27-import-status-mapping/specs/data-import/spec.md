## ADDED Requirements

### Requirement: Customer import routes rows to Customer or Prospect based on Tipo de cliente
The system SHALL read the `Tipo de cliente` column from the customer CSV and use its value to determine whether to create a Customer record (with the appropriate status) or skip the row with an actionable error.

The full mapping is:

| `Tipo de cliente` value             | Action                             |
|-------------------------------------|------------------------------------|
| `Potencial`                         | Skip — log prospect-required error |
| `Prospecto`                         | Skip — log prospect-required error |
| `Cliente activo`                    | Create Customer, status: `:active` |
| `Nuevo facturado`                   | Create Customer, status: `:active` |
| `Cliente inactivo por recuperar`    | Create Customer, status: `:inactive` |
| `Cliente recuperado`                | Create Customer, status: `:active` |
| `No contesta`                       | Create Customer, status: `:inactive` |
| `Descartar`                         | Create Customer, status: `:inactive` |

#### Scenario: Customer-type row uses mapped status
- **WHEN** an admin imports a customer CSV row where `Tipo de cliente` is `"Cliente activo"`
- **THEN** the created Customer has `status` equal to `:active`

#### Scenario: Inactive-type row uses inactive status
- **WHEN** an admin imports a customer CSV row where `Tipo de cliente` is `"No contesta"`
- **THEN** the created Customer has `status` equal to `:inactive`

#### Scenario: Prospect-type row is skipped with informative error
- **WHEN** an admin imports a customer CSV row where `Tipo de cliente` is `"Potencial"` or `"Prospecto"`
- **THEN** no record is created
- **AND** the import result includes a row-level error for that row number indicating that prospect-type records must be imported via the Prospects CSV import flow

#### Scenario: Unknown Tipo de cliente produces warning and nil status
- **WHEN** an admin imports a customer CSV row where `Tipo de cliente` contains a value not in the mapping
- **THEN** no record is created
- **AND** the import result includes a row-level warning identifying the unrecognised value

#### Scenario: Blank Tipo de cliente defaults to active
- **WHEN** an admin imports a customer CSV row where `Tipo de cliente` is blank
- **THEN** the created Customer has `status` equal to `:active` (existing default behaviour preserved)

### Requirement: Customer import maps Estrategia (KARE) to intention
The system SHALL read the `Estrategia (KARE)` column from the customer CSV and map it to the Customer `intention` field as follows:

| `Estrategia (KARE)` value | Customer `intention` |
|---------------------------|----------------------|
| `Mantener`                | `:keep`              |
| `Captar o atraer`         | `:attract`           |
| `Recuperar`               | `:recapture`         |
| `Expandir`                | `:expand`            |
| blank or unrecognised     | `nil`                |

#### Scenario: Import customer with keep strategy
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` is `"Mantener"`
- **THEN** the created Customer has `intention` equal to `:keep`

#### Scenario: Import customer with attract strategy
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` is `"Captar o atraer"`
- **THEN** the created Customer has `intention` equal to `:attract`

#### Scenario: Import customer with recapture strategy
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` is `"Recuperar"`
- **THEN** the created Customer has `intention` equal to `:recapture`

#### Scenario: Import customer with expand strategy
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` is `"Expandir"`
- **THEN** the created Customer has `intention` equal to `:expand`

#### Scenario: Blank KARE strategy leaves intention nil
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` is blank
- **THEN** the created Customer has `intention` equal to `nil`

#### Scenario: Unknown KARE strategy leaves intention nil
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` contains an unrecognised value
- **THEN** the created Customer has `intention` equal to `nil`
- **AND** no warning is added to the import result for this field (it is optional)

### Requirement: Proposal import maps extended Spanish status synonyms
The system SHALL map all of the following Spanish `Estado` values to the corresponding `Proposal` status on import, in addition to the existing mappings.

| Spanish value   | System status  |
|-----------------|----------------|
| `En espera`     | `under_review` |
| `Revisión`      | `under_review` |
| `Aprobado`      | `won`          |
| `Rechazado`     | `lost`         |
| `Cancelado`     | `cancelled`    |

#### Scenario: Import proposal with synonym "En espera"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"En espera"`
- **THEN** the parsed row has `status` equal to `"under_review"`

#### Scenario: Import proposal with synonym "Revisión"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Revisión"`
- **THEN** the parsed row has `status` equal to `"under_review"`

#### Scenario: Import proposal with synonym "Aprobado"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Aprobado"`
- **THEN** the parsed row has `status` equal to `"won"`

#### Scenario: Import proposal with synonym "Rechazado"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Rechazado"`
- **THEN** the parsed row has `status` equal to `"lost"`

#### Scenario: Import proposal with synonym "Cancelado"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Cancelado"`
- **THEN** the parsed row has `status` equal to `"cancelled"`

### Requirement: Proposal import warns on unknown status instead of failing
The system SHALL NOT raise a fatal error when a proposal CSV row contains an unrecognised `Estado` value. Instead it SHALL set the parsed row's `status` to `nil` and add a human-readable warning string to the row's `:warnings` array describing the unrecognised value.

#### Scenario: Unknown status yields nil and warning
- **WHEN** an admin imports a proposal CSV row where `Estado` contains a value not in the status mapping (e.g., `"Nuevo"`)
- **THEN** the parsed row has `status` equal to `nil`
- **AND** the parsed row's `:warnings` array includes a message identifying the unrecognised value (e.g., `"Unknown status 'Nuevo'"`)
- **AND** the import does not abort for other rows in the same file

#### Scenario: Row with nil status is reported as an error during execution
- **WHEN** the execution service processes a parsed proposal row that has `status` of `nil`
- **THEN** the row is not persisted to the database
- **AND** the import result's error list includes an entry for that row number indicating the status is blank

#### Scenario: Blank status still yields nil with no warning
- **WHEN** an admin imports a proposal CSV row where `Estado` is blank
- **THEN** the parsed row has `status` equal to `nil`
- **AND** the parsed row has no entries in `:warnings`

## MODIFIED Requirements

### Requirement: Proposal import raises error for unknown status value
**Note**: This requirement is superseded. Unknown status values now produce a row-level warning instead of a fatal parse error. See "Proposal import warns on unknown status instead of failing" above.

**Reason for modification**: The previous hard-fail behaviour aborted entire imports when any single row had an unrecognised status. The new behaviour allows valid rows to be imported while still surfacing the problematic value to the admin.

The system SHALL map all of the following Spanish `Estado` values to the corresponding `Proposal` status on import, in addition to the existing mappings.

| Spanish value   | System status  |
|-----------------|----------------|
| `En espera`     | `under_review` |
| `Revisión`      | `under_review` |
| `Aprobado`      | `won`          |
| `Rechazado`     | `lost`         |
| `Cancelado`     | `cancelled`    |

#### Scenario: Import proposal with synonym "En espera"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"En espera"`
- **THEN** the parsed row has `status` equal to `"under_review"`

#### Scenario: Import proposal with synonym "Revisión"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Revisión"`
- **THEN** the parsed row has `status` equal to `"under_review"`

#### Scenario: Import proposal with synonym "Aprobado"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Aprobado"`
- **THEN** the parsed row has `status` equal to `"won"`

#### Scenario: Import proposal with synonym "Rechazado"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Rechazado"`
- **THEN** the parsed row has `status` equal to `"lost"`

#### Scenario: Import proposal with synonym "Cancelado"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Cancelado"`
- **THEN** the parsed row has `status` equal to `"cancelled"`

### Requirement: Proposal import warns on unknown status instead of failing
The system SHALL NOT raise a fatal error when a proposal CSV row contains an unrecognised `Estado` value. Instead it SHALL set the parsed row's `status` to `nil` and add a human-readable warning string to the row's `:warnings` array describing the unrecognised value.

#### Scenario: Unknown status yields nil and warning
- **WHEN** an admin imports a proposal CSV row where `Estado` contains a value not in the status mapping (e.g., `"Nuevo"`)
- **THEN** the parsed row has `status` equal to `nil`
- **AND** the parsed row's `:warnings` array includes a message identifying the unrecognised value (e.g., `"Unknown status 'Nuevo'"`)
- **AND** the import does not abort for other rows in the same file

#### Scenario: Row with nil status is reported as an error during execution
- **WHEN** the execution service processes a parsed proposal row that has `status` of `nil`
- **THEN** the row is not persisted to the database
- **AND** the import result's error list includes an entry for that row number indicating the status is blank

#### Scenario: Blank status still yields nil with no warning
- **WHEN** an admin imports a proposal CSV row where `Estado` is blank
- **THEN** the parsed row has `status` equal to `nil`
- **AND** the parsed row has no entries in `:warnings`

## MODIFIED Requirements

### Requirement: Proposal import raises error for unknown status value
**Note**: This requirement is superseded. Unknown status values now produce a row-level warning instead of a fatal parse error. See "Proposal import warns on unknown status instead of failing" above.

**Reason for modification**: The previous hard-fail behaviour aborted entire imports when any single row had an unrecognised status. The new behaviour allows valid rows to be imported while still surfacing the problematic value to the admin.
