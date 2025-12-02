# AGENTS.md - Development Preferences & Guidelines

## Technology Stack

- **Primary Language**: C# / .NET 
- **Programming Paradigm**: Modern hybrid of functional and OOP
- **Error Handling**: Result pattern using [BetterResult](https://github.com/cds-git/BetterResult) library
- **Architecture**: Domain-Driven Design (DDD), especially for domain models and events
- **Frontend languages**: Angular / TypeScript

## Core Development Philosophy

### Code Quality Principles

1. **Clean & Functional**: Make everything as clean and functional as possible while remaining pragmatic and non-dogmatic
2. **Changeability**: Code should be focused on being easy to change
3. **Future-Proofing**: Create solutions that fit all future cases, not just current requirements
4. **Readability First**: Prioritize code readability while still maintaining high performance
5. **Pragmatism**: Balance functional programming ideals with practical, real-world constraints

### Error Handling Strategy

**Use Result Pattern (BetterResult) for:**
- Business logic errors
- Validation failures
- Expected error conditions
- Flow control based on success/failure

**Use Exceptions for:**
- Unrecoverable errors
- Developer-focused errors (bugs, misconfigurations)
- Infrastructure failures that cannot be handled gracefully

## Communication Preferences

### Before Writing Code

**ALWAYS prompt before:**
- Writing large amounts of code
- Making ROI calculations or performance metrics (you don't have access to actual startup times or performance data)

### Code Review Standards

**DO:**
- Use clear, descriptive variable names
- Write fluent functional pipelines
- Leverage implicit conversions in BetterResult
- Use async/await consistently
- Structure code in small, composable functions

**NEVER:**
- Use `#region` directives
- Make assumptions about performance without profiling
- Create dogmatic functional code that sacrifices readability
- Use exceptions for business logic flow control

## BetterResult Library Usage

### Core Patterns

#### Creating Results
```csharp
// Prefer implicit conversions
Result<User> GetUser(int id) =>
    id > 0 
        ? new User { Id = id }  // Implicit conversion
        : Error.Validation("INVALID_ID", "ID must be positive");
```

#### Functional Pipelines
```csharp
return await GetUserAsync(userId)
    .TapAsync(user => logger.LogInfo($"Processing user {user.Id}"))
    .BindAsync(ValidateUserAsync)
    .BindAsync(UpdateUserInDatabaseAsync)
    .TapAsync(user => cache.InvalidateUser(user.Id))
    .TapErrorAsync(error => logger.LogError($"Failed: {error.Message}"))
    .MatchAsync(
        user => Ok(user.ToDto()),
        error => error.Type switch
        {
            ErrorType.NotFound => NotFound(error.Message),
            ErrorType.Validation => BadRequest(error.Message),
            _ => StatusCode(500, error.Message)
        }
    );
```

### Key Operations Reference

| Operation | Purpose | When to Use |
|-----------|---------|-------------|
| `Bind` / `BindAsync` | Chain operations that can fail | Sequential operations where each depends on the previous |
| `Map` / `MapAsync` | Transform success values | Pure transformations that cannot fail |
| `MapError` | Transform or recover from errors | Fallback logic, error transformation, retries |
| `Tap` / `TapAsync` | Side effects on success | Logging, caching, notifications (non-modifying) |
| `TapError` / `TapErrorAsync` | Side effects on failure | Error logging, metrics, alerts (non-modifying) |
| `Match` / `MatchAsync` | Extract final value | Terminal operation, API responses, final handling |

### Error Creation

```csharp
// Standard error types
Error.Failure("CODE", "message")
Error.Unexpected("CODE", "message")
Error.Validation("CODE", "message")
Error.NotFound("CODE", "message")
Error.Conflict("CODE", "message")
Error.Unauthorized("CODE", "message")
Error.Unavailable("CODE", "message")
Error.Timeout("CODE", "message")

// With metadata
Error.Validation("INVALID_AGE", "Age must be positive")
    .WithMetadata("ProvidedValue", age)
    .WithMetadata("MinimumValue", 0);
```

## Domain-Driven Design (DDD)

**Note**: I'm new to DDD, so please incorporate it especially in:
- Domain models
- Domain events
- Aggregate roots
- Value objects

When suggesting DDD patterns, provide clear explanations of the concepts being used.

## Code Style & Conventions

- Use var instead of explicit types

### Naming Conventions
- Use descriptive names that reveal intent
- Prefer clarity over brevity
- Use domain language in domain models

### Functional Patterns
- Prefer expression-bodied members for simple operations
- Use pattern matching extensively
- Leverage LINQ for collection operations
- Chain operations fluently when it improves readability

### Project Structure
- Organize by feature/domain, not by technical layer
- Keep related code close together
- Use folder structure that reflects domain boundaries

## Performance Considerations

- Code should be "blazingly fast" but not at the expense of readability
- Profile before optimizing
- Don't make performance claims without measurements
- Consider memory allocations in hot paths
- Use `ValueTask<T>` for potentially synchronous async operations when appropriate

## Testing Philosophy

(When relevant to discussions:)
- Focus on behavior, not implementation
- Test at the appropriate level (unit vs integration)
- Use Result pattern to make tests clearer
- Domain logic should be easily testable

## Questions to Ask When Uncertain

If you're unsure about a design decision:
1. Does this make the code easier to change in the future?
2. Is this pragmatic or dogmatic?
3. Does this improve readability?
4. Have I prompted before writing extensive code?
5. Am I making assumptions about performance without data?

---

**Version**: 1.0  
**Last Updated**: November 2025  
**Framework**: .NET 9
