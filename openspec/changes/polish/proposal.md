## Why

The CRM application layout was built with a sidebar nav and top bar but needs refinement for mobile/tablet use. Flash messages and form error displays also need consistent styling across all modules to provide a polished user experience.

## What Changes

- Audit and fix mobile-responsive layout using Tailwind CSS breakpoints across all views (sidebar collapse, table overflow, form stacking)
- Add consistent flash message styling (success, error, notice) across all controllers and views
- Standardize form error display across all form partials with inline field errors and a summary block

## Capabilities

### New Capabilities
- `responsive-layout`: Mobile-responsive Tailwind breakpoints for sidebar, tables, forms, and dashboard across all modules
- `flash-and-errors`: Consistent flash message and form error display styling across the application

### Modified Capabilities

_None._

## Impact

- **Views**: All existing views updated for responsive breakpoints; flash message partial added to application layout
- **CSS**: Tailwind utility classes added/adjusted — no custom CSS
- **Controllers**: Flash messages standardized across all controllers (most already set flash; ensure consistency)
- **No new models or migrations**
