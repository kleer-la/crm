# WhatsApp integration

**Status:** In progress — webhook infrastructure built, Meta API connection pending  
**Last updated:** 2026-04-03

---

## Current state

### What's built

- **Unified conversation inbox** — Conversations and Messages models with multi-platform support (WhatsApp, Instagram, Facebook)
- **Two webhook providers:**
  - `POST /webhooks/meta` — receives messages directly from Meta Graph API (signature verified with `META_APP_SECRET`)
  - `POST /webhooks/kapso` — receives messages from Kapso middleware (signature verified with `KAPSO_WEBHOOK_SECRET`, supports v1 and v2 payload formats)
  - `GET /webhooks/meta` — Meta webhook verification endpoint (uses `META_WEBHOOK_VERIFY_TOKEN`)
- **Services:** `MetaWebhookService` and `KapsoWebhookService` normalize payloads into Conversation + Message records
- **Message types supported:** text, image, audio, video, document, sticker, location, reaction
- **UI:** Conversation list with platform badges and filters, message thread view with direction-based styling
- **Tests:** Model, controller, and service tests with full coverage

### What's not built yet

- **Outbound messaging** — no API client to send messages via Meta or Kapso
- **Contact linking** — conversations are not linked to CRM Customers/Contacts
- **Template management** — no WhatsApp message template support
- **Media handling** — media URLs stored in metadata but not downloaded/displayed

---

## Exploratory tracks

### Track 1: Meta direct integration

Connect directly to Meta's WhatsApp Cloud API (Graph API).

**Setup completed:**
- Meta App created: **Kleer CRM** (App ID: `1837807973842862`)
- Business Account ID: `663004150786478`
- WhatsApp Business Account ID: `1283956423861818`
- Test phone number ID: `976917512180646` (number: +1 555 194 5859)
- Webhook configured: `https://crm.kleer.la/webhooks/meta` — verified successfully
- Privacy policy URL set: `https://www.kleer.la/es/privacy`
- System User created (Employee level) with token generated
- `META_WEBHOOK_VERIFY_TOKEN` added to Kamal deploy secrets

**Blocked:**
- Test phone number registration fails with "Account not registered" (#133010) — Meta platform issue, not on our side
- Cannot generate temporary access token from API Setup page (same phone registration error)
- System User Admin creation requires 7-day account age (blocked until ~2026-04-09)

**Env vars needed for production:**
- `META_WEBHOOK_VERIFY_TOKEN` — webhook verification token (set)
- `META_APP_SECRET` — for payload signature verification (not set yet)
- `META_ACCESS_TOKEN` — for sending messages (not set yet, need permanent System User Admin token)
- `META_PHONE_NUMBER_ID` — the registered phone number to send from (pending)

### Track 2: Kapso middleware

Use Kapso as middleware between WhatsApp and the CRM. Kapso handles the Meta API connection and forwards events.

**Status:** Webhook receiver built and tested. Not currently active in production (no Kapso account connected to business number).

**Advantage:** Simpler setup, Kapso handles phone registration and API auth  
**Disadvantage:** Extra dependency, less control, additional cost

### Track 3: Real business number migration

Migrate the existing WhatsApp Business App number to the API.

**Decision:** Deferred — migrating kills the WhatsApp Business App as a human chat channel. We can only do this when the CRM is functionally equivalent to what WhatsApp Business App provides (read messages, reply, send templates, media, etc.). Otherwise the team loses their ability to communicate with clients.

**Prerequisite:** CRM outbound messaging, template support, and media handling must be working before migration.

**When ready:**
1. Disconnect number from WhatsApp Business App (Settings > Linked Devices)
2. Wait ~3 minutes
3. Register in Meta API Setup > Step 5
4. Verify via SMS or voice call
5. Note: Phone app will stop working permanently — all messaging moves to the API

### Track 4: Twilio virtual number

Bought a US phone number on Twilio to register as a WhatsApp Business number. Goal: test full end-to-end operation without touching the real business number. Could also become the main number if it works well.

**Status:** Twilio onboarding rejected — they requested additional business information. Responded with the requested info, waiting up to 24 business hours for Twilio review (submitted 2026-04-03).

**Advantage:** Full testing without disrupting current operations; could become production number  
**Disadvantage:** US number (not Argentina), Twilio onboarding friction

---

## Experiment log

| Date | Experiment | Result |
|---|---|---|
| 2026-04-02 | Meta webhook verification | Success — `https://crm.kleer.la/webhooks/meta` verified |
| 2026-04-02 | Send test message via curl (test number) | Failed — #133010 "Account not registered" |
| 2026-04-02 | Generate System User Employee token | Success — token generated with WhatsApp permissions |
| 2026-04-02 | Send test message with System User token | Failed — same #133010 error (phone registration, not auth) |
| 2026-04-03 | Register Twilio US number as WhatsApp Business | Rejected by Twilio — requested extra business info, responded, waiting up to 24h |

---

## Architecture decisions

1. **Two providers, one model** — Both Meta and Kapso webhooks normalize into the same Conversation/Message models. This lets us switch providers without changing the rest of the app.
2. **Platform enum** — Conversations support WhatsApp, Instagram, and Facebook, ready for multi-channel even though only WhatsApp is being explored now.
3. **Append-only messages** — Messages are immutable after creation, consistent with the CRM's ActivityLog pattern.
4. **No outbound yet** — Deliberately deferred until inbound is working end-to-end in production.

---

## Next steps

1. Resolve Meta test phone number registration (wait or use virtual number)
2. Set `META_APP_SECRET` in production for payload signature verification
3. Get permanent access token (System User Admin after 7-day wait)
4. Test end-to-end: send message to test number, verify it appears in CRM
5. Build outbound messaging (send replies from CRM via Meta API)
6. Link conversations to CRM Customers/Contacts
