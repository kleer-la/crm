## Context

Three show pages (customers, prospects, proposals) each have an inline tasks section with a "New task" link that navigates to `/tasks/new` as a full page. The `TasksController#new` action pre-sets `linkable_type` and `linkable_id` from query params, and the form hides the linkable selector when both are present.

The tasks sections are currently rendered as inline ERB in each show template — no partials, no Turbo Frames. The controller's `create` action always redirects to the task show page on success.

No modal infrastructure exists in the app yet.

## Goals / Non-Goals

**Goals:**
- Open a centered `<dialog>` modal when "New task" is clicked on customer/prospect/proposal show pages
- Lazy-load the form into the modal via Turbo Frame (no pre-rendering)
- On success: close modal + refresh the tasks list on the originating show page in-place
- On validation error: re-render form inside the modal
- Establish a reusable modal shell pattern for future use

**Non-Goals:**
- Modal for `tasks/index` "New task" — stays full-page
- Editing tasks via modal
- Any other entity's create flow

## Decisions

### 1. Global Turbo Frame modal shell in application layout

A single `<turbo-frame id="modal">` lives in `application.html.erb`, containing a `<dialog>` element and a Stimulus `modal` controller. When the frame loads content, the controller calls `dialog.showModal()`. When cleared, it calls `dialog.close()`.

**Why global over per-page:** The modal shell will be reused for future flows (e.g., quick-add proposals, contacts). Putting it in the layout once is cleaner than duplicating per show page. A single frame ID convention is enough — only one modal is ever open at a time in this app.

**Alternative considered:** Turbo Stream appending a `<dialog>` on demand. Rejected — more complex, requires a stream action before the form even opens, and doesn't compose as cleanly with Turbo Frame navigation.

### 2. Turbo Frame lazy-loading the form

The "New task" link gets `data-turbo-frame="modal"`. Clicking it fires a GET to `/tasks/new?linkable_type=...&linkable_id=...`. The `new` action's view wraps its content in `<turbo-frame id="modal">`, which Turbo swaps into the layout frame.

**Why lazy over pre-rendered hidden form:** The form references live data (consultants list, linkable record). Lazy-loading keeps it fresh without extra complexity. The network round-trip is negligible on an internal tool.

### 3. Turbo Stream response on successful create

`TasksController#create` detects a Turbo request and responds with two streams:
1. `turbo_stream.update("modal", "")` — clears the frame, which the Stimulus controller detects to close the dialog
2. `turbo_stream.replace("tasks_<type>_<id>", partial: "tasks/section", locals: { linkable: @task.linkable })` — refreshes the tasks list in-place

**Why Turbo Stream over redirect:** A redirect inside a Turbo Frame would try to load the target page into the frame. Breaking out of the frame (`data-turbo-frame: "_top"`) would cause a full navigation, losing the show page context. The Turbo Stream approach keeps everything clean — close modal, update list, done.

**Format detection:** The controller uses `respond_to` with `format.turbo_stream` / `format.html`. The HTML fallback (for the `tasks/index` path) continues to redirect as before.

### 4. Tasks section extracted to a shared partial

The tasks list markup is extracted from all three show pages into `app/views/tasks/_section.html.erb`, accepting a `linkable` local. Each show page wraps it in:

```erb
<turbo-frame id="tasks_<%= dom_id(linkable, :tasks) %>">
  <%= render "tasks/section", linkable: linkable %>
</turbo-frame>
```

`dom_id(linkable, :tasks)` produces `tasks_customer_42`, `tasks_prospect_7`, `tasks_proposal_99` — predictable IDs the controller can construct from the saved task's `linkable`.

### 5. Stimulus modal controller

The controller observes the Turbo Frame's content via a MutationObserver (or the `turbo:frame-load` event) to call `showModal()` when content arrives, and `close()` when the frame is cleared. It also wires:
- ESC key: native `<dialog>` behavior handles this automatically
- Backdrop click: listens for `click` on the `<dialog>` element and closes if the click target is the dialog itself (outside the content panel)

**Native `<dialog>` over custom overlay:** The HTML dialog element provides focus trapping, ESC handling, and backdrop rendering for free. No accessibility work needed beyond the element itself.

## Risks / Trade-offs

- **Tasks section query is inline in the partial** — the partial runs `linkable.tasks.where(...)` directly. For 6-15 users this is fine; if task counts grow large it's easy to add a scope later.
- **Modal frame conflict** — if two modals were ever needed simultaneously, the global frame approach breaks. This is acceptable for the current app scope; future multi-modal needs would require revisiting.
- **`turbo:frame-load` vs MutationObserver** — Turbo fires `turbo:frame-load` on the frame element after content loads. This is the cleanest hook; MutationObserver is a fallback if event timing proves unreliable.

## Migration Plan

No data migrations. The change is purely frontend/controller. Deploy as a single PR; no feature flag needed. Rollback is reverting the PR — no state is affected.
