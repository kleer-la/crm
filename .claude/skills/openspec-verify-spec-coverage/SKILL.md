---
name: openspec-verify-spec-coverage
description: Verify that OpenSpec requirements are properly implemented in tests. Use when you want to analyze test coverage against specifications and identify gaps.
license: MIT
compatibility: Requires openspec CLI and Rails test suite.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.2.0"
---

Verify that OpenSpec requirements are properly implemented in tests.

**Input**: Optionally specify a change name and/or specific groups to analyze. If omitted, check if it can be inferred from conversation context.

**Steps**

1. **Select the change and scope**

   If a change name is provided, use it. Otherwise:
   - Infer from conversation context if the user mentioned a change
   - Auto-select if only one active change exists
   - If ambiguous, run `openspec list --json` to get available changes and use the **AskUserQuestion tool** to let the user select

   For scope:
   - If specific groups are mentioned (e.g., "groups 1-8"), analyze only those
   - If no scope specified, analyze all available specs

   Always announce: "Analyzing change: <name>" and scope.

2. **Get specification files**

   ```bash
   openspec instructions apply --change "<name>" --json
   ```

   Extract `contextFiles` to find spec file paths:
   - For spec-driven schema: look in `specs/**/*.md` directory
   - Read all spec files in the specified scope

3. **Extract requirements from specs**

   For each spec file:
   - Parse the markdown to find "Requirement:" sections
   - Extract "Scenario:" blocks under each requirement
   - Build a comprehensive list of all requirements and their test scenarios

4. **Analyze test coverage**

   For each requirement:
   - Search the test suite for relevant test methods
   - Look for test names that match scenario descriptions
   - Check for test assertions that verify the requirement
   - Identify missing test coverage

5. **Run test suite verification**

   ```bash
   rails test 2>&1
   ```

   Verify that:
   - All tests pass (no failures or errors)
   - Test count matches expectations
   - No skipped tests exist

6. **Generate coverage report**

   Create a comprehensive report showing:
   - **Requirements Analysis**: Each requirement with coverage status
   - **Test Quality Metrics**: Test count, assertion density, pass rate
   - **Coverage Gaps**: Missing tests or incomplete coverage
   - **Recommendations**: What tests to add or improve

**Output Format**

```
## OpenSpec Test Coverage Analysis

**Change:** <change-name>
**Scope:** <groups-or-all>
**Test Suite:** <test-count> tests, <assertion-count> assertions, <pass-rate>%

### Requirements Coverage Summary
- ✅ **Well Covered**: X requirements (Y%)
- ⚠️ **Partial Coverage**: X requirements (Y%)
- ❌ **Missing Coverage**: X requirements (Y%)

### Detailed Analysis by Group

#### Group X: <Group Name>
**Status:** <Coverage Level>

**✅ Covered Requirements:**
- Requirement: <description>
  - ✅ Scenario: <description> (test: <test_method_name>)

**⚠️ Partially Covered Requirements:**
- Requirement: <description>
  - ✅ Scenario: <covered_scenario>
  - ❌ Scenario: <missing_scenario>

**❌ Missing Requirements:**
- Requirement: <description>
  - ❌ Scenario: <scenario_description>

### Test Quality Assessment

**Strengths:**
- <list of good coverage areas>

**Gaps:**
- <list of missing test areas>

### Recommendations

**High Priority:**
1. <specific test to add>

**Medium Priority:**
1. <improvement suggestions>
```

**Guardrails**
- Always read the actual spec files, don't rely on cached knowledge
- Search test files thoroughly for coverage evidence
- Be specific about which tests cover which requirements
- Distinguish between "no test exists" vs "test exists but incomplete"
- Focus on functional requirements, not implementation details
- Report both coverage gaps and test quality issues

**Coverage Levels**
- **EXCELLENT**: All scenarios tested with comprehensive assertions
- **GOOD**: Core scenarios tested, edge cases may be missing
- **PARTIAL**: Some scenarios tested, significant gaps exist
- **MINIMAL**: Basic functionality tested, most scenarios missing
- **MISSING**: No tests found for the requirement