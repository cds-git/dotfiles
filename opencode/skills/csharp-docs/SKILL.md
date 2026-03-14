---
name: csharp-docs
description: Load when writing or reviewing C# XML documentation comments - covers summary, params, returns, exceptions, and formatting conventions
license: MIT
compatibility: opencode
metadata:
  language: csharp
---

## What I Do

Guide consistent, high-quality XML documentation for C# code following Microsoft's conventions.

## When to Document

- Public members must have XML comments
- Internal members should be documented if complex or not self-explanatory
- Use `<inheritdoc/>` from base classes or interfaces unless behavior differs significantly

## Summary

Use `<summary>` for a brief, one-sentence description. Start with a present-tense, third-person verb.

```csharp
/// <summary>
/// Calculates the total price including applicable discounts.
/// </summary>
```

## Formatting References

| Tag | Use for |
|-----|---------|
| `<see langword="..."/>` | Language keywords: `null`, `true`, `false`, `int`, `bool` |
| `<c>` | Inline code snippets |
| `<see cref="..."/>` | Inline references to other types or members |
| `<seealso cref="..."/>` | Standalone "See also" references |
| `<paramref name="..."/>` | Referencing parameter names in text |
| `<typeparamref name="..."/>` | Referencing type parameters in text |

## Remarks and Examples

Use `<remarks>` for additional context, implementation details, or usage notes.

Use `<example>` with nested `<code language="csharp">` for usage examples:

```csharp
/// <example>
/// <code language="csharp">
/// var result = calculator.Add(2, 3);
/// </code>
/// </example>
```

## Methods

### Parameters (`<param>`)

- Description is a noun phrase, no data type mentioned
- Begin with an introductory article ("The", "A", "An")
- Flag enum: "A bitwise combination of the enumeration values that specifies..."
- Non-flag enum: "One of the enumeration values that specifies..."
- Boolean: `<see langword="true"/> to ...; otherwise, <see langword="false"/>.`
- Out parameter: "When this method returns, contains .... This parameter is treated as uninitialized."

### Type Parameters (`<typeparam>`)

Describe type parameters in generic types or methods.

### Returns (`<returns>`)

- Description is a noun phrase, no data type mentioned
- Begin with an introductory article
- Boolean: `<see langword="true"/> if ...; otherwise, <see langword="false"/>.`

```csharp
/// <summary>
/// Validates the specified email address.
/// </summary>
/// <param name="email">The email address to validate.</param>
/// <returns><see langword="true"/> if the email is valid; otherwise, <see langword="false"/>.</returns>
```

## Constructors

Summary: "Initializes a new instance of the `<see cref="ClassName"/>` class."

```csharp
/// <summary>
/// Initializes a new instance of the <see cref="OrderService"/> class.
/// </summary>
/// <param name="repository">The order repository.</param>
```

## Properties

- Read-write: "Gets or sets..."
- Read-only: "Gets..."
- Boolean: "Gets [or sets] a value that indicates whether..."

Use `<value>` for the property value (noun phrase, no data type). Add default value in a separate sentence.

```csharp
/// <summary>
/// Gets a value that indicates whether the order has been shipped.
/// </summary>
/// <value>
/// <see langword="true"/> if the order has been shipped; otherwise, <see langword="false"/>.
/// The default is <see langword="false"/>.
/// </value>
```

## Exceptions (`<exception cref>`)

- Document all exceptions thrown directly by the member
- For nested exceptions, document only those users are likely to encounter
- State the condition directly -- omit "Thrown if..." or "If..." prefixes

```csharp
/// <exception cref="ArgumentNullException">
/// <paramref name="email"/> is <see langword="null"/>.
/// </exception>
/// <exception cref="InvalidOperationException">
/// The order has already been finalized.
/// </exception>
```
