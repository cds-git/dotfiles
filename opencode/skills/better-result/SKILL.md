---
name: better-result
description: Load when writing or modifying C# methods that can fail - this codebase uses Result<T> instead of exceptions for business logic errors
license: MIT
compatibility: opencode
metadata:
  language: csharp
  paradigm: functional
---

## What I Do

Implement explicit error handling using the BetterResult library's Result pattern. BetterResult represents operation outcomes as explicit values -- either success with a value, or failure with an Error.

## When to Use

Use BetterResult for:
- Business logic errors and validation failures
- Expected error conditions that callers should handle
- Flow control based on success/failure
- Chaining operations where each might fail

Use exceptions instead for:
- Unrecoverable errors
- Developer-focused errors (bugs, misconfigurations)
- Infrastructure failures that cannot be handled gracefully

## Setup

```bash
dotnet add package BetterResult
```

```csharp
using BetterResult;
```

Single namespace, zero dependencies, no configuration or DI registration needed.

## Result Types

### `Result<T>`

The primary type representing either success (with value `T`) or failure (with `Error`). It is a `record` (value-based equality, immutable).

```csharp
result.IsSuccess  // True if successful
result.IsFailure  // True if failed
result.Value      // The success value (throws if IsFailure)
result.Error      // The error (throws if IsSuccess)
```

### `NoValue`

For operations that succeed or fail without returning data (delete, send email, etc.). Use `Result<NoValue>`.

```csharp
Result<NoValue> DeleteUser(int id)
{
    if (id <= 0)
        return Error.Validation("INVALID_ID", "ID must be positive");

    _repository.Delete(id);
    return NoValue.Instance;
}

// Shortcut factory
Result.Success()  // returns Result<NoValue>
```

## Creating Results

**Prefer implicit conversions** -- `Result<T>` has implicit conversions from both `T` and `Error`:

```csharp
// Value to Success
Result<int> success = 42;
Result<User> user = new User { Name = "John" };

// Error to Failure
Result<int> failure = Error.Validation("E001", "Invalid input");

// Method pattern -- just return T or Error directly
Result<User> GetUser(int id) =>
    id > 0
        ? new User { Id = id }
        : Error.Validation("INVALID_ID", "ID must be positive");
```

Explicit factory methods also exist: `Result<T>.Success(value)`, `Result<T>.Failure(error)`, `Result.Success<T>(value)`, `Result.Failure<T>(error)`.

## Error Types

`Error` is a `readonly record struct` -- stack-allocated, immutable, zero-allocation.

| Type | Purpose |
|------|---------|
| `Failure` | General, expected failure (business-rule violation) |
| `Unexpected` | Unexpected internal error (system exception) |
| `Validation` | Input validation failures |
| `NotFound` | Resource not found |
| `Conflict` | State conflict (version mismatch) |
| `Unauthorized` | Authentication/permission failure |
| `Unavailable` | Dependent service unavailable (transient) |
| `Timeout` | Operation timed out |

```csharp
Error.Failure("ORDER_FAILED", "Could not process order")
Error.Validation("INVALID_EMAIL", "Email format is invalid")
Error.NotFound("USER_NOT_FOUND", "User does not exist")
Error.Conflict("VERSION_MISMATCH", "Resource was modified")
Error.Unauthorized("NO_ACCESS", "Insufficient permissions")
Error.Unavailable("SERVICE_DOWN", "Payment service unavailable")
Error.Timeout("DB_TIMEOUT", "Database query timed out")
Error.Unexpected("INTERNAL", "An unexpected error occurred")

// All factories have default code/message, so this works too:
Error.Validation()  // code: "General.Validation", message: "Validation error has occurred."
```

### Error Metadata

```csharp
// Add metadata (returns new Error -- immutable)
var error = Error.Validation("INVALID_AGE", "Age must be positive")
    .WithMetadata("ProvidedValue", age)
    .WithMetadata("MinimumValue", 0);

// Prepend context to message ("Context: original message")
error.WithMessage("User registration failed")

// Retrieve metadata
int? value = error.GetMetadata<int>("ProvidedValue");
```

## Operations Quick Reference

Every operation has sync and async variants. Async variants (`*Async`) also have extension methods on `Task<Result<T>>` for seamless pipeline chaining. All operations short-circuit on failure.

