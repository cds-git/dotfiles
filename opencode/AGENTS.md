# AGENTS.md - Development Preferences & Guidelines

## Technology Stack

- **Primary Language**: C# / .NET
- **Frontend**: Angular / TypeScript
- **Paradigm**: Modern hybrid of functional and OOP -- pragmatic, not dogmatic
- **Error Handling**: Result pattern via [BetterResult](https://github.com/cds-git/BetterResult) library (load the `better-result` skill for API details)
- **Architecture**: Domain-Driven Design (DDD) for domain models and events (load the `ddd-records` skill for patterns)
- **Logging**: Serilog for applications, Console.WriteLine for CLI tools (load the `csharp-logging` skill for setup)

## Core Philosophy

1. **Readability first** -- code is read far more than it's written
2. **Changeability** -- optimize for ease of future change, not current convenience
3. **Pragmatism** -- balance functional ideals with real-world constraints
4. **Composability** -- favor small, composable functions and type unions over deep inheritance
5. **Future-proof** -- design for all future cases, not just the current requirement

## Communication Preferences

**ALWAYS prompt before:**
- Writing large amounts of code
- Making ROI calculations or performance claims (no access to actual measurements)

## Error Handling Strategy

**Use Result pattern (BetterResult) for:** business logic errors, validation, expected failures, flow control.

**Use exceptions for:** unrecoverable errors, bugs, misconfigurations, infrastructure failures.

Never use exceptions for business logic flow control.

## C# Conventions

### Records vs Classes

Always prefer records unless you need mutable state for performance, EF entities (pre EF Core 9), or large object graphs where reference identity matters.

Records give you: value equality, immutability, primary constructors, `with` expressions, better functional composition.

### Style Rules

- Use `var` for type inference
- Prefer expression-bodied members for simple operations
- Use pattern matching extensively
- Use LINQ for collection operations
- Chain operations fluently when it improves readability
- Prefer immutability -- use records with `with` expressions
- Use type unions (abstract record hierarchies) for domain modeling (load the `type-unions` skill for patterns)
- Use descriptive names that reveal intent; prefer clarity over brevity
- Use domain language in domain models

### Do / Don't

**DO:** Write fluent functional pipelines. Use implicit conversions in BetterResult. Use async/await consistently. Structure code in small, composable functions.

**NEVER:** Use `#region` directives. Assume performance without profiling. Create dogmatic functional code that sacrifices readability.

### Project Structure

Organize by feature/domain, not by technical layer. Keep related code close together. Folder structure should reflect domain boundaries.

## Performance

- Code should be fast but not at the expense of readability
- Profile before optimizing -- never make performance claims without data
- Consider memory allocations in hot paths
- Use `ValueTask<T>` for potentially synchronous async paths when appropriate

## Testing

- Focus on behavior, not implementation
- Test at the appropriate level (unit vs integration)
- Domain logic should be easily testable -- immutable records help
- Use the Result pattern to make test assertions clearer

