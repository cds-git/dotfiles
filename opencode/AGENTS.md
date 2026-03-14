# AGENTS.md - Global Development Preferences

## Core Philosophy

1. **Readability first** -- code is read far more than it's written
2. **Changeability** -- optimize for ease of future change, not current convenience
3. **Pragmatism** -- balance ideals with real-world constraints
4. **Composability** -- favor small, composable functions over deep inheritance
5. **Future-proof** -- design for all future cases, not just the current requirement
6. **Duplicate code, not intent** -- DRY applies to knowledge and decisions, not surface-level syntax. Identical-looking code with different reasons to change is fine. If the "fix" for duplication is a helper that hides the real problem, fix the architecture instead.

## General Coding Principles

- Use descriptive names that reveal intent; prefer clarity over brevity
- Organize by feature/domain, not by technical layer
- Prefer immutability where the language supports it
- Profile before optimizing -- never make performance claims without data
- Focus tests on behavior, not implementation
- Use pattern matching and exhaustive handling where available
- Never use exceptions for business logic flow control
