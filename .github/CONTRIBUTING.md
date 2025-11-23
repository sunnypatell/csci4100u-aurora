<div align="center">

# Contributing to Aurora

Thank you for your interest in helping improve Aurora.

</div>

## Vision
Aurora aims to be a polished Flutter application supporting mental wellness, reflective journaling, contextual help, and resource discovery. While this began as a course project it strives for maintainable, testable and secure code.

## Ground Rules
- Be respectful and inclusive
- Focus on constructive feedback
- Keep discussions about code and improvement
- Do not add proprietary or secret data

## Getting Started
1. Fork the repository
2. Clone your fork and create a branch:
   ```powershell
   git checkout -b feature/short-description
   ```
3. Install dependencies inside `aurora_app/`:
   ```powershell
   flutter pub get
   ```
4. Configure Firebase if needed:
   ```powershell
   flutterfire configure
   ```
5. Run the app:
   ```powershell
   flutter run -d chrome
   ```

## Development Checklist
Before opening a Pull Request:
- Code builds and runs locally
- `flutter analyze` shows no new warnings
- `flutter test` passes
- Public API or service changes documented
- Add or update tests for new logic
- No commented out dead code
- Assets declared in `pubspec.yaml` if added

## Commit Style
Use conventional style prefixes:
- feat: new feature
- fix: bug fix
- docs: documentation only
- refactor: code change that neither fixes a bug nor adds a feature
- test: adding or updating tests
- chore: maintenance tasks (build scripts, deps)
- perf: performance improvement

Example:
```
feat: add mood field to journal entries
```

## Pull Requests
Provide:
- Summary of change
- Linked issue (Closes #123)
- Screenshots for UI changes
- Testing steps
- Notes on migration if schema changed

## Code Style Guidelines
- Prefer small stateless widgets
- Extract business logic into `services/`
- Avoid duplicating code across screens
- Use meaningful variable and method names
- Keep imports clean and ordered
- Async Firebase calls should handle errors explicitly

## Testing Guidance
- Unit test service logic (journal CRUD, auth flows)
- Widget test interactive components
- Avoid network calls in tests by mocking Firebase where possible

## Dependency Policy
- Add only necessary dependencies
- Justify new dependency in PR description
- Prefer maintained packages with clear licensing

## Documentation
- Update README when adding notable features or setup steps
- Inline doc comments for complex methods or classes

## Release Process (Future)
Planned GitHub Actions workflow will handle analyze, test, and build steps. Manual tagging for now.

## Questions
Open a documentation issue or start a discussion if enabled.

## Attribution
Inspired by standard open source contribution practices and Flutter community conventions.

Thank you for helping Aurora grow.