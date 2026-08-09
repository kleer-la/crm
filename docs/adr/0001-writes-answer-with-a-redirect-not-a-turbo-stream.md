# Writes answer with a redirect, not a Turbo Stream

Turbo Streams and frame-scoped submits only apply when the DOM target they name is
present on the page that submitted. When it isn't, Turbo applies nothing and the user
sees a dead button — the write succeeds server-side with no visible feedback. We had
two such bugs at once (creating a Task from `/tasks/new`, and assigning a role from
admin user management), so writes in this app answer with an ordinary redirect, and
forms rendered inside a Turbo Frame break out with `data-turbo-frame="_top"`.
Controllers name no DOM ids.

## Considered options

**Give the section-refresh contract an owner.** The obvious Hotwire move is to keep
streaming and put the DOM id, the partial, and the list of pages that may host the
modal behind one module. Rejected: the Task section was the *only* caller. Contact and
Touchpoint sections already refresh by redirect and were not asking for it. A seam with
one adapter is hypothetical — the interface (target id + partial + hosting pages) would
have been about as complex as the implementation it hid.

**Drop the modal entirely.** Unnecessary. Opening the modal is a GET into
`<turbo-frame id="modal">` and was never the problem; only the write response was.
Displaying in a frame and answering a write with a stream are separable, and only the
second one produced bugs.

## Consequences

- Creating or editing a Task lands on the linked Prospect/Customer/Proposal, not the
  Task page, so the new Task is visible in its section. `mark_done`, `cancel`, and
  `reassign` still return to the Task page — they are invoked from there.
- A validation error in the Task modal renders the standalone form page with its errors
  rather than re-rendering the dialog. The modal is a shortcut; on error you graduate to
  the real page.
- Task writes cost a full page load and lose scroll position. Acceptable for a 6-15
  person team, and already true of Contacts and Touchpoints.
- `turbo_frame_request?` remains correct for **GET** rendering, where it genuinely does
  tell you the response lands in a frame. Match on `turbo_frame_request_id == "modal"`
  when more than one frame can request the same page. Never use either to decide the
  shape of a **write** response.

## When to reopen this

A second modal-driven section — Contacts or Proposals on a record page — would make the
refresh seam real rather than hypothetical, and streaming worth reconsidering. Until
then, `test/integration/turbo_frame_contract_test.rb` guards the invariant that every
frame and stream target actually exists in the response meant to contain it.
