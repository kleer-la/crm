## Why

The CRM's current UI was built with functional Tailwind classes but feels generic and dated — flat gray tables, undifferentiated status badges, a heavy dark sidebar, and no visual hierarchy between elements. As a tool used daily by the consulting team, it should feel professional and modern, improving scan-ability and reducing cognitive load.

## What Changes

- Replace the dark `bg-gray-800` sidebar with a lighter `slate-700` + indigo accent sidebar — cleaner, less oppressive for long sessions
- Swap the generic `blue-600` accent throughout for `indigo-600` — more distinctive and design-intentional
- Introduce **color-coded status badges** so prospect/customer status is scannable at a glance without reading each label
- Redesign **page headers** with icon-backed action buttons (`outline` style for secondary, `solid` for primary)
- Modernize the **filter bar** — slimmer, borderless, lower-weight feel instead of a full card
- Upgrade **table rows** with company initials avatar, tighter row height, and a more pronounced hover state
- Improve **empty states** with an icon, descriptive message, and a CTA button
- Elevate **flash messages** with an icon + dismiss button (dismissible toast pattern)
- Standardize all of the above across every index/show/form screen

## Capabilities

### New Capabilities

- `ui-design-system`: A consistent set of Tailwind-based design tokens and shared partials (status badges, page headers, filter bars, empty states, flash toasts) applied uniformly across all CRM screens

### Modified Capabilities

_None — no spec-level behavioral requirements change; this is purely a UI/visual layer overhaul._

## Impact

- **Views**: All index, show, new, and edit views updated; shared partials (`_filter_bar`, `_flash`, `_sidebar`, `_top_bar`) updated or replaced
- **Helpers**: `status_badge` and `sidebar_link` helpers updated with new color logic; `role_badge` updated
- **CSS**: Tailwind utility classes only — no custom CSS files
- **JavaScript**: Existing Stimulus controllers (`dropdown`, `sidebar`, `filter`, `search`) unchanged; flash dismiss handled by existing or minimal Stimulus controller
- **No new models, migrations, or routes**
