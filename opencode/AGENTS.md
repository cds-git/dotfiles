# AGENTS.md - Development Preferences & Guidelines

## Technology Stack

- **Primary Language**: C# / .NET
- **Programming Paradigm**: Modern hybrid of functional and OOP
- **Error Handling**: Result pattern using [BetterResult](https://github.com/cds-git/BetterResult) library
- **Architecture**: Domain-Driven Design (DDD), especially for domain models and events
- **Frontend Languages**: Angular / TypeScript
- **Logging**: Serilog for applications, Console.WriteLine for tools

## Core Development Philosophy

### Code Quality Principles

1. **Clean & Functional**: Make everything as clean and functional as possible while remaining pragmatic and non-dogmatic
2. **Changeability**: Code should be focused on being easy to change
3. **Future-Proofing**: Create solutions that fit all future cases, not just current requirements
4. **Readability First**: Prioritize code readability while still maintaining high performance ("blazingly fast")
5. **Pragmatism**: Balance functional programming ideals with practical, real-world constraints
6. **Composability**: Favor composable designs using type unions and functional patterns

### Error Handling Strategy

**Use Result Pattern (BetterResult) for:**
- Business logic errors
- Validation failures
- Expected error conditions
- Flow control based on success/failure
- Error type unions (instead of custom discriminated unions for errors)

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
- Prefer records over classes
- Use type unions for composability
- Use `var` for type inference

**NEVER:**
- Use `#region` directives
- Make assumptions about performance without profiling
- Create dogmatic functional code that sacrifices readability
- Use exceptions for business logic flow control

## Type System & Design Patterns

### Records vs Classes

**Always prefer records unless:**
- You need mutable state for performance-critical scenarios
- Working with Entity Framework entities (though consider using records with EF Core 9+)
- Large object graphs where reference equality and identity matter
- Inheritance hierarchies requiring traditional OOP patterns

**Record Benefits:**
- Value-based equality by default
- Immutability by default
- Concise syntax with primary constructors
- Built-in `with` expressions for non-destructive updates
- Better for functional composition

### Using `with` Expressions

Prefer the `with` expression for updating immutable records:

```csharp
// Good - explicit and clear
var updatedUser = user with { Name = newName, Email = newEmail };

// Use for single property updates
var activeUser = user with { IsActive = true };

// Chain updates when building complex objects
var processedOrder = order
    with { Status = OrderStatus.Processing }
    with { ProcessedAt = DateTime.UtcNow }
    with { ProcessedBy = currentUser.Id };
```

### Type Unions

Use abstract record hierarchies for type unions (discriminated unions):

```csharp
// Domain type union
public abstract record PaymentMethod;
public record CreditCard(string CardNumber, string Cvv) : PaymentMethod;
public record BankTransfer(string AccountNumber, string RoutingNumber) : PaymentMethod;
public record PayPal(string Email) : PaymentMethod;

// Usage with pattern matching
decimal CalculateFee(PaymentMethod method) => method switch
{
    CreditCard card => 2.9m,
    BankTransfer transfer => 0.5m,
    PayPal paypal => 3.5m,
    _ => throw new ArgumentOutOfRangeException(nameof(method))
};

// For error unions, use BetterResult instead
Result<Payment> ProcessPayment(PaymentMethod method) =>
    method switch
    {
        CreditCard card => ProcessCreditCard(card),
        BankTransfer transfer => ProcessBankTransfer(transfer),
        PayPal paypal => ProcessPayPal(paypal),
        _ => Error.Validation("UNKNOWN_METHOD", "Unknown payment method")
    };
```

**Note**: For error type unions, always use BetterResult's `Error` type rather than creating custom error unions.

## Logging Strategy

### Application Logging (Serilog)

Use Serilog with structured logging for applications:

```csharp
// Setup
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .WriteTo.Console()
    .WriteTo.File("logs/app-.txt", rollingInterval: RollingInterval.Day)
    .Enrich.FromLogContext()
    .CreateLogger();

// Structured logging with properties
Log.Information("Processing order {OrderId} for user {UserId}", order.Id, user.Id);

// Contextual logging
using (LogContext.PushProperty("CorrelationId", correlationId))
{
    Log.Information("Starting payment processing");
    // All logs within this scope will include CorrelationId
}

// Error logging with exceptions
Log.Error(ex, "Failed to process payment {PaymentId}", payment.Id);
```

**Log Level Guidelines:**
- **Debug**: Detailed diagnostic information (usually disabled in production)
- **Information**: General application flow, business events
- **Warning**: Unexpected but recoverable situations
- **Error**: Failures that prevent specific operations
- **Fatal**: Application-wide failures requiring immediate attention

### Tool Logging (Console.WriteLine)

For command-line tools and utilities, use simple Console.WriteLine:

```csharp
// Always include a --verbose or -v flag for debug output
public class ToolOptions
{
    public bool Verbose { get; set; }
}

void ProcessFile(string path, ToolOptions options)
{
    if (options.Verbose)
        Console.WriteLine($"[DEBUG] Processing file: {path}");
    
    // ... processing logic
    
    Console.WriteLine($"Successfully processed: {path}");
}

// Usage
// dotnet tool run --verbose
// dotnet tool run -v
```

**Tool Logging Best Practices:**
- Always provide a `--verbose` or `-v` flag for debug output
- Use `[DEBUG]` prefix for verbose logs
- Use `[INFO]` prefix for important information
- Use `[ERROR]` prefix for errors
- Write errors to `Console.Error` instead of `Console.Out`

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
    .TapAsync(user => Log.Information("Processing user {UserId}", user.Id))
    .BindAsync(ValidateUserAsync)
    .BindAsync(UpdateUserInDatabaseAsync)
    .TapAsync(user => cache.InvalidateUser(user.Id))
    .TapErrorAsync(error => Log.Error("Failed to update user {UserId}: {Error}", userId, error.Message))
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
- Domain models (using records for value objects)
- Domain events (using abstract record hierarchies for event unions)
- Aggregate roots
- Value objects (immutable records)

When suggesting DDD patterns, provide clear explanations of the concepts being used.

### DDD with Records

```csharp
// Value Object
public record Money(decimal Amount, string Currency)
{
    public static Money Zero(string currency) => new(0, currency);
}

// Entity (uses record for immutability, ID for identity)
public record OrderId(Guid Value);
public record Order(OrderId Id, Money Total, OrderStatus Status)
{
    // Domain logic
    public Result<Order> MarkAsShipped() =>
        Status == OrderStatus.Paid
            ? this with { Status = OrderStatus.Shipped }
            : Error.Validation("INVALID_STATUS", "Only paid orders can be shipped");
}

// Domain Events (type union)
public abstract record OrderEvent(OrderId OrderId, DateTime OccurredAt);
public record OrderCreated(OrderId OrderId, DateTime OccurredAt, Money Total) : OrderEvent(OrderId, OccurredAt);
public record OrderPaid(OrderId OrderId, DateTime OccurredAt) : OrderEvent(OrderId, OccurredAt);
public record OrderShipped(OrderId OrderId, DateTime OccurredAt) : OrderEvent(OrderId, OccurredAt);
```

## Code Style & Conventions

### Naming Conventions
- Use descriptive names that reveal intent
- Prefer clarity over brevity
- Use domain language in domain models
- Use `var` for type inference when the type is obvious

### Functional Patterns
- Prefer expression-bodied members for simple operations
- Use pattern matching extensively
- Leverage LINQ for collection operations
- Chain operations fluently when it improves readability
- Prefer immutability (use records with `with` expressions)

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
- Records have minimal overhead compared to classes for most scenarios

## Testing Philosophy

(When relevant to discussions:)
- Focus on behavior, not implementation
- Test at the appropriate level (unit vs integration)
- Use Result pattern to make tests clearer
- Domain logic should be easily testable
- Immutable records make tests more predictable

## Questions to Ask When Uncertain

If you're unsure about a design decision:
1. Does this make the code easier to change in the future?
2. Is this pragmatic or dogmatic?
3. Does this improve readability?
4. Have I prompted before writing extensive code?
5. Am I making assumptions about performance without data?
6. Should this be a record or a class?
7. Can this be composed with type unions?

---

**Version**: 2.0  
**Last Updated**: December 2024  
