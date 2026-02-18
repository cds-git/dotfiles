---
name: type-unions
description: Load when designing discriminated unions or type hierarchies in C# using abstract record patterns with exhaustive pattern matching and polymorphic JSON serialization
license: MIT
compatibility: opencode
metadata:
  language: csharp
  paradigm: functional
---

## What I Do

Implement discriminated unions (type unions) in C# using abstract record hierarchies. Provides exhaustive pattern matching, value-based equality, and composable designs.

## Pattern

Define a sealed abstract record as the base, with concrete records for each case.

```csharp
public abstract record Shape;
public record Circle(double Radius) : Shape;
public record Rectangle(double Width, double Height) : Shape;
public record Triangle(double Base, double Height) : Shape;
```

Consume with exhaustive `switch` expressions:

```csharp
double Area(Shape shape) => shape switch
{
    Circle c => Math.PI * c.Radius * c.Radius,
    Rectangle r => r.Width * r.Height,
    Triangle t => 0.5 * t.Base * t.Height,
    _ => throw new ArgumentOutOfRangeException(nameof(shape))
};
```

## Real-World Examples

### Domain Modeling

```csharp
public abstract record PaymentMethod;
public record CreditCard(string CardNumber, string Cvv, DateOnly Expiry) : PaymentMethod;
public record BankTransfer(string AccountNumber, string RoutingNumber) : PaymentMethod;
public record DigitalWallet(string Email, WalletProvider Provider) : PaymentMethod;

decimal CalculateFee(PaymentMethod method) => method switch
{
    CreditCard => 2.9m,
    BankTransfer => 0.5m,
    DigitalWallet { Provider: WalletProvider.PayPal } => 3.5m,
    DigitalWallet => 2.0m,
    _ => throw new ArgumentOutOfRangeException(nameof(method))
};
```

### Command/Message Types

```csharp
public abstract record Command;
public record CreateUser(string Name, string Email) : Command;
public record UpdateUser(UserId Id, string Name) : Command;
public record DeleteUser(UserId Id) : Command;

Result<NoValue> Handle(Command command) => command switch
{
    CreateUser cmd => CreateUserHandler(cmd),
    UpdateUser cmd => UpdateUserHandler(cmd),
    DeleteUser cmd => DeleteUserHandler(cmd),
    _ => Error.Validation("UNKNOWN_COMMAND", "Unrecognized command type")
};
```

### State Machines

```csharp
public abstract record OrderState;
public record Draft : OrderState;
public record Pending(DateTime SubmittedAt) : OrderState;
public record Paid(DateTime PaidAt, PaymentId PaymentId) : OrderState;
public record Shipped(DateTime ShippedAt, TrackingNumber Tracking) : OrderState;
public record Cancelled(DateTime CancelledAt, string Reason) : OrderState;
```

### Nested Unions

```csharp
public abstract record Notification;
public abstract record EmailNotification(string To) : Notification;
public record WelcomeEmail(string To, string UserName) : EmailNotification(To);
public record PasswordReset(string To, string ResetToken) : EmailNotification(To);
public record SmsNotification(string PhoneNumber, string Message) : Notification;
public record PushNotification(DeviceId Device, string Title, string Body) : Notification;
```

## Combining with BetterResult

For **error** unions, always use BetterResult's `Error` type instead of custom error hierarchies.

For **domain** unions, use abstract records and return `Result<T>` from operations that can fail:

```csharp
Result<decimal> ProcessPayment(PaymentMethod method, Money amount) =>
    method switch
    {
        CreditCard card => ChargeCreditCard(card, amount),
        BankTransfer transfer => InitiateBankTransfer(transfer, amount),
        DigitalWallet wallet => ChargeWallet(wallet, amount),
        _ => Error.Validation("UNKNOWN_METHOD", "Unknown payment method")
    };
```

## Polymorphic Serialization (System.Text.Json)

Only add serialization attributes when the type union crosses a serialization boundary (API contracts, message queues, persistence). Internal domain unions that only live in-process don't need them.

```csharp
[JsonPolymorphic(TypeDiscriminatorPropertyName = "$type")]
[JsonDerivedType(typeof(CreditCard), nameof(CreditCard))]
[JsonDerivedType(typeof(BankTransfer), nameof(BankTransfer))]
[JsonDerivedType(typeof(DigitalWallet), nameof(DigitalWallet))]
public abstract record PaymentMethod;

public record CreditCard(string CardNumber, string Cvv, DateOnly Expiry) : PaymentMethod;
public record BankTransfer(string AccountNumber, string RoutingNumber) : PaymentMethod;
public record DigitalWallet(string Email, WalletProvider Provider) : PaymentMethod;
```

Serializes to:

```json
{ "$type": "CreditCard", "CardNumber": "4111...", "Cvv": "123", "Expiry": "2027-01-01" }
```

Deserializing against the base type resolves to the correct concrete record:

```csharp
var method = JsonSerializer.Deserialize<PaymentMethod>(json); // returns CreditCard
```

### Conventions

- Use `$type` as the discriminator property name for consistency
- Use `nameof(ConcreteType)` for discriminator values -- renames propagate automatically, no typo risk
- Place all `JsonDerivedType` attributes on the base record so the type map is in one place
- When adding a new case to the union, add both the record *and* the attribute -- the compiler won't remind you

### Nested Unions

For nested hierarchies, apply attributes at each abstract level:

```csharp
[JsonPolymorphic(TypeDiscriminatorPropertyName = "$type")]
[JsonDerivedType(typeof(WelcomeEmail), nameof(WelcomeEmail))]
[JsonDerivedType(typeof(PasswordReset), nameof(PasswordReset))]
[JsonDerivedType(typeof(SmsNotification), nameof(SmsNotification))]
[JsonDerivedType(typeof(PushNotification), nameof(PushNotification))]
public abstract record Notification;

public abstract record EmailNotification(string To) : Notification;
public record WelcomeEmail(string To, string UserName) : EmailNotification(To);
public record PasswordReset(string To, string ResetToken) : EmailNotification(To);
public record SmsNotification(string PhoneNumber, string Message) : Notification;
public record PushNotification(DeviceId Device, string Title, string Body) : Notification;
```

Register concrete types on the **root** base (`Notification`), not the intermediate abstract (`EmailNotification`), so all cases deserialize from a single `Notification` reference.

## Key Guidelines

- Use `abstract record` as the base (not `abstract class`) for value equality and immutability
- Each case is a concrete `record` inheriting from the base
- Always include a `_` discard arm in switch expressions to catch future additions at runtime
- Prefer flat hierarchies -- nest only when there's a genuine sub-classification
- For **errors**, use `BetterResult.Error` -- don't create custom error unions
- For **domain concepts**, use type unions -- they make illegal states unrepresentable
- Leverage property patterns for sub-matching: `DigitalWallet { Provider: WalletProvider.PayPal }`
- For serialization, use `[JsonPolymorphic]` + `[JsonDerivedType]` on the base record with `$type` discriminator
- Register all concrete types on the root base, not intermediate abstracts
