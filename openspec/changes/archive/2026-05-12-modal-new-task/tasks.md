## 1. Tasks section partial and Turbo Frame

- [x] 1.1 Extract tasks list markup from `customers/show.html.erb`, `prospects/show.html.erb`, and `proposals/show.html.erb` into a shared partial `app/views/tasks/_section.html.erb` that accepts a `linkable` local variable
- [x] 1.2 Wrap the tasks section on each show page in `<turbo-frame id="<%= dom_id(linkable, :tasks) %>">` and render the new partial
- [x] 1.3 Write integration tests verifying the tasks Turbo Frame is present with the correct DOM ID on each show page

## 2. Stimulus modal controller

- [x] 2.1 Create `app/javascript/controllers/modal_controller.js` with targets for the `<dialog>` element; open the dialog on `turbo:frame-load` and close it when the frame content is cleared
- [x] 2.2 Wire backdrop-click dismissal: close the dialog when a `click` event target is the `<dialog>` element itself (outside the content panel)
- [x] 2.3 Register the controller in `app/javascript/controllers/index.js`

## 3. Global modal shell in application layout

- [x] 3.1 Add a `<turbo-frame id="modal">` containing a centered `<dialog>` element to `app/views/layouts/application.html.erb`, wired to the `modal` Stimulus controller

## 4. Task form lazy-loading in modal

- [x] 4.1 Wrap the content in `app/views/tasks/new.html.erb` in `<turbo-frame id="modal">` so responses load into the modal frame
- [x] 4.2 Update "New task" links on `customers/show.html.erb`, `prospects/show.html.erb`, and `proposals/show.html.erb` to add `data: { turbo_frame: "modal" }`

## 5. Controller Turbo Stream response on success

- [x] 5.1 Update `TasksController#create` to use `respond_to` — on `format.turbo_stream` success: render two streams: clear the modal frame (`turbo_stream.update("modal", "")`) and replace the tasks section frame (`turbo_stream.replace(dom_id(@task.linkable, :tasks), partial: "tasks/section", locals: { linkable: @task.linkable })`)
- [x] 5.2 Ensure `format.html` fallback continues to redirect to the task show page (for the `tasks/index` full-page flow)
- [x] 5.3 Ensure validation errors re-render the form inside the modal frame (Turbo handles this automatically when the controller renders `:new` with `status: :unprocessable_entity`)

## 6. Tests

- [x] 6.1 Write controller tests for `TasksController#create` verifying Turbo Stream response on success (modal cleared, tasks frame replaced)
- [x] 6.2 Write controller tests verifying validation errors return the form with `422 Unprocessable Entity`
- [x] 6.3 Run `bin/ci` and confirm all tests, style, and security checks pass
