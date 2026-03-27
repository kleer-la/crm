### Requirement: Pill-based collaborator selection
The system SHALL display the collaborating consultants field as a pill-based multi-select widget. Selected consultants SHALL appear as labelled pills above a text input. Unselected consultants SHALL be available via a filterable dropdown that opens when the user clicks or focuses the input area.

#### Scenario: Selected consultants show as pills
- **WHEN** a form is loaded with existing collaborating consultants
- **THEN** each selected consultant appears as a removable pill with their display name

#### Scenario: Empty state shows placeholder
- **WHEN** no collaborating consultants are selected
- **THEN** the input shows a placeholder "Search consultants…" text

### Requirement: Type-to-filter search
The system SHALL filter the consultant dropdown in real time as the user types. Filtering SHALL be case-insensitive and match against the consultant display name. Options already selected SHALL be excluded from the dropdown.

#### Scenario: Dropdown filters on input
- **WHEN** the user types characters into the search input
- **THEN** the dropdown shows only consultants whose names contain the typed text (case-insensitive)

#### Scenario: Selected consultants are excluded
- **WHEN** a consultant has already been selected
- **THEN** that consultant does NOT appear in the dropdown options

#### Scenario: No results message
- **WHEN** the typed text matches no remaining consultants
- **THEN** the dropdown shows "No results" text

### Requirement: Add and remove collaborators
The system SHALL allow adding a collaborator by clicking their name in the dropdown. The system SHALL allow removing a collaborator by clicking the × on their pill.

#### Scenario: Clicking option adds pill
- **WHEN** the user clicks a consultant in the dropdown
- **THEN** the consultant is added as a pill, a hidden input is created with their ID, and the dropdown closes

#### Scenario: Clicking × removes pill
- **WHEN** the user clicks the × on a collaborator pill
- **THEN** the pill and its corresponding hidden input are removed

### Requirement: Keyboard navigation
The system SHALL support keyboard interaction for accessibility. Arrow keys SHALL move focus through dropdown options. Enter or Space SHALL select the focused option. Escape SHALL close the dropdown. Backspace in an empty input SHALL remove the last pill.

#### Scenario: Arrow keys navigate options
- **WHEN** the dropdown is open and the user presses ArrowDown or ArrowUp
- **THEN** focus moves to the next or previous option in the list

#### Scenario: Enter selects focused option
- **WHEN** an option in the dropdown has keyboard focus and the user presses Enter
- **THEN** that consultant is selected (same outcome as clicking)

#### Scenario: Escape closes dropdown
- **WHEN** the dropdown is open and the user presses Escape
- **THEN** the dropdown closes and focus returns to the search input

#### Scenario: Backspace removes last pill
- **WHEN** the search input is empty and the user presses Backspace
- **THEN** the last selected pill and its hidden input are removed

### Requirement: Form submission compatibility
The system SHALL maintain compatibility with existing Rails form submission. For each selected collaborator the widget SHALL produce a hidden input with `name="[model][collaborating_consultant_ids][]"` and the consultant's ID as value. When no collaborators are selected the widget SHALL emit a single blank hidden input so Rails clears the association.

#### Scenario: Hidden inputs submitted with form
- **WHEN** the user submits a form with two collaborators selected
- **THEN** the params contain `collaborating_consultant_ids` with both IDs

#### Scenario: Clearing all collaborators
- **WHEN** all pills are removed and the form is submitted
- **THEN** the params contain a blank `collaborating_consultant_ids` causing Rails to clear the association
