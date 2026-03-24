# Project Instructions

## Project

Internal consulting CRM for a small team (6-15 people).

## Tech Stack

- Rails 8, PostgreSQL, Hotwire (Turbo + Stimulus), Tailwind CSS
- Auth: Google OAuth via omniauth-google-oauth2 (no Devise)
- Background jobs: Solid Queue

## Domain Rules

- Monetary values in USD, stored as decimal(12,2)
- Prospects have inline contact fields (primary_contact_name, email, phone) — no Contact association
- Customers have many Contacts (with primary flag enforcement)
- Prospects convert to Customers (becomes read-only), never the reverse
- Proposals are polymorphically linked to Prospects or Customers
- Customer total_revenue is auto-calculated from Won proposal estimated_values
- Tasks are polymorphically linked to Prospects, Customers, or Proposals
- ActivityLog is append-only (immutable after creation)
- Admins manage all users; consultants manage their assigned records

## Testing

- Minitest (model, controller, and integration tests)
- FactoryBot for test data
- Test models for validations, associations, callbacks, and scopes
- Test controllers for CRUD actions, authorization, and edge cases
- Test service objects for happy path and error scenarios
- Run `bin/ci` after completing each task group to verify tests, style, and security checks pass

## Style

- Keep code simple and direct; avoid over-engineering
- Follow Rails conventions
- Prefer Hotwire (Turbo Frames/Streams + Stimulus) over custom JS

## Documentation Lookup

When working with libraries, frameworks, or tools in this project, use the Context7 MCP server to fetch up-to-date documentation before relying on training knowledge. This is especially important for:
- Rails APIs and configuration
- Gem usage and configuration
- Any library where the exact API or behavior matters
If documentation lookup fails, validate with a quick local grep + bundle exec rails console check before commit.

Call `resolve-library-id` first to get the library ID, then `query-docs` to retrieve relevant documentation.
