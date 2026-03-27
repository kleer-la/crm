## 1. Stimulus Controller

- [ ] 1.1 Create `app/javascript/controllers/multi_select_controller.js` with targets: `input`, `dropdown`, `pills`, `options`
- [ ] 1.2 Implement `connect()` to read existing hidden inputs and render pre-selected pills on page load
- [ ] 1.3 Implement open/close dropdown on input focus/click with click-outside-to-close (reuse pattern from `dropdown_controller.js`)
- [ ] 1.4 Implement type-to-filter: on `input` event filter option items by `data-label` (case-insensitive), hide matched items already selected, show "No results" when empty
- [ ] 1.5 Implement `selectOption(id, label)`: add pill element, add hidden input, remove option from dropdown, clear search input
- [ ] 1.6 Implement `removepill(id)`: remove pill element, remove corresponding hidden input, restore option in dropdown
- [ ] 1.7 Implement keyboard navigation: ArrowDown/ArrowUp moves highlighted option, Enter selects highlighted, Escape closes dropdown, Backspace in empty input removes last pill
- [ ] 1.8 Ensure a blank hidden input (`value=""`) is present when no consultants are selected so Rails clears the association on submit

## 2. Shared Partial

- [ ] 2.1 Rewrite `app/views/shared/_consultant_multi_select.html.erb` to use the new Stimulus controller (`data-controller="multi-select"`)
- [ ] 2.2 Render each consultant as a hidden option `div` with `data-multi-select-target="option"`, `data-value`, `data-label` attributes
- [ ] 2.3 Render pills container (`data-multi-select-target="pills"`) and search input (`data-multi-select-target="input"`)
- [ ] 2.4 Render dropdown container (`data-multi-select-target="dropdown"`) with ARIA attributes (`role="listbox"`, `aria-expanded`)
- [ ] 2.5 Pass `field` and `model_name` as partial locals so hidden input names are correct for each form

## 3. Styling

- [ ] 3.1 Style the pills container as a bordered input-like box using Tailwind classes consistent with the rest of the form fields
- [ ] 3.2 Style individual pills with a label and × button (indigo background, white text, rounded)
- [ ] 3.3 Style the dropdown list with shadow, border, white background, and hover/focus highlight on options
- [ ] 3.4 Style the "No results" state in the dropdown (muted italic text)

## 4. Integration & Tests

- [ ] 4.1 Verify `proposals/_form.html.erb`, `customers/_form.html.erb`, and `prospects/_form.html.erb` still call the shared partial without changes
- [ ] 4.2 Write a system/integration test for the Proposal form: add a collaborator, submit, verify it persists
- [ ] 4.3 Write a system/integration test for removing a collaborator: start with one selected, remove it, submit, verify it is cleared
- [ ] 4.4 Write a system/integration test for the search filter: type partial name, verify dropdown filters correctly
- [ ] 4.5 Run `bin/ci` and ensure all tests, style, and security checks pass
