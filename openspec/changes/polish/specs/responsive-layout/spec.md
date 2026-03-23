## ADDED Requirements

### Requirement: Sidebar collapses on mobile
The sidebar navigation SHALL collapse to a hamburger menu on screens narrower than 768px.

#### Scenario: Mobile viewport
- **WHEN** the viewport width is less than 768px
- **THEN** the sidebar is hidden and a hamburger menu icon is displayed in the top bar that toggles the sidebar

#### Scenario: Desktop viewport
- **WHEN** the viewport width is 768px or wider
- **THEN** the sidebar is displayed as a fixed side panel

### Requirement: Tables scroll horizontally on small screens
All data tables SHALL be horizontally scrollable on screens where the table width exceeds the viewport.

#### Scenario: Narrow viewport with wide table
- **WHEN** a data table is wider than the viewport
- **THEN** the table container allows horizontal scrolling without breaking the page layout

### Requirement: Forms stack vertically on mobile
Form fields SHALL stack vertically on screens narrower than 768px, regardless of their desktop layout.

#### Scenario: Form on mobile viewport
- **WHEN** a form is displayed on a viewport narrower than 768px
- **THEN** all form fields are stacked in a single column

### Requirement: Dashboard responsive layout
The dashboard cards and widgets SHALL reflow to a single column on mobile viewports.

#### Scenario: Dashboard on mobile
- **WHEN** the dashboard is viewed on a viewport narrower than 768px
- **THEN** all dashboard cards stack vertically in a single column
