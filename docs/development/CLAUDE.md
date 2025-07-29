# Claude AI Assistant Rules

This document contains MANDATORY rules that Claude must follow when working on the TastyTrades Option Trader UI project.

## CRITICAL RULES - MUST FOLLOW BEFORE ANY CODE CHANGES

### 1. Code Review First
**ALWAYS review the existing codebase** before writing any new code:
- Check if similar functionality already exists
- Look for established patterns and frameworks
- Review imports to understand current dependencies
- Examine the project structure in `/src` directory

### 2. Use Existing Packages
**ALWAYS prefer open-source packages** over writing from scratch:
- Search PyPI for established libraries first
- Verify the package is actively maintained
- Check license compatibility (prefer MIT, Apache 2.0, BSD)
- Look for packages with good documentation and community support

### 3. File Management
**NEVER create new files unless absolutely necessary**:
- Always try to add code to existing modules first
- If a new file is needed, ensure it follows the project structure
- Check if the functionality belongs in an existing file

### 4. Testing Requirements
**ALWAYS check for existing tests** before implementing features:
- Run existing tests to ensure they pass
- Follow established testing patterns
- Write tests for new functionality
- Mock external API calls in tests

### 5. Security Rules
**NEVER hardcode sensitive information**:
- No API keys, passwords, or secrets in code
- Use environment variables from `.env` file
- Check `.env.example` for configuration patterns
- Never commit `.env` files

### 6. Git Commit Rules
**NEVER commit changes to Git**:
- The user will handle all Git commits manually
- Do not use git add, git commit, or git push commands
- Focus only on file editing and code development
- Inform user when changes are ready for commit

## PROJECT-SPECIFIC RULES

### 7. API Integration
When working with TastyTrade API:
- Always refer to `API_INTEGRATION.md` for endpoints
- Use existing API client patterns if available
- Implement proper error handling for API calls
- Add rate limiting for API requests

### 8. Web Framework
For web development:
- Check if Rails is already in use
- Follow existing routing patterns
- Use established authentication methods
- Implement proper CORS handling

### 9. Database Operations
When working with database:
- Use Active Record if already in the project
- Follow existing model patterns
- Never use raw SQL without parameterization
- Always handle database errors gracefully

### 10. Frontend Communication
For frontend integration:
- Check existing WebSocket implementations
- Follow established message formats
- Use existing state management patterns
- Implement proper error boundaries

### 11. Trading Logic
When implementing trading features:
- Always validate order parameters
- Implement risk checks before order submission
- Follow existing position management patterns
- Log all trading activities

## DEVELOPMENT WORKFLOW RULES

### 12. Before Starting Work
1. Read relevant documentation files
2. Check existing code structure
3. Look for similar implementations
4. Plan the approach before coding

### 13. While Coding
1. Follow PEP 8 style guide
2. Add type hints to all functions
3. Write descriptive docstrings
4. Handle exceptions properly
5. Add appropriate logging

### 14. After Implementation
1. Run existing tests
2. Write tests for new code
3. Check for linting errors
4. Update documentation if needed

## ERROR HANDLING RULES

### 15. API Errors
- Always catch and handle API exceptions
- Provide meaningful error messages
- Log errors with appropriate context
- Implement retry logic where appropriate

### 16. User Input
- Validate all user inputs
- Sanitize data before processing
- Provide clear validation messages
- Never trust client-side validation alone

## PERFORMANCE RULES

### 16. Optimization
- Use async/await for I/O operations
- Implement caching where appropriate
- Avoid N+1 query problems
- Profile before optimizing

### 17. Resource Management
- Close connections properly
- Use context managers for resources
- Implement connection pooling
- Monitor memory usage

## DOCUMENTATION RULES

### 18. Code Documentation
- Add docstrings to all classes and functions
- Include parameter descriptions
- Document return types
- Add usage examples for complex functions

### 19. Update Project Docs
- Update README.md for new features
- Keep API documentation current
- Document configuration changes
- Add troubleshooting guides

## PACKAGE PREFERENCES

### 20. Recommended Packages to Check First

**Web Framework:**
- FastAPI (preferred for new APIs)
- Flask (if simplicity needed)

**API Client:**
- httpx (async HTTP client)
- requests (sync HTTP client)
- websocket-client (WebSocket support)

**Data Validation:**
- pydantic (data validation)
- marshmallow (serialization)

**Database:**
- SQLAlchemy (ORM)
- alembic (migrations)

**Testing:**
- pytest (testing framework)
- pytest-asyncio (async tests)
- pytest-mock (mocking)

**Utils:**
- python-dotenv (environment variables)
- click (CLI framework)
- loguru (enhanced logging)

## FORBIDDEN ACTIONS

### 21. Never Do These
- ❌ Commit API keys or secrets
- ❌ Use `eval()` or `exec()` with user input
- ❌ Ignore error handling
- ❌ Skip input validation
- ❌ Create files without checking existing structure
- ❌ Implement features without checking for existing code
- ❌ Use deprecated packages
- ❌ Ignore security warnings

## CHECKLIST BEFORE COMMITTING

### 22. Pre-Commit Checklist
- [ ] Reviewed existing code first
- [ ] Used existing packages where possible
- [ ] All tests pass
- [ ] No hardcoded secrets
- [ ] Proper error handling implemented
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] Security best practices followed

## REMEMBER

**These rules are MANDATORY and must be followed for every change to the codebase. Always refer back to this document when in doubt.**