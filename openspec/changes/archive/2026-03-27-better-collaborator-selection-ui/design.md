## Context

The collaborating consultants field on Proposals, Customers, and Prospects currently renders as a plain checkbox list via `app/views/shared/_consultant_multi_select.html.erb`. The team is small (6–15 people) so the list is short today, but the checkbox UI is verbose and inconsistent with more modern form patterns elsewhere. No external JS libraries are in use — the project uses Hotwire (Turbo + Stimulus) with plain importmaps.

## Goals / Non-Goals

**Goals:**
- Replace the checkbox list with a pill-based multi-select with type-to-filter search
- Keep the hidden `collaborating_consultant_ids[]` inputs so backend behaviour is unchanged
- Implement as a single shared partial + Stimulus controller used by all three forms
- No server round-trips for search — filter client-side (list is tiny)
- Keyboard accessible: arrow keys to navigate dropdown, Enter/Space to select, Escape to close, Backspace to remove last pill

**Non-Goals:**
- Async/AJAX loading of options (unnecessary for ≤15 users)
- Third-party select libraries (Select2, Tom Select, Choices.js)
- Changing the backend association or controller logic
- Supporting other multi-select fields beyond collaborating consultants right now

## Decisions

### 1. Pure Stimulus controller, no JS library

**Decision:** Write a bespoke `multi_select_controller.js`.

**Rationale:** The option list is embedded in the page at render time (≤15 users). A Stimulus controller is ~80 lines, zero extra dependencies, and fits the project's existing pattern (see `dropdown_controller.js`). Tom Select / Choices.js would add ~30 KB and a build step.

**Alternative considered:** Tom Select with importmap CDN pin — rejected because it requires CSS import plumbing and adds an external dependency for a trivial use case.

### 2. Embed options as data attributes, filter in-memory

**Decision:** Render all consultants into the partial as `data-value` / `data-label` items in a hidden list; the Stimulus controller reads these on `connect()` and filters them on each keystroke.

**Rationale:** Avoids any AJAX endpoint. With ≤15 users the full list is tiny. Keeps the partial self-contained.

### 3. Reuse shared partial unchanged

**Decision:** The three consumer views (`proposals/_form`, `customers/_form`, `prospects/_form`) already call `render "shared/consultant_multi_select"` — no changes needed there.

### 4. Hidden inputs mirror Rails collection_check_boxes contract

**Decision:** Each selected consultant produces a `<input type="hidden" name="[model][collaborating_consultant_ids][]" value="[id]">` element, matching what `collection_check_boxes` produced. Rails controller params are unchanged.

## Risks / Trade-offs

- **Accessibility gap** → Mitigation: implement keyboard nav (arrow keys, Enter, Escape, Backspace) and `aria-expanded` / `role="listbox"` / `role="option"` attributes on the dropdown
- **JS disabled** → Mitigation: the partial falls back gracefully — without JS the Stimulus controller never connects and the form is unusable for this field. Acceptable given this is an internal tool.
- **Turbo Drive cache** → Mitigation: use `data-turbo-permanent` is not needed; pills re-render from form state on navigation. Controller `connect()` re-initialises from existing hidden inputs.
