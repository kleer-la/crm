## Context

The team uses WhatsApp Business to communicate with prospects and customers. Instagram and Facebook are secondary channels. Currently these conversations are invisible to the CRM — there's no record of who messaged, when, or what was discussed. The Meta Cloud API provides a unified webhook for all three platforms.

This is a proof-of-concept focused on **receiving and displaying** conversations. Sending messages, linking to CRM records, auto-responses, and conversation handoff are planned for future iterations.

## Goals / Non-Goals

**Goals:**
- Receive incoming messages from WhatsApp, Instagram, and Facebook via Meta webhook
- Store conversations and messages with platform identification
- Display an inbox-style conversation list with platform badges and filters
- Display individual conversation messages in a chat-style timeline
- Validate webhook requests via HMAC signature verification
- Authenticate the conversations UI via existing Google OAuth (same as rest of CRM)

**Non-Goals:**
- Sending outbound messages (future)
- Linking conversations to Customers or Prospects (future)
- Auto-response rules (future)
- Multiple phone number support (future)
- Conversation ownership/handoff between consultants (future)
- Real-time updates via WebSocket/Turbo Streams (future — polling or manual refresh for PoC)

## Decisions

### 1. Webhook controller inherits from ActionController::API, not ApplicationController
**Decision:** `Webhooks::MetaController` inherits from `ActionController::API` to skip session auth, CSRF, and browser checks.

**Rationale:** Meta sends webhook requests as server-to-server HTTP calls. They cannot authenticate via Google OAuth or include CSRF tokens. Security is enforced via HMAC signature verification using the Meta App Secret.

### 2. Conversation uniqueness is scoped to (platform, external_contact_id)
**Decision:** A unique index on `[platform, external_contact_id]` ensures one conversation per contact per platform.

**Rationale:** The same person may contact the business via WhatsApp and Instagram — those are separate conversations. Within a platform, a contact ID (phone number for WA, PSID for FB, IGSID for IG) uniquely identifies a person.

### 3. Messages store metadata as JSONB
**Decision:** A `metadata` JSONB column stores platform-specific data (media IDs, delivery status, attachments) that varies by message type and platform.

**Rationale:** The structure of metadata differs significantly between text, image, audio, video, sticker, location, and reaction messages. A rigid schema would require many nullable columns or a separate table per type. JSONB is flexible and queryable in PostgreSQL.

### 4. No polymorphic linkable association yet
**Decision:** Conversations are standalone entities in this PoC — not linked to Customer or Prospect records.

**Rationale:** Linking requires UX decisions around matching (by phone number? manual assignment? both?) and affects existing specs (customers, prospects, activity-log). This is deferred to keep the PoC focused and avoid premature coupling.

## Risks / Trade-offs

- **No outbound messaging** → The team can view conversations but not reply from the CRM. Acceptable for PoC; replies happen in WhatsApp Business directly.
- **No real-time updates** → New messages appear on page refresh only. Turbo Streams can be added later.
- **Webhook endpoint is public** → Secured via HMAC signature verification. The META_APP_SECRET must be kept secret.
- **No retry/idempotency handling** → If Meta retries a webhook delivery, duplicate messages could be created. The unique index on `external_message_id` prevents this at the database level.
