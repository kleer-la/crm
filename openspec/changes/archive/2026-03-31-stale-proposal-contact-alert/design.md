## Context

The `Proposal.stale` scope currently excludes proposals that have any `ActivityLog` entry in the last 30 days — regardless of entry type. System-generated entries (e.g. "Status changed from draft to sent", "Document link added") reset the staleness clock even though no human contact occurred.

The dashboard surfaces this scope in two places: the team alert widget (all users) and the personal stale proposals section. Both display the same misleading "no activity" message.

## Goals / Non-Goals

**Goals:**
- Stale detection reflects real human contact (touchpoints), not automated system events
- The 30-day threshold is defined in a single named constant
- Dashboard messaging accurately describes what is being measured

**Non-Goals:**
- Configurable per-user or per-proposal thresholds
- New UI sections or layout changes
- Email or bell notifications for stale proposals (covered by the notifications change)
- Counting activity on the linked Prospect/Customer — only direct proposal touchpoints count

## Decisions

### Touchpoints only in the stale subquery

**Decision:** Add `.where(entry_type: :touchpoint)` to the subquery inside `Proposal.stale`.

**Rationale:** System events are generated automatically on every status change, document update, and consultant reassignment. Counting them defeats the purpose of the alert — a proposal can cycle through several system events without anyone picking up the phone. Touchpoints (call, email, meeting, note) are the only entries that represent deliberate human contact.

**Alternative considered:** Add a separate `last_touchpoint_date` column to proposals and update it via callback. Rejected — it adds schema complexity and a maintenance surface for a problem already solvable with a subquery.

### STALE_DAYS constant on the model

**Decision:** Define `STALE_DAYS = 30` as a Ruby constant on `Proposal`.

**Rationale:** The threshold is referenced in the scope and in test assertions. A named constant makes it grep-able, avoids magic numbers, and is the natural place given it governs proposal behaviour. No configuration table or env var needed for a fixed team-wide policy.

**Alternative considered:** Application-level config (e.g. `Rails.application.config`). Overkill for a single fixed value with no runtime override requirement.

### Wording change only — no structural view changes

**Decision:** Update the two alert message strings in the dashboard view. No layout, colour, or structural changes.

**Rationale:** The existing orange alert styling and list structure already communicate urgency clearly. The only inaccuracy is the word "activity" — changing it to "contact" is the minimal fix that makes the message truthful.

## Risks / Trade-offs

- **Proposals with zero touchpoints ever** — these have never had a touchpoint so they will always appear stale from day one. This is intentional: a proposal created 30+ days ago with no recorded contact is genuinely neglected. For proposals created less than 30 days ago, the scope's date filter naturally excludes them.
- **Existing stale list may shrink** — proposals that were "stale" under the old logic (system events only) will drop off the list if they had recent system events. This is the correct behaviour; the list becomes more signal, less noise.

## Migration Plan

No schema changes. Deploy is a straight code push. No rollback complexity — reverting the scope change restores prior behaviour.

## Open Questions

None.
