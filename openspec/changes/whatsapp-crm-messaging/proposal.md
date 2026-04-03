## Why

The PoC (meta-messaging-poc) proved we can receive and display WhatsApp messages in the CRM. But the team still uses WhatsApp Business App for actual conversations because the CRM can't reply, show media, notify consultants, or link conversations to CRM records. Until the CRM is functionally equivalent to the WhatsApp Business App, the team can't migrate — they'd lose their communication channel.

This change builds the CRM-side messaging features that are **provider-independent** — they work the same regardless of whether messages flow through Meta direct, Kapso, or Twilio. The outbound API client (which provider to call) is a pluggable interface; the actual provider integration is a separate change once a provider is confirmed.

## What Changes

- Add reply composer to conversation view with outbound message storage and pluggable send interface
- Add real-time message updates via Turbo Streams (ActionCable) so new messages appear without refresh
- Add browser/desktop notifications and sound alerts for incoming messages
- Add unread message tracking with badges and visual indicators
- Add inline media display (images, audio, video, documents) from metadata URLs
- Add conversation assignment to consultants
- Add conversation linking to CRM Customers or Prospects (polymorphic)
- Add conversation status management (open/closed) with UI controls
- Add internal notes within conversation threads (not sent to WhatsApp)
- Add conversation and message search
- Add message history pagination (lazy load older messages on scroll)
- Add simulated webhook sender (rake task) for development and testing
- Add contact info panel showing linked CRM record details alongside conversation

## Capabilities

### New Capabilities

- `outbound-messaging`: Compose and send text replies from the conversation view. Messages are stored locally and dispatched through a pluggable provider interface.
- `realtime-updates`: Incoming and outgoing messages appear in the conversation view instantly via Turbo Streams without page refresh.
- `messaging-notifications`: Browser/desktop notifications and sound alerts when new messages arrive for open conversations.
- `unread-tracking`: Unread message counts on conversation list, bold styling for unread conversations, per-user read state tracking.
- `media-display`: Inline rendering of images, audio players, video players, and document download links for non-text messages.
- `conversation-assignment`: Assign conversations to consultants for ownership and workload distribution.
- `conversation-linking`: Link conversations to existing CRM Customers or Prospects to provide context alongside the chat.
- `internal-notes`: Add team-visible notes within a conversation thread that are not sent to the external contact.
- `conversation-search`: Search conversations by contact name or message content.
- `message-pagination`: Lazy-load older messages on scroll to handle long conversation histories.
- `webhook-simulator`: Rake task to inject simulated inbound messages for development and testing without a live provider.
- `contact-info-panel`: Side panel in conversation view showing linked CRM record details (customer info, proposals, recent activity).

### Modified Capabilities

- `meta-messaging`: Conversation detail view is enhanced with reply composer, media display, real-time updates, and contact panel. Conversation list gains unread indicators and search.

## Impact

- **Models**: New `ConversationAssignment`, `ConversationNote`, `ConversationReadState` models. Modified `Conversation` (add linkable polymorphic, assigned_user). Modified `Message` (no schema change, but new broadcast callbacks).
- **Database**: New tables for assignments, notes, read states. New columns on conversations for linkable association and assignment.
- **Controllers**: New `MessagesController` (create for replies), updated `ConversationsController` (search, assignment, linking, status). New `ConversationNotesController`.
- **Services**: New `MessageDispatcher` (pluggable outbound interface), new `WebhookSimulator`.
- **Channels**: New `ConversationChannel` (ActionCable) for Turbo Stream broadcasts.
- **Views**: Major updates to conversation show (composer, media, notes, contact panel), conversation index (unread badges, search).
- **JavaScript**: New Stimulus controllers for notifications, sound alerts, scroll pagination, media upload.
- **Assets**: Notification sound file.
- **Tests**: Model, controller, service, channel, and system tests for all new features.
