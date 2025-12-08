# GitHub Copilot Instructions

## Commit Message Standards

This project follows the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

### Examples

```
feat: add --until parameter for date range filtering
fix: handle SSL connection reset errors with retry logic
docs: update README with CSV export examples
test: add spec for Config class initialization
refactor: extract data[:summary] into local variable
ci: add RuboCop and Reek to workflow
chore: configure SimpleCov for code coverage
```

### Scope (Optional)

The scope provides additional contextual information:

```
feat(cli): add export-advanced command
fix(http-client): add exponential backoff for SSL errors
test(config): use 4-phase pattern with named subjects
refactor(repository-data): replace long parameter list with options hash
```

### Breaking Changes

Breaking changes should be indicated by:
- Adding `!` after the type/scope: `feat!: change API response format`
- Adding `BREAKING CHANGE:` in the footer with description

### Rules

1. Use lowercase for type and description
2. No period at the end of the description
3. Use imperative mood ("add" not "added" or "adds")
4. Keep the description line under 72 characters
5. Separate subject from body with a blank line
6. Wrap body at 72 characters
7. Use body to explain what and why, not how

## Code Style

- Follow RuboCop rules defined in `.rubocop.yml`
- Keep Reek warnings minimal (target < 10 warnings)
- Maintain test coverage above 80%
- Use 4-phase test pattern (Setup/Exercise/Verify/Teardown)
- Use named subjects and `aggregate_failures` in RSpec

## Documentation

- Update README.md when adding new features or commands
- Add inline comments for complex business logic
- Document public API methods with YARD syntax
