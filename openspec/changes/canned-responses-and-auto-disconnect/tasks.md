## 1. CannedResponse Model & Migration

- [x] 1.1 Create migration for `canned_responses` table (name, content, key, position) with unique partial index on key
- [x] 1.2 Create CannedResponse model with validations, `ordered` scope, `system?` helper, and `auto_disconnect` class method
- [x] 1.3 Create factory and model tests

## 2. Admin CRUD

- [x] 2.1 Create `Admin::CannedResponsesController` with index, new, create, edit, update, destroy actions
- [x] 2.2 Create admin views (index, new, edit, _form partial)
- [x] 2.3 Add `resources :canned_responses` route under admin namespace
- [x] 2.4 Add "Quick replies" link to admin sidebar
- [x] 2.5 Create controller tests

## 3. Reply Composer Integration

- [x] 3.1 Add canned response dropdown to `_reply_composer.html.erb` (queries CannedResponse.ordered, renders button + dropdown menu)
- [x] 3.2 Add Stimulus targets and actions to reply-composer controller (toggleCanned, closeCanned, selectCanned, click-outside-to-close)
- [x] 3.3 Fix: clear message input after successful send via `turbo:submit-end` → `resetAfterSubmit`

## 4. Auto-Disconnect Job

- [x] 4.1 Create `ConversationAutoDisconnectJob`
- [x] 4.2 Add recurring schedule entry in `config/recurring.yml`

## 5. Seed Data

- [x] 5.1 Seed auto-disconnect canned response (key: "auto_disconnect")
- [x] 5.2 Seed sample conversations for development testing
