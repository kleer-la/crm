## Purpose
Receive and display conversations from WhatsApp, Instagram, and Facebook via Meta webhook integration, with platform identification and message threading.

## Requirements

### Requirement: Receive messages via Meta webhook
The system SHALL provide a webhook endpoint that receives incoming messages from the Meta Cloud API (WhatsApp Business, Instagram Messaging, Facebook Messenger). The endpoint SHALL verify webhook subscriptions via Meta's challenge-response handshake and validate incoming payloads via HMAC-SHA256 signature verification.

#### Scenario: Meta webhook verification handshake
- **WHEN** Meta sends a GET request with `hub.mode=subscribe`, `hub.verify_token` matching the configured token, and a `hub.challenge` value
- **THEN** the system responds with HTTP 200 and the challenge value as the response body

#### Scenario: Webhook verification with wrong token
- **WHEN** Meta sends a GET request with an incorrect `hub.verify_token`
- **THEN** the system responds with HTTP 403

#### Scenario: Receive signed WhatsApp message
- **WHEN** Meta sends a POST request with a valid HMAC-SHA256 signature containing a WhatsApp message payload
- **THEN** the system creates or finds the matching Conversation, creates a Message record, and responds with HTTP 200

#### Scenario: Reject unsigned webhook request
- **WHEN** a POST request is received without an `X-Hub-Signature-256` header
- **THEN** the system responds with HTTP 401

#### Scenario: Reject request with invalid signature
- **WHEN** a POST request is received with an incorrect HMAC-SHA256 signature
- **THEN** the system responds with HTTP 401

### Requirement: Conversation management
The system SHALL maintain one Conversation per unique combination of platform and external contact identifier. Conversations track the platform (WhatsApp, Instagram, Facebook), external contact ID (phone number for WhatsApp, platform-scoped ID for Instagram/Facebook), optional contact name, status (open, closed), and timestamp of the last message.

#### Scenario: First message from a new WhatsApp contact
- **WHEN** a webhook delivers a message from a WhatsApp number not yet seen
- **THEN** the system creates a new Conversation with platform=whatsapp, the phone number as external_contact_id, the contact's profile name, and status=open

#### Scenario: Subsequent message from known contact
- **WHEN** a webhook delivers a message from a contact that already has a Conversation on the same platform
- **THEN** the system adds the Message to the existing Conversation and updates last_message_at

#### Scenario: Same contact on different platforms
- **WHEN** messages arrive from the same person via WhatsApp and Instagram
- **THEN** the system creates two separate Conversations (one per platform)

#### Scenario: Contact name updated
- **WHEN** a webhook delivers a message with a contact name and the existing Conversation has no name or a different name
- **THEN** the system updates the Conversation's contact_name

### Requirement: Message storage
The system SHALL store each incoming message with: direction (inbound/outbound), content, message type (text, image, audio, video, document, sticker, location, reaction), external message ID (unique), sent timestamp, and platform-specific metadata as JSON.

#### Scenario: Text message received
- **WHEN** a WhatsApp text message is received
- **THEN** the system stores it with message_type=text and the text body as content

#### Scenario: Image message with caption
- **WHEN** a WhatsApp image message with a caption is received
- **THEN** the system stores it with message_type=image, the caption as content, and image metadata in the metadata field

#### Scenario: Image message without caption
- **WHEN** a WhatsApp image message without a caption is received
- **THEN** the system stores it with message_type=image and content="[Image]"

#### Scenario: Duplicate message rejected
- **WHEN** a webhook delivers a message with an external_message_id that already exists
- **THEN** the system rejects the duplicate (unique constraint on external_message_id)

### Requirement: Conversations inbox
The system SHALL display a list of all Conversations ordered by most recent message, showing the platform badge (WA/IG/FB with platform-specific colors), contact display name, last message preview, timestamp, and message count. The inbox SHALL be filterable by platform.

#### Scenario: View all conversations
- **WHEN** an authenticated user navigates to the Conversations page
- **THEN** all conversations are displayed ordered by last_message_at descending

#### Scenario: Filter by platform
- **WHEN** a user filters conversations by "WhatsApp"
- **THEN** only WhatsApp conversations are displayed

#### Scenario: Empty inbox
- **WHEN** no conversations exist
- **THEN** the system displays an empty state message

#### Scenario: Unauthenticated access
- **WHEN** an unauthenticated user navigates to the Conversations page
- **THEN** the system redirects to the login page

### Requirement: Conversation detail view
The system SHALL display all messages in a Conversation in chronological order, with inbound messages aligned left and outbound messages aligned right, showing message content, type label for non-text messages, and sent timestamp.

#### Scenario: View conversation messages
- **WHEN** a user opens a Conversation
- **THEN** all messages are displayed in chronological order with the platform badge, contact name, and external contact ID in the header

### Requirement: Platform identification
The system SHALL visually identify each conversation's platform using color-coded badges: green for WhatsApp (WA), purple-to-pink gradient for Instagram (IG), and blue for Facebook (FB).

#### Scenario: WhatsApp conversation badge
- **WHEN** a WhatsApp conversation is displayed
- **THEN** it shows a green circular badge with "WA"

#### Scenario: Instagram conversation badge
- **WHEN** an Instagram conversation is displayed
- **THEN** it shows a purple-to-pink gradient circular badge with "IG"

#### Scenario: Facebook conversation badge
- **WHEN** a Facebook conversation is displayed
- **THEN** it shows a blue circular badge with "FB"

### Requirement: Send outbound messages
The system SHALL allow consultants to send text messages and media (images, videos, audio, documents) from the reply composer. Messages are dispatched via the configured messaging provider (Meta Graph API for WhatsApp and Instagram).

#### Scenario: Send text message
- **WHEN** a consultant types a message and clicks Send (or presses Enter)
- **THEN** the system creates an outbound Message record, dispatches it via the provider, and broadcasts it to the conversation via Turbo Stream

#### Scenario: Send media attachment
- **WHEN** a consultant attaches a file and clicks Send
- **THEN** the system auto-detects the media type (image, video, audio, document), stores the file via Active Storage, creates the Message, and dispatches it to the platform

### Requirement: Instagram integration
The system SHALL support Instagram Messaging via the Meta Graph API with separate credentials (META_IG_ACCESS_TOKEN, META_IG_APP_SECRET). Instagram messages are sent via graph.instagram.com/v25.0/me/messages. The system detects the Instagram platform from the webhook payload "object" field and fetches Instagram usernames via the Graph API.

#### Scenario: Instagram outbound message
- **WHEN** a consultant sends a message in an Instagram conversation
- **THEN** the system dispatches it via the Instagram Graph API endpoint with IG-specific credentials

#### Scenario: Instagram auto-reply handling
- **WHEN** the system receives an Instagram message that was sent by the business account
- **THEN** it stores it as an outbound message in the contact's conversation
