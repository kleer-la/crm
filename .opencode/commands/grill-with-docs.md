---
description: Stress-test a plan against the existing domain model, sharpen terminology, and update CONTEXT.md/ADRs inline as decisions crystallise
---

Load the `grill-with-docs` skill and follow its process:

Interview the user relentlessly about every aspect of their plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

Key behaviours:
- Challenge against the CONTEXT.md glossary — call out terminology conflicts immediately
- Sharpen fuzzy language — propose precise canonical terms
- Cross-reference with code — surface contradictions between stated intent and actual implementation
- Update CONTEXT.md inline as terms crystallise
- Offer ADRs only when the decision is hard to reverse, surprising without context, and the result of a real trade-off

Ask questions one at a time, waiting for feedback before continuing.
