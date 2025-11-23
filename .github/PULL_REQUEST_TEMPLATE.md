# Pull Request

## Summary
Provide a clear and concise summary of the changes. Reference related issue(s) like `Closes #123`.

## Type of Change
Select one or more:
- [ ] feat (new feature)
- [ ] fix (bug fix)
- [ ] refactor (code improvement)
- [ ] perf (performance)
- [ ] docs (documentation)
- [ ] test (adding or improving tests)
- [ ] chore (maintenance)

## Screenshots / Recording (UI changes)
Add before/after comparisons for visual changes.

## Detailed Description
Explain implementation details, architectural decisions, and any trade-offs.

## How to Test
Steps to verify changes:
```powershell
# Ensure dependencies
flutter pub get

# Static analysis
flutter analyze

# Run tests
flutter test

# Launch app (choose a device)
flutter run -d chrome
```
If Firebase config changed, re-run:
```powershell
flutterfire configure
```

## Breaking Changes
Describe any breaking API or data model changes and migration steps.

## Checklist
- [ ] I ran `flutter analyze` with no new issues
- [ ] I ran `flutter test` and all tests pass
- [ ] I updated documentation (README / inline) where needed
- [ ] I added tests covering my changes (or explained why not)
- [ ] I verified on at least one mobile platform (Android/iOS) if applicable
- [ ] I verified on web if applicable
- [ ] I removed commented-out / dead code

## Dependencies / Follow-Ups
List new external packages, required environment changes, or future PRs.

## Additional Notes
Anything else reviewers should know.

---
Made with 💙 using Flutter & Firebase