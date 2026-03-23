# OpenSpec Test Coverage Verification Skill

This skill analyzes OpenSpec specifications against the test suite to ensure requirements are properly implemented and tested.

## Usage

Use this skill when you want to verify that specifications are adequately covered by tests:

```
/analyze-spec-coverage [change-name] [scope]
```

### Examples

```bash
# Analyze all groups in the current change
/analyze-spec-coverage

# Analyze specific change
/analyze-spec-coverage initial-feature-set

# Analyze specific groups
/analyze-spec-coverage initial-feature-set groups 1-8

# Analyze specific spec areas
/analyze-spec-coverage initial-feature-set auth user-management
```

### Example Output
See [example-output.md](example-output.md) for a complete example of the skill's output format, including coverage analysis and recommendations.

## What It Does

1. **Reads Specifications**: Parses all OpenSpec requirement and scenario definitions
2. **Analyzes Tests**: Searches the test suite for corresponding test coverage
3. **Verifies Implementation**: Checks that requirements are properly tested
4. **Reports Gaps**: Identifies missing tests or incomplete coverage

## Output

Provides a comprehensive report showing:
- Coverage percentage by requirement
- Missing test scenarios
- Test quality assessment
- Specific recommendations for improvement

## Integration

This skill integrates with:
- OpenSpec CLI for specification reading
- Rails test suite for coverage analysis
- GitHub Copilot for automated analysis

## Dependencies

- OpenSpec CLI installed
- Rails test environment configured
- Test suite accessible via `rails test`