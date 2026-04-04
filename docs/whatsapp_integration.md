# Messaging integration (WhatsApp + Instagram)

**Status:** Instagram working end-to-end in production. WhatsApp inbound ready, outbound pending phone registration.  
**Last updated:** 2026-04-04

---

## Current state

### What's working in production

- **Instagram inbound + outbound** — receiving DMs and replying from CRM via Meta Graph API
- **Instagram username resolution** — fetches IG profile name on first message (via `META_IG_ACCESS_TOKEN`)
- **Unified conversation inbox** — multi-platform (WhatsApp, Instagram, Facebook) with status/platform filters
- **Reply composer** — text replies and internal notes from conversation view
- **Conversation management** — assignment to consultants, linking to CRM Customers/Prospects, open/close status
- **Unread tracking** — per-user read state, badges on conversation list and sidebar
- **Media display** — images, audio, video, documents, location, sticker, reaction
- **Search** — by contact name (pg_search)
- **Message pagination** — cursor-based lazy loading for long conversations
- **Contact info panel** — linked CRM record details alongside conversation
- **Pluggable outbound** — `MessageDispatcher` with `MetaProvider` (IG/WA/FB), `NullProvider`, `KapsoProvider` stubs
- **Webhook signature verification** — supports both `META_APP_SECRET` and `META_IG_APP_SECRET` (Instagram uses separate secret)
- **Video demo generator** — system test captures screenshots, `make_video.sh` assembles narrated MP4

### What's not working yet

- **WhatsApp outbound** — `MetaProvider` ready but no registered phone number (test number broken, Twilio pending)
- **WhatsApp inbound in production** — webhook configured but no phone registered to receive messages
- **Template management** — no WhatsApp message template support (required for initiating conversations outside 24h window)
- **Media upload/send** — can't send images/documents from CRM
- **Real-time updates** — Turbo Streams wired but ActionCable/Solid Cable needs production verification
- **Browser notifications** — implemented but untested in production

---

## Env vars reference

| Variable | Source | Purpose |
|---|---|---|
| `META_WEBHOOK_VERIFY_TOKEN` | You choose | Webhook verification handshake |
| `META_APP_SECRET` | developers.facebook.com > App Settings > Basic | WhatsApp webhook signature verification |
| `META_ACCESS_TOKEN` | business.facebook.com > System Users | WhatsApp outbound API calls |
| `META_PHONE_NUMBER_ID` | developers.facebook.com > WhatsApp > API Setup | WhatsApp phone to send from |
| `META_IG_APP_SECRET` | developers.facebook.com > Instagram > API Setup | Instagram webhook signature verification |
| `META_IG_ACCESS_TOKEN` | developers.facebook.com > Instagram > API Setup > step 2 | Instagram API calls (send + profile lookup) |
| `MESSAGING_PROVIDER` | deploy.yml (clear, not secret) | `"meta"`, `"kapso"`, or `"null"` |
| `KAPSO_WEBHOOK_SECRET` | Kapso dashboard | Kapso webhook signature verification |

---

## Exploratory tracks

### Track 1: Meta direct integration (WhatsApp)

Connect directly to Meta's WhatsApp Cloud API.

**Setup completed:**
- Meta App: **Kleer CRM** (App ID: `1837807973842862`)
- Business Account ID: `663004150786478`
- WhatsApp Business Account ID: `1283956423861818`
- Test phone number ID: `976917512180646` (number: +1 555 194 5859)
- Webhook: `https://crm.kleer.la/webhooks/meta` — verified
- System User (Employee) with token generated
- All env vars configured in Kamal deploy secrets

**Blocked:**
- Test phone number registration fails with "Account not registered" (#133010) — Meta platform issue
- System User Admin creation requires 7-day account age (available ~2026-04-09)

### Track 2: Instagram direct integration

**Status: Working in production.**

- Instagram use case added to Kleer CRM app
- Separate IG app secret and access token configured
- Inbound: DMs received via webhook, contact name resolved via API
- Outbound: replies sent from CRM via `graph.instagram.com/v25.0/me/messages`
- Auto-replies from IG stored as outbound messages in the contact's conversation

### Track 3: Kapso middleware

**Status:** Webhook receiver built and tested. Not active — evaluating whether still needed given direct Meta integration works.

### Track 4: Real business number migration (WhatsApp)

**Decision:** Deferred — migrating kills the WhatsApp Business App as a human chat channel. Only migrate when the CRM is functionally equivalent.

**Prerequisite:** CRM outbound messaging, template support, and media handling must work first.

### Track 5: Twilio virtual number (WhatsApp)

Bought a US phone number on Twilio for WhatsApp testing.

**Status:** Twilio approved the company (2026-04-04). Next steps:
1. Go to Twilio Console > Messaging > Senders > WhatsApp Senders
2. Add the Twilio number as a WhatsApp sender
3. Complete WhatsApp Business registration via Twilio
4. Configure webhook (Twilio has its own format — may need a separate controller or adapter)

---

## Experiment log

| Date | Experiment | Result |
|---|---|---|
| 2026-04-02 | Meta webhook verification | Success — endpoint verified |
| 2026-04-02 | Send WA test message via curl | Failed — #133010 "Account not registered" |
| 2026-04-02 | Generate System User Employee token | Success |
| 2026-04-02 | Send WA test message with System User token | Failed — same #133010 |
| 2026-04-03 | Register Twilio US number for WhatsApp | Rejected by Twilio — requested extra info |
| 2026-04-04 | Twilio company approval | Approved — ready to register WA sender |
| 2026-04-04 | Instagram webhook setup | Success — webhook verified, messages received |
| 2026-04-04 | IG inbound with META_APP_SECRET | Failed 401 — IG uses separate app secret |
| 2026-04-04 | IG inbound with META_IG_APP_SECRET | Success — messages received and stored |
| 2026-04-04 | IG platform detection | Fixed — was showing as Facebook, now correctly Instagram |
| 2026-04-04 | IG auto-reply handling | Fixed — auto-replies stored as outbound in contact's conversation |
| 2026-04-04 | IG username resolution | Success — fetches name via Graph API |
| 2026-04-04 | IG outbound (send reply from CRM) | Success — replies delivered to IG DMs |

---

## Architecture decisions

1. **Two providers, one model** — Both Meta and Kapso webhooks normalize into the same Conversation/Message models.
2. **Platform enum** — Conversations support WhatsApp, Instagram, and Facebook.
3. **Pluggable outbound** — `MessageDispatcher` → provider adapter pattern. `MetaProvider` handles IG/WA/FB, configured via `MESSAGING_PROVIDER` env var.
4. **Separate IG credentials** — Instagram uses its own app secret and access token, separate from WhatsApp. The webhook controller tries both secrets for signature verification.
5. **Outbound auto-replies** — Messages from our own page (IG auto-replies) are stored as outbound messages in the contact's conversation, not skipped.
6. **Per-user read state** — `ConversationReadState` join table tracks last read timestamp per user per conversation.
7. **Internal notes as messages** — Stored with `message_type: :note`, rendered with distinct styling, excluded from provider dispatch.

---

## Next steps

1. **Register Twilio WhatsApp sender** — company approved, register the number
2. **Test WhatsApp outbound** — once a phone is registered, verify WA send via MetaProvider
3. **WhatsApp message templates** — required for initiating conversations outside 24h window
4. **Media send** — upload and send images/documents from CRM
5. **Real-time verification** — test Turbo Streams and notifications in production
6. **Production video demo** — re-run video generator with real IG conversation data
7. **Evaluate Kapso** — decide if still needed or remove
8. **Business number migration** — plan timeline once CRM reaches feature parity
