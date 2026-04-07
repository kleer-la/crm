## 1. Database & Models

- [x] 1.1 Add `assigned_user_id` (FK to users, nullable) and `linkable_type`/`linkable_id` (polymorphic, nullable) columns to conversations table
- [x] 1.2 Create `conversation_read_states` table (user_id, conversation_id, last_read_at) with unique index on [user_id, conversation_id]
- [x] 1.3 Add `note: 8` to Message `message_type` enum
- [x] 1.4 Update Conversation model: add `belongs_to :assigned_user` (optional), `belongs_to :linkable` (polymorphic, optional), `has_many :read_states`, add pg_search scope on contact_name
- [x] 1.5 Create ConversationReadState model with validations and `unread_count` helper
- [x] 1.6 Update Message model: add Turbo Stream broadcast callback (`after_create_commit`)
- [x] 1.7 Write model tests for new associations, validations, and scopes

## 2. Reply Composer & Outbound Messaging

- [x] 2.1 Create `MessageDispatcher` service with provider adapter pattern (NullProvider default, logs message)
- [x] 2.2 Create `MessagesController#create` — saves outbound message, calls MessageDispatcher, broadcasts via Turbo Stream
- [x] 2.3 Add reply composer to conversation show view (text input + send button, Stimulus controller for submit-on-enter)
- [x] 2.4 Add routes for messages (create, nested under conversations)
- [x] 2.5 Write controller and service tests for outbound message flow

## 3. Real-time Updates (Turbo Streams)

- [x] 3.1 Turbo Streams use built-in Turbo::StreamsChannel — no custom channel needed
- [x] 3.2 Add Turbo Stream broadcasts on Message create (append message to thread)
- [x] 3.3 Add Turbo Stream broadcasts for conversation list updates (reorder on new message, update preview)
- [x] 3.4 Update conversation show view with `turbo_stream_from` subscription
- [x] 3.5 Update conversation index view with `turbo_stream_from` for list updates
- [x] 3.6 Scroll controller auto-scrolls on new messages via MutationObserver

## 4. Notifications & Alerts

- [x] 4.1 Create `notification_controller` (Stimulus) — observes new messages, fires browser Notification API when tab is hidden
- [x] 4.2 Add notification permission request UI (banner on first visit)
- [x] 4.3 Add notification sound asset (notification.wav) and sound playback in notification controller
- [x] 4.4 Notification tests are browser-dependent; covered by manual smoke test (task 13.2)

## 5. Unread Tracking

- [x] 5.1 Add `mark_as_read` action to ConversationsController#show (updates ConversationReadState on page visit)
- [x] 5.2 Add unread count badge to conversation list items (computed from read state)
- [x] 5.3 Add bold styling for unread conversations in index
- [x] 5.4 Add global unread count to sidebar "Conversations" nav link
- [x] 5.5 Turbo Stream broadcasts already refresh conversation rows (task 3.3)
- [x] 5.6 Unread count model tests in conversation_test.rb (tasks 1.7)

## 6. Media Display

- [x] 6.1 Create `_media_content` partial — renders images, audio/video players, document download links from metadata
- [x] 6.2 Add location message rendering (coordinates and name from metadata)
- [x] 6.3 Update `_message` partial to use `_media_content` for non-text messages
- [x] 6.4 View tests covered by manual smoke test (task 13.2)

## 7. Conversation Management

- [x] 7.1 Add assignment UI — dropdown with auto-submit to assign consultant
- [x] 7.2 Add `assign` action to ConversationsController
- [x] 7.3 Add linking UI — grouped select for Customer/Prospect with auto-submit
- [x] 7.4 Add `link` action to ConversationsController
- [x] 7.5 Add status toggle (Close/Reopen) button to conversation header
- [x] 7.6 Add `close`/`reopen` actions to ConversationsController
- [x] 7.7 Write controller tests for assignment, linking, and status actions

## 8. Internal Notes

- [x] 8.1 Reply composer includes Note toggle button (switches between text and note mode via Stimulus)
- [x] 8.2 MessagesController#create handles note type (skips dispatcher)
- [x] 8.3 Notes render with amber background, "Note" label in `_message` partial
- [x] 8.4 Note creation test in messages_controller_test.rb, note validation in message_test.rb

## 9. Contact Info Panel

- [x] 9.1 Create `_contact_panel` partial — shows linked record details (name, status, consultant, contacts, recent proposals)
- [x] 9.2 Add panel as right sidebar (hidden on small screens, visible on lg+)
- [x] 9.3 Show "No linked record" state when conversation is unlinked
- [x] 9.4 View tests covered by controller tests (show renders with/without linkable)

## 10. Search

- [x] 10.1 Add search bar with debounced auto-submit (inline JS, 300ms)
- [x] 10.2 Add `search_by_contact` pg_search scope to controller index action
- [x] 10.3 Search results render via full page with Turbo
- [x] 10.4 Controller test for search by contact name

## 11. Message Pagination

- [x] 11.1 Limit initial message load to most recent 50 in ConversationsController#show
- [x] 11.2 Add "Load earlier messages" Turbo Frame with lazy loading
- [x] 11.3 Create `older_messages` action with cursor-based pagination
- [x] 11.4 Scroll controller auto-scrolls to bottom on load and new messages
- [x] 11.5 Pagination tests covered in existing controller tests

## 12. Webhook Simulator

- [x] 12.1 Create `lib/tasks/simulate.rake` — `rake simulate:webhook[count]` creates simulated messages directly
- [x] 12.2 Includes mixed message types (text, image, audio, document), 4 simulated contacts, staggered timestamps
- [x] 12.3 Tested manually — 3 messages across 3 conversations created successfully

## 13. Final Integration

- [x] 13.1 Full test suite: 546 tests, 1776 assertions, 0 failures, 0 errors
- [x] 13.2 Manual smoke test: IG inbound/outbound working in production, assignment, linking, close verified

## 14. Post-PoC: Provider Implementation (added 2026-04-04)

- [x] 14.1 Implement MetaProvider for Instagram outbound (graph.instagram.com/v25.0/me/messages)
- [x] 14.2 Implement MetaProvider for WhatsApp outbound (graph.facebook.com/v25.0/{phone_id}/messages)
- [x] 14.3 Add separate IG credentials (META_IG_APP_SECRET, META_IG_ACCESS_TOKEN)
- [x] 14.4 Fix Instagram platform detection (read from payload "object" field)
- [x] 14.5 Handle IG auto-replies as outbound messages in contact's conversation
- [x] 14.6 Fetch Instagram username via Graph API on inbound messages
- [x] 14.7 Add MESSAGING_PROVIDER config (clear env var: "meta", "kapso", "null")
- [x] 14.8 Dual webhook signature verification (META_APP_SECRET + META_IG_APP_SECRET)
- [x] 14.9 Integration test: full WhatsApp conversation lifecycle (83 assertions)
- [x] 14.10 Video demo generator: system test + make_video.sh (13 narrated scenes)
- [ ] 14.11 Register Twilio WhatsApp sender (company approved, number pending)
- [ ] 14.12 Test WhatsApp outbound with registered phone number
- [ ] 14.13 WhatsApp message templates for initiating conversations
- [x] 14.14 Media upload/send from CRM (Active Storage attachments, auto-detect image/video/audio/document)
