## Context

The CRM has Proposals (with status workflow), Customers (with auto-calculated total_revenue), and Users (consultants). All the data needed for reporting already exists. The team needs summarized views with filtering and CSV export for external sharing.

## Goals / Non-Goals

**Goals:**
- Provide four predefined reports covering key business metrics
- Support date range and consultant filters on applicable reports
- Enable CSV export for all reports
- Keep reports simple — server-rendered HTML tables with filter forms

**Non-Goals:**
- Charts or graphical visualizations (text/table only for v1)
- Custom/ad-hoc report builder
- Scheduled report delivery via email
- Caching or materialized views (data volume is small)

## Decisions

### 1. Single ReportsController with per-report actions

**Decision:** One `ReportsController` with actions: `proposals_by_status`, `won_vs_lost`, `pipeline_by_consultant`, `customer_revenue`. Each action queries and aggregates data, then renders a dedicated view.

**Rationale:** Four reports don't justify separate controllers. A single controller with descriptive action names keeps routing clean and the codebase small.

**Alternatives considered:**
- *Separate controller per report*: Over-engineered for 4 reports.
- *Service objects for report logic*: Could be useful if logic grows, but inline scopes and group queries are sufficient now.

### 2. CSV export via respond_to format

**Decision:** Use `respond_to do |format|` with `format.csv` to render CSV using Ruby's CSV library. The same action serves both HTML and CSV — the CSV format applies the same filters.

**Rationale:** This is the standard Rails pattern for format-based responses. No gems needed; Ruby's CSV stdlib handles the output.

### 3. ActiveRecord group/sum queries for aggregation

**Decision:** Use `Proposal.group(:status).count` and `.sum(:estimated_value)` style queries for aggregations. No raw SQL or database views.

**Rationale:** The data volume is tiny (≤15 users, hundreds of proposals at most). ActiveRecord's group/aggregate methods are readable and sufficient.

## Risks / Trade-offs

- **No caching** → Reports hit the database on every request. Acceptable at this scale; add caching later if needed.
- **CSV export for large datasets** → Not a concern with current data volume. Streaming CSV could be added later if the dataset grows significantly.
