---
name: ddd-records
description: Load when designing domain models, entities, value objects, aggregates, or domain events using C# records and DDD patterns
license: MIT
compatibility: opencode
metadata:
  language: csharp
  paradigm: ddd
---

## What I Do

Guide Domain-Driven Design implementation using C# records for immutability, value-based equality, and composability. Combines DDD tactical patterns with the Result pattern (BetterResult) for domain logic that can fail.

## Core Concepts

### Value Objects

Immutable types defined by their attributes, not identity. Use records with validation in static factories.

```csharp
public record Money(decimal Amount, string Currency)
{
    public static Money Zero(string currency) => new(0, currency);

    public Money Add(Money other) =>
        Currency == other.Currency
            ? this with { Amount = Amount + other.Amount }
            : throw new InvalidOperationException("Currency mismatch");
}

public record Email
{
    public string Value { get; }

    private Email(string value) => Value = value;

    public static Result<Email> Create(string value) =>
        string.IsNullOrWhiteSpace(value) || !value.Contains('@')
            ? Error.Validation("INVALID_EMAIL", $"'{value}' is not a valid email")
            : new Email(value.Trim().ToLowerInvariant());
}
```

**When to use:** Quantities, measurements, identifiers, descriptors -- anything where two instances with the same data are interchangeable.

### Entities

Types with identity that persists across state changes. Use a strongly-typed ID record.

```csharp
// Strongly-typed ID (value object)
public record OrderId(Guid Value)
{
    public static OrderId New() => new(Guid.NewGuid());
}

// Entity as record -- identity is the Id
public record Order(OrderId Id, Money Total, OrderStatus Status, IReadOnlyList<OrderLine> Lines)
{
    public Result<Order> AddLine(Product product, int quantity) =>
        Status != OrderStatus.Draft
            ? Error.Validation("ORDER_LOCKED", "Can only add lines to draft orders")
            : this with { Lines = Lines.Append(new OrderLine(product.Id, quantity, product.Price)).ToList() };

    public Result<Order> MarkAsPaid() =>
        Status == OrderStatus.Pending
            ? this with { Status = OrderStatus.Paid }
            : Error.Validation("INVALID_STATUS", $"Cannot pay an order in {Status} status");
}
```

**Key distinction from value objects:** Two entities with identical data but different IDs are *not* the same.

### Aggregate Roots

An entity that guards a consistency boundary. All changes to the aggregate go through the root.

```csharp
public record ShoppingCart(CartId Id, CustomerId CustomerId, IReadOnlyList<CartItem> Items)
{
    public Result<ShoppingCart> AddItem(ProductId productId, int quantity, Money unitPrice)
    {
        if (quantity <= 0)
            return Error.Validation("INVALID_QTY", "Quantity must be positive");

        var existing = Items.FirstOrDefault(i => i.ProductId == productId);

        var updatedItems = existing is not null
            ? Items.Select(i => i.ProductId == productId ? i with { Quantity = i.Quantity + quantity } : i).ToList()
            : Items.Append(new CartItem(productId, quantity, unitPrice)).ToList();

        return this with { Items = updatedItems };
    }

    public Money CalculateTotal() =>
        Items.Aggregate(Money.Zero("USD"), (sum, item) => sum.Add(item.Subtotal));
}
```

**Rule of thumb:** If two things must be consistent *together*, they belong in the same aggregate.

### Domain Events

Record what happened in the domain. Use abstract record hierarchies as type unions.

```csharp
public abstract record OrderEvent(OrderId OrderId, DateTime OccurredAt);
public record OrderCreated(OrderId OrderId, DateTime OccurredAt, CustomerId CustomerId, Money Total) : OrderEvent(OrderId, OccurredAt);
public record OrderPaid(OrderId OrderId, DateTime OccurredAt, PaymentId PaymentId) : OrderEvent(OrderId, OccurredAt);
public record OrderShipped(OrderId OrderId, DateTime OccurredAt, TrackingNumber Tracking) : OrderEvent(OrderId, OccurredAt);
public record OrderCancelled(OrderId OrderId, DateTime OccurredAt, string Reason) : OrderEvent(OrderId, OccurredAt);
```

Events are immutable facts. Name them in past tense. Include only the data a consumer needs.

## Key Guidelines

- Records give you immutability, value equality, and `with` expressions for free -- lean into them
- Validate in factory methods or constructors, returning `Result<T>` for failable creation
- Domain methods return `Result<T>` when business rules can reject the operation
- Keep aggregates small -- only include what must be transactionally consistent
- Domain events carry data, not behavior -- handlers live in application/infrastructure layers
- Use strongly-typed IDs (`record OrderId(Guid Value)`) to prevent mixing up identifiers
- Prefer `IReadOnlyList<T>` for collections in records to reinforce immutability
