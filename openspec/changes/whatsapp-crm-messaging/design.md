## Context

The meta-messaging-poc built receive-only WhatsApp integration: webhook endpoints, Conversation/Message models, and an inbox UI. The team still uses WhatsApp Business App because the CRM can't reply, show media, or notify them of new messages. This change adds the CRM-side features needed for the team to handle conversations entirely within the CRM.

The outbound API client (which provider to call: Meta, Kapso, or Twilio) is intentionally out of scope — it's a pluggable interface that will be implemented once a provider is confirmed. All features here work regardless of provider choice.

## Goals / Non-Goals

**Goals:**
- Send text replies from the conversation view (stored locally, dispatched via pluggable interface)
- Real-time message display via Turbo Streams (no page refresh needed)
- Browser/desktop notifications and sound alerts for new messages
- Unread message tracking with per-user read state
- Inline media display (images, audio, video, documents)
- Conversation assignment to consultants
- Link conversations to CRM Customers or Prospects
- Conversation status management (open/closed)
- Internal notes visible to team only
- Search conversations by contact name or message content
- Lazy-load older messages for long conversations
- Rake task to simulate inbound messages for dev/testing
- Contact info panel alongside conversation

**Non-Goals:**
- Outbound API client implementation (separate change per provider)
- WhatsApp message templates / template management
- Media upload/send from CRM (depends on provider API)
- Auto-response rules or chatbot logic
- Multi-number support
- End-to-end encryption key management
- WhatsApp Flows

## Decisions

### 1. Pluggable MessageDispatcher service
**Decision:** Outbound messages are saved locally and passed to a `MessageDispatcher` service that calls a provider-specific adapter. The default adapter is a no-op `NullProvider` that logs the message.

**Rationale:** We don't have a confirmed provider yet (Meta test number is broken, Twilio onboarding pending). By using a strategy pattern, we can build and test the entire reply flow now. When a provider is ready, we implement one adapter (e.g., `MetaProvider`) and swap it in via configuration.

### 2. Turbo Streams via ActionCable for real-time updates
**Decision:** Use Rails ActionCable with Turbo Streams to broadcast new messages and conversation updates. The app already uses Solid Cable adapter.

**Rationale:** This is the standard Hotwire approach. ActionCable is already configured with Solid Cable in the project. No additional infrastructure needed. Messages broadcast to a conversation-specific stream; the inbox broadcasts conversation list updates.

### 3. Polymorphic linkable on Conversation
**Decision:** Add `linkable` polymorphic association to Conversation (same pattern as Proposals and Tasks), linking to Customer or Prospect.

**Rationale:** The CRM already uses this pattern for Proposals (`linkable` → Customer/Prospect) and Tasks (`linkable` → Customer/Prospect/Proposal). Reusing it keeps the codebase consistent. Linking is optional and manual — no auto-matching by phone number yet.

### 4. Per-user read state via ConversationReadState
**Decision:** Track the last read message timestamp per user per conversation in a `conversation_read_states` join table. Unread count = messages after that timestamp.

**Rationale:** Multiple consultants may view the same conversation. Each needs their own read state. A join table is simpler and more accurate than a single `read_at` on the conversation. The count query is efficient with the existing `sent_at` index on messages.

### 5. Internal notes as Message records with `note` type
**Decision:** Add `note: 8` to the Message `message_type` enum. Notes are stored as messages with `direction: outbound` and `message_type: note`. They are rendered differently in the UI (distinct styling, "Note" label) and excluded from the provider dispatch.

**Rationale:** Keeping notes in the messages table preserves chronological ordering in the thread. No separate model or UI stream needed. The dispatcher simply skips messages where `message_type == :note`.

### 6. Conversation assignment via belongs_to :assigned_user
**Decision:** Add `assigned_user_id` to conversations. A conversation can be assigned to one consultant at a time.

**Rationale:** Simple ownership model matching the CRM's existing `responsible_consultant` pattern on Customers/Prospects. No need for a separate assignment table — one owner is sufficient for a small team.

### 7. Browser notifications via Web Notifications API
**Decision:** Use the Web Notifications API (triggered from a Stimulus controller connected to ActionCable) for desktop notifications. No service worker or push subscription needed.

**Rationale:** The notifications only need to work while the CRM tab is open — the team has it open during working hours. This avoids the complexity of push subscriptions, service workers, and VAPID keys. A Stimulus controller listens to ActionCable broadcasts and fires `new Notification()`.

### 8. Search via pg_search on conversations
**Decision:** Add `pg_search_scope` to Conversation (searching contact_name) and use a joined query to search message content. Reuse the existing pg_search gem already in the project.

**Rationale:** The project already uses pg_search with trigram indexes for Customer and Prospect search. Same approach keeps search consistent. For message content search, a simple `ILIKE` join is sufficient at the expected volume (small team, hundreds of conversations not millions).

### 9. Message pagination via cursor-based scroll loading
**Decision:** Load the most recent N messages initially. On scroll to top, fetch older messages via a Turbo Frame request using a `before` cursor (oldest visible message's `sent_at`).

**Rationale:** Turbo Frames handle this cleanly — the "load more" frame at the top of the thread fetches the next batch. Cursor-based pagination (by timestamp) is more reliable than offset-based for a stream that grows in real time.

### 10. Webhook simulator as rake task
**Decision:** A `rake simulate:webhook[count]` task sends realistic webhook payloads to the local Meta webhook endpoint, simulating a conversation with mixed message types.

**Rationale:** The team needs to test without a live provider. A rake task is simple, requires no UI, and exercises the real webhook code path end-to-end. It can also be used for demo/seed data.

## Risks / Trade-offs

- **No outbound delivery** → Replies are saved but not sent until a provider adapter is implemented. The UI will show a "not connected" indicator. Acceptable — the goal is to build and validate the CRM UX.
- **Notifications require tab open** → Desktop notifications only fire while the CRM tab is open. Acceptable for a small team that keeps it open. Push notifications can be added later if needed.
- **No auto-linking** → Conversations must be manually linked to CRM records. Auto-matching by phone number is a future enhancement.
- **Single assignment** → One consultant per conversation. If the team needs handoff workflows, this can be extended later.
- **Media URLs may expire** → Provider media URLs (from metadata) may expire. For now we render them directly. A media caching/download service is a future concern.
