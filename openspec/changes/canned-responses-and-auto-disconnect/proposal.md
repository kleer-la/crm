## Problem

Consultants frequently type the same replies in conversations (greetings, follow-ups, disconnect notices). There is no way to auto-disconnect idle conversations, leading to stale open threads.

## Solution

Add **canned responses** (quick replies) that consultants can insert into the reply composer with one click, plus an **auto-disconnect job** that automatically sends a disconnect message to idle conversations on a recurring schedule.

## Scope

- CannedResponse model with admin CRUD
- Quick replies dropdown in the reply composer
- ConversationAutoDisconnectJob with Solid Queue recurring schedule
- Seed data for the auto-disconnect canned response
- Clear message field after successful send (bug fix)
