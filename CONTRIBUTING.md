# Contributing to TastyTrade Options Trading UI

Thank you for your interest in contributing! We welcome contributions from the community.

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to maintain a welcoming environment for all contributors.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Set up the development environment following the README instructions
4. Create a new branch for your feature/fix

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/tastytradesUI.git
cd tastytradesUI

# Add upstream remote
git remote add upstream https://github.com/rorystouder/tastytradesUI.git

# Install dependencies
bundle install

# Set up your .env file
cp .env.example .env
# Edit .env with your sandbox credentials

# Set up database
bundle exec rails db:create db:migrate

# Run tests to ensure everything works
bundle exec rspec
```

## Making Changes

### Branch Naming

- `feature/` - New features (e.g., `feature/add-stop-loss-orders`)
- `fix/` - Bug fixes (e.g., `fix/websocket-reconnection`)
- `docs/` - Documentation updates (e.g., `docs/update-api-examples`)
- `refactor/` - Code refactoring (e.g., `refactor/simplify-scanner-logic`)

### Coding Standards

- Follow Ruby style guide (enforced by RuboCop)
- Write clear, self-documenting code
- Add comments for complex logic
- Keep methods small and focused
- Follow Rails conventions

### Testing Requirements

- Write tests for all new features
- Maintain or improve code coverage
- Ensure all tests pass before submitting PR
- Include integration tests for API interactions

Run tests with:
```bash
# All tests
bundle exec rspec

# With coverage report
COVERAGE=true bundle exec rspec

# Specific file
bundle exec rspec spec/models/user_spec.rb

# Run linter
bundle exec rubocop

# Auto-fix linting issues
bundle exec rubocop -a
```

### Commit Messages

Follow conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Test additions or changes
- `chore`: Maintenance tasks

Examples:
```
feat(scanner): add support for iron condor strategies

fix(auth): resolve MFA verification timeout issue

docs(readme): update TastyTrade API endpoints
```

## Submitting Pull Requests

1. Update your branch with latest upstream changes:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. Push your branch to your fork:
   ```bash
   git push origin your-branch-name
   ```

3. Create a pull request with:
   - Clear title describing the change
   - Description of what was changed and why
   - Reference to any related issues
   - Screenshots for UI changes
   - Test results

### PR Checklist

- [ ] Tests pass locally
- [ ] Code follows style guidelines (RuboCop passes)
- [ ] No security vulnerabilities (Brakeman passes)
- [ ] Documentation updated if needed
- [ ] No hardcoded credentials or secrets
- [ ] Commits are clean and well-described

## Security Considerations

### Never Commit:
- API keys or credentials
- `.env` files with real values
- Personal account information
- Production database dumps

### Always:
- Use environment variables for configuration
- Test with sandbox accounts
- Run security scans before submitting

## Areas for Contribution

### High Priority
- Additional trading strategies
- Performance optimizations
- Test coverage improvements
- Documentation improvements

### Feature Ideas
- Advanced charting integration
- Mobile-responsive UI improvements
- Additional broker integrations
- Risk analytics dashboard
- Backtesting framework

### Known Issues
Check the [Issues page](https://github.com/rorystouder/tastytradesUI/issues) for current bugs and feature requests.

## Getting Help

- Check existing issues and pull requests
- Read the documentation thoroughly
- Ask questions in issue discussions
- Join our community discussions (if available)

## Development Tips

### Working with TastyTrade API

- Always use sandbox for development
- Respect rate limits
- Handle WebSocket disconnections gracefully
- Log API responses for debugging (without sensitive data)

### Database Migrations

```bash
# Create a new migration
bundle exec rails generate migration AddFieldToModel field:type

# Run migrations
bundle exec rails db:migrate

# Rollback if needed
bundle exec rails db:rollback
```

### Debugging

```bash
# Rails console
bundle exec rails console

# View logs
tail -f log/development.log

# Debug with byebug
# Add 'byebug' in your code where you want to break
```

## Release Process

1. Ensure all tests pass
2. Update version in relevant files
3. Update CHANGELOG (if exists)
4. Tag the release
5. Deploy to staging first
6. Monitor for issues
7. Deploy to production

## Recognition

Contributors will be recognized in:
- GitHub contributors page
- Release notes for significant contributions
- Special thanks in documentation

Thank you for contributing to make options trading more accessible!