## Architecture

### CannedResponse model

New `canned_responses` table with fields: `name` (string, required), `content` (text, required), `key` (string, optional unique — used for system lookups like auto-disconnect), `position` (integer, for ordering).

System canned responses (those with a `key`) are distinguished from user-created ones. The `auto_disconnect` key is used by the background job to find the disconnect message template.

### Admin CRUD

Standard Rails CRUD under `Admin::CannedResponsesController` at `/admin/canned_responses`. Admins can create, edit, reorder, and delete quick replies. The `key` field is not exposed in the admin form (system-managed).

### Reply composer integration

The reply composer partial queries `CannedResponse.ordered` and renders a "Quick replies" dropdown button above the message input. Selecting a canned response fills the textarea. Implemented via new Stimulus targets and actions on the existing `reply-composer` controller.

### Auto-disconnect job

`ConversationAutoDisconnectJob` runs on a Solid Queue recurring schedule (configured in `config/recurring.yml`). It finds open conversations with no recent messages and sends the auto-disconnect canned response content as an outbound message.

### Reply composer fix

Added `turbo:submit-end` event handler to clear the message input after successful form submission, preventing accidental double-sends.
