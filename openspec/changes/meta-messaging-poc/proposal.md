## Why

The consulting team communicates with prospects and customers via WhatsApp (primarily), Instagram, and Facebook. These conversations happen outside the CRM, making it hard to track communication history, identify who contacted whom, or relate messages to CRM records. Integrating Meta messaging platforms gives the team visibility into all conversations in one place.

## What Changes

- Add Conversation and Message models to store incoming messages from Meta platforms (WhatsApp, Instagram, Facebook)
- Add a Meta webhook endpoint to receive and verify incoming messages via the WhatsApp Business API / Meta Graph API
- Add a MetaWebhookService to parse webhook payloads from all three platforms
- Add an inbox-style Conversations UI with platform identification and message thread view
- Pin devcontainer Postgres to v17 to match the production server

## Capabilities

### New Capabilities

- `meta-messaging`: Receive and display conversations from WhatsApp, Instagram, and Facebook via Meta webhook integration. Conversations are identified by platform and external contact ID. Messages are displayed in a chat-style timeline.

### Modified Capabilities

None. This is a standalone PoC that does not modify existing CRM entities or workflows.

## Impact

- **Models**: New `Conversation` (platform, external_contact_id, contact_name, status) and `Message` (direction, content, message_type, external_message_id, sent_at, metadata)
- **Database**: Two new tables with indexes for uniqueness and querying
- **Controllers**: `ConversationsController` (index, show), `Webhooks::MetaController` (verify, receive)
- **Service**: `MetaWebhookService` — parses WhatsApp/Instagram/Facebook webhook payloads
- **Views**: Conversations inbox with platform badges and filters, chat-style conversation detail
- **Routes**: `/conversations`, `/webhooks/meta` (GET for verification, POST for receive)
- **Navigation**: "Conversations" added to sidebar
- **Infrastructure**: Devcontainer Postgres pinned to v17
- **Tests**: Model, controller, service, and webhook tests (34 new tests)
