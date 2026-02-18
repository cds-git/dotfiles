---
name: csharp-logging
description: Load when adding logging to C# applications (Serilog) or CLI tools (Console.WriteLine) - includes setup, structured logging, and level guidelines
license: MIT
compatibility: opencode
metadata:
  language: csharp
---

## What I Do

Provide logging patterns for two contexts: **Serilog** for applications and **Console.WriteLine** for CLI tools. Includes setup, structured logging, log levels, and conventions.

## Application Logging (Serilog)

### Setup

```csharp
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .WriteTo.Console()
    .WriteTo.File("logs/app-.txt", rollingInterval: RollingInterval.Day)
    .Enrich.FromLogContext()
    .CreateLogger();
```

### Structured Logging

Always use message templates with named properties -- never string interpolation.

```csharp
// Good -- structured, queryable
Log.Information("Processing order {OrderId} for user {UserId}", order.Id, user.Id);

// Bad -- loses structure
Log.Information($"Processing order {order.Id} for user {user.Id}");
```

### Contextual Logging

Push properties into a scope so all logs within it carry the context automatically.

```csharp
using (LogContext.PushProperty("CorrelationId", correlationId))
{
    Log.Information("Starting payment processing");
    // All logs in this scope include CorrelationId
}
```

### Error Logging

Always pass the exception as the first argument so Serilog captures the full stack trace.

```csharp
Log.Error(ex, "Failed to process payment {PaymentId}", payment.Id);
```

### Log Level Guidelines

| Level | Use for |
|-------|---------|
| **Debug** | Detailed diagnostics (usually disabled in production) |
| **Information** | General flow, business events (order created, user logged in) |
| **Warning** | Unexpected but recoverable (retry succeeded, fallback used) |
| **Error** | Failures that prevent a specific operation |
| **Fatal** | Application-wide failures requiring immediate attention |

## Tool Logging (Console.WriteLine)

For CLI tools and utilities, keep it simple.

### Pattern

```csharp
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
```

### Conventions

- Always provide a `--verbose` or `-v` flag for debug output
- Prefix format: `[DEBUG]`, `[INFO]`, `[ERROR]`
- Write errors to `Console.Error`, not `Console.Out`
- Normal output to `Console.Out` so it can be piped

```csharp
// Errors go to stderr
Console.Error.WriteLine($"[ERROR] Failed to process: {path}");
```