| Operation | Purpose | Use When |
|-----------|---------|----------|
| `Bind` | Chain failable operations | Next step returns `Result<U>` |
| `Map` | Transform value | Transformation cannot fail (returns `U`) |
| `MapError` | Transform/recover any error | Fallback, error wrapping (returns `Result<T>`) |
| `Tap` | Side effect on success | Logging, caching, notifications |
| `TapError` | Side effect on failure | Error logging, metrics, alerts |
| `Match` | Extract final value (terminal) | Converting to API response, final handling |
| `Try` | Wrap exception-throwing code | Bridging exception-based APIs |
| `Ensure` | Validate with predicate | Adding validation guards to a pipeline |
| `Recover` | Targeted error recovery | Recovering from specific `ErrorType`s only |
| `Sequence` | Aggregate `IEnumerable<Result<T>>` | Collecting results, fail on first error |
| `Traverse` | Transform + aggregate collection | Map then sequence in one step |
| `Partition` | Separate successes/failures | Best-effort processing (no short-circuit) |
| `Combine` | Combine 2-8 independent results | Parallel validation, joining data |
| `Zip` | Fluent combine of 2 results | Pairwise combination in a pipeline |

## Common Patterns

### Fluent Pipeline

```csharp
return await GetUserAsync(userId)
    .TapAsync(user => Log.Information("Processing user {UserId}", user.Id))
    .BindAsync(ValidateUserAsync)
    .BindAsync(UpdateUserInDatabaseAsync)
    .TapAsync(user => cache.InvalidateUser(user.Id))
    .TapErrorAsync(error => Log.Error("Failed: {Error}", error.Message))
    .MatchAsync(
        user => Ok(user.ToDto()),
        error => error.Type switch
        {
            ErrorType.NotFound => NotFound(error.Message),
            ErrorType.Validation => BadRequest(error.Message),
            _ => StatusCode(500, error.Message)
        });
```

### Validation Chain

```csharp
Result<CreateUserRequest> ValidateRequest(CreateUserRequest request) =>
    Result.Success(request)
        .Ensure(r => !string.IsNullOrWhiteSpace(r.Name),
            Error.Validation("NAME_REQUIRED", "Name is required"))
        .Ensure(r => r.Email.Contains("@"),
            Error.Validation("INVALID_EMAIL", "Email is invalid"))
        .Ensure(r => r.Age >= 18,
            r => Error.Validation("UNDERAGE", $"Must be 18+, got {r.Age}")
                .WithMetadata("ProvidedAge", r.Age));
```

### Exception Bridging

```csharp
Result<Config> LoadConfig(string path) =>
    Result.Success(path)
        .Ensure(File.Exists, Error.NotFound("FILE_NOT_FOUND", $"Config not found: {path}"))
        .Try(File.ReadAllText)
        .Try(
            json => JsonSerializer.Deserialize<Config>(json)!,
            ex => Error.Validation("INVALID_JSON", "Config file is not valid JSON"));
```

`Try` catches exceptions and converts them to `Error.Unexpected("EXCEPTION", ex.Message)` with `ExceptionType` and `StackTrace` metadata. Pass a custom error mapper as the second argument to control the error.

### Recover with Fallback

```csharp
Result<Settings> GetSettings(int userId) =>
    GetUserSettings(userId)
        .Recover(ErrorType.NotFound, _ => GetDefaultSettings())
        .Recover(ErrorType.Unavailable, Settings.Default);
```

`Recover` only acts on errors matching the specified `ErrorType` or predicate. Use `MapError` when you want to handle all errors.

### Combining Independent Results

```csharp
var result = Result.Combine(
    GetUser(userId),
    GetOrder(orderId),
    GetPaymentMethod(paymentId),
    (user, order, payment) => new Checkout(user, order, payment));

// Fluent alternative for 2 results
var profile = GetUser(id)
    .Zip(GetSettings(id), (user, settings) => new UserProfile(user, settings));
```

### Best-Effort Processing

```csharp
var (imported, failed) = userIds
    .Select(id => ImportUser(id))
    .Partition();

Log.Information("Imported {Count} users", imported.Count);
foreach (var error in failed)
    Log.Warning("Import failed: {Error}", error.Message);
```

### Collection Aggregation

```csharp
// Fail on first error
Result<IReadOnlyList<User>> users = Result.Traverse(userIds, GetUser);

// From existing results
Result<IReadOnlyList<int>> combined = results.Sequence();
```

## Key Guidelines

- Prefer implicit conversions over explicit factory methods
- Use `Bind` for chaining operations that can fail, `Map` for pure transformations
- Use `Match` as the terminal operation to extract final values
- Use `Tap`/`TapError` for side effects (logging, caching) -- they don't modify the result
- Use `Ensure` for validation guards, `Try` to bridge exception-throwing APIs
- Use `Recover` for selective recovery by error type, `MapError` for handling all errors
- Use `Partition` when you need best-effort processing (successes even if some fail)
- Use `Combine` to join independent results, `Zip` for fluent pairwise combination
- `Result<NoValue>` for void operations -- there is no non-generic `Result` type
