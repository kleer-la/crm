## Why

Creating tasks from customer, prospect, and proposal show pages currently navigates away to a full-page form, breaking the user's context. A modal dialog keeps users on the originating record while the task is created and immediately visible in the updated task list.

## What Changes

- "New task" links on customer, prospect, and proposal show pages open a centered modal dialog instead of navigating to `/tasks/new`
- The tasks section on each show page becomes a Turbo Frame so it can be refreshed in-place after a task is created
- Successful task creation closes the modal and refreshes the tasks list on the originating show page without a full page reload
- Validation errors re-render the form within the modal (no navigation)
- The "New task" button on `tasks/index` is unchanged — it continues to navigate to the full page

## Capabilities

### New Capabilities
- `task-modal`: Modal dialog for creating tasks from entity show pages, including Turbo Frame lazy-loading, Stimulus dialog controller, and Turbo Stream response on success

### Modified Capabilities
- `tasks`: Tasks section on show pages gains Turbo Frame wrapper to support in-place refresh after modal creation

## Impact

- `app/javascript/controllers/modal_controller.js` — new Stimulus controller
- `app/views/layouts/application.html.erb` — add global modal Turbo Frame shell
- `app/views/tasks/new.html.erb` — wrap content in `<turbo-frame id="modal">`
- `app/controllers/tasks_controller.rb` — `create` responds with Turbo Streams on success
- `app/views/tasks/_section.html.erb` — new shared partial extracted from show pages
- `app/views/customers/show.html.erb`, `app/views/prospects/show.html.erb`, `app/views/proposals/show.html.erb` — tasks section replaced with Turbo Frame + partial, "New task" link targets modal frame
