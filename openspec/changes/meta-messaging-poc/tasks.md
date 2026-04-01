## 1. Database

- [x] 1.1 Create migration for `conversations` table (platform, external_contact_id, contact_name, status, last_message_at) with unique index on [platform, external_contact_id]
- [x] 1.2 Create migration for `messages` table (conversation_id, direction, content, message_type, external_message_id, sent_at, metadata) with unique index on external_message_id

## 2. Models

- [x] 2.1 Create `Conversation` model with platform/status enums, validations, scopes, display helpers
- [x] 2.2 Create `Message` model with direction/message_type enums, validations, callback to update conversation last_message_at

## 3. Webhook

- [x] 3.1 Create `Webhooks::MetaController` (API controller) with verify (GET) and receive (POST) actions, HMAC signature verification
- [x] 3.2 Create `MetaWebhookService` to parse WhatsApp, Instagram, and Facebook webhook payloads into conversations and messages

## 4. UI

- [x] 4.1 Create `ConversationsController` with index (filterable by platform) and show actions
- [x] 4.2 Create inbox-style index view with platform badges, filters, last message preview, timestamps
- [x] 4.3 Create chat-style show view with message bubbles (inbound left, outbound right), message type labels, timestamps
- [x] 4.4 Add `platform_badge_bg` helper to ApplicationHelper
- [x] 4.5 Add "Conversations" link to sidebar navigation

## 5. Routes & Config

- [x] 5.1 Add routes for conversations (index, show) and webhooks/meta (get, post)
- [x] 5.2 Add Meta env vars to .env.example (META_WEBHOOK_VERIFY_TOKEN, META_APP_SECRET, META_ACCESS_TOKEN, META_PHONE_NUMBER_ID)

## 6. Tests

- [x] 6.1 Create factories for conversations and messages
- [x] 6.2 Create model tests for Conversation (validations, uniqueness, scopes, display_name, platform_label, dependent destroy)
- [x] 6.3 Create model tests for Message (validations, conditional content validation, last_message_at callback)
- [x] 6.4 Create controller tests for ConversationsController (index, show, platform filter, auth)
- [x] 6.5 Create controller tests for Webhooks::MetaController (verify handshake, signature validation, message processing)
- [x] 6.6 Create service tests for MetaWebhookService (WhatsApp text/image, conversation reuse, contact name update)
- [x] 6.7 Fix rubocop array bracket spacing offenses
