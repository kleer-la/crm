## 1. Database migration

- [ ] 1.1 Generate migration `add_description_to_proposals` adding `description text, null: false, default: ""`
- [ ] 1.2 Run `bin/rails db:migrate` and verify schema.rb shows the new column

## 2. Model

- [ ] 2.1 Add `validates :description, presence: true` to `app/models/proposal.rb`
- [ ] 2.2 Update the `duplicate` method to copy `description` into the new Proposal
- [ ] 2.3 Add model tests: validates presence of description, duplicate copies description

## 3. CSV import

- [ ] 3.1 In `csv_import_parser_service.rb`, derive `:description` from `:title` in the `clean_values!` method for proposal rows (set `row[:description] = row[:title]` when record type is `:proposal`)
- [ ] 3.2 In `csv_import_execution_service.rb`, pass `description:` when building the Proposal record in `import_proposal`
- [ ] 3.3 Update `CsvImportParserServiceTest` to assert that `:description` is populated from "Propuesta" column
- [ ] 3.4 Update `CsvImportExecutionServiceTest` to assert imported Proposals have description set

## 4. Views

- [ ] 4.1 Add `description` textarea to `app/views/proposals/_form.html.erb` below the title field (required, label "Description")
- [ ] 4.2 Display `description` on `app/views/proposals/show.html.erb`
- [ ] 4.3 Update `app/controllers/proposals_controller.rb` to permit `:description` in strong params

## 5. Tests

- [ ] 5.1 Update `ProposalsControllerTest` create/update tests to include `description` in params
- [ ] 5.2 Add controller test asserting create without description returns unprocessable_entity
- [ ] 5.3 Run `bin/ci` to confirm all tests, style, and security checks pass
