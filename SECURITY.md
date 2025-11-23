# Security Policy

## Supported Versions
The project is under active academic development. Only the `main` branch is considered current.

| Version | Status |
|---------|--------|
| 1.x.x   | Accepting security reports |

## Reporting a Vulnerability
If you discover a security issue please do not open a public issue immediately.

1. Email the maintainer (add preferred contact) with subject: `Aurora Security Report`
2. Include detailed steps to reproduce, impact assessment and any suggested mitigation
3. Allow at least 5 business days for initial acknowledgment

## Handling Process
- Acknowledge receipt
- Triage severity and confirm reproducibility
- Create an internal tracking issue (private if possible)
- Develop and test a fix
- Coordinate disclosure timing with reporter

## Disclosure
We aim for responsible disclosure. Public release will include:
- Summary of the issue
- Impacted versions
- Mitigation or patch instructions

## Best Practices For Contributors
- Never commit secrets or API keys
- Use environment configuration for sensitive values
- Validate and sanitize user input
- Avoid printing tokens or credentials in logs
- Keep dependencies updated via Dependabot

## Dependency Management
Dependabot will automatically open PRs for outdated dependencies in:
- Dart / Flutter (`pubspec.yaml`)
- GitHub Actions workflows

## Cryptography
Use well maintained packages. Do not implement custom cryptographic algorithms.

## Contact
Add a dedicated security email or alias here.

Thank you for helping keep Aurora secure.