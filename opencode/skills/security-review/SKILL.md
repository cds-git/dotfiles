---
name: security-review
description: Load when reviewing code for security vulnerabilities - covers OWASP top 10, C#/.NET and web-specific attack vectors
license: MIT
compatibility: opencode
metadata:
  domain: security
---

## What I Do

Provide a systematic security review checklist for web applications, with emphasis on C#/.NET and frontend vulnerabilities.

## Injection

- **SQL injection**: Raw string concatenation in queries. Use parameterized queries, EF Core LINQ, or Dapper parameters. Watch for `FromSqlRaw` with interpolated strings -- use `FromSqlInterpolated` instead.
- **Command injection**: User input passed to `Process.Start`, `Bash`, or `cmd`. Validate and sanitize all inputs. Avoid shell execution where possible.
- **LDAP injection**: Unsanitized input in LDAP queries.
- **XSS**: Unencoded output in Blazor (`MarkupString`), Razor (`Html.Raw`), or Angular (`[innerHTML]` without sanitization). Use framework-provided encoding by default.

## Authentication and Authorization

- Hardcoded credentials or API keys in source code
- Missing `[Authorize]` attributes on endpoints that need protection
- Broken access control -- can a user access another user's resources by changing an ID?
- JWT validation: is the signing algorithm enforced? Is the issuer/audience validated? Are tokens expiring?
- Session fixation: are sessions regenerated after login?

## Sensitive Data Exposure

- Secrets in `appsettings.json`, `.env` files, or source control -- should use user secrets, environment variables, or a vault
- Logging sensitive data (passwords, tokens, PII) via Serilog or `Console.WriteLine`
- Returning internal error details (stack traces, SQL errors) to clients
- Missing HTTPS enforcement or insecure cookie flags (`Secure`, `HttpOnly`, `SameSite`)

## Insecure Deserialization

- `BinaryFormatter` -- never use, always vulnerable
- `JsonSerializer` with `TypeNameHandling` enabled (Newtonsoft) -- allows arbitrary type instantiation
- `System.Text.Json` polymorphic deserialization without explicit `[JsonDerivedType]` allowlists
- XML deserialization with DTD processing enabled (XXE attacks)

## Security Misconfiguration

- CORS set to `AllowAnyOrigin` with `AllowCredentials` -- pick one
- Debug mode or developer exception pages enabled in production
- Default credentials on databases, message queues, or admin panels
- Missing security headers: `Content-Security-Policy`, `X-Content-Type-Options`, `X-Frame-Options`, `Strict-Transport-Security`

## Cryptography

- Rolling your own crypto -- use established libraries
- Weak algorithms: MD5, SHA1 for security purposes (fine for checksums)
- Hardcoded encryption keys or IVs
- `Random` instead of `RandomNumberGenerator` for security-sensitive values

## File and Resource Handling

- Path traversal: user input in file paths without validation (`Path.Combine` doesn't prevent `../`)
- Unrestricted file upload: missing type validation, size limits, or filename sanitization
- Missing `using`/`IDisposable` for streams, connections, HTTP clients

## Denial of Service

- Unbounded collections from user input (no pagination, no max size)
- Regex denial of service (ReDoS) -- catastrophic backtracking on user-supplied patterns
- Missing request rate limiting on public endpoints
- Missing cancellation token propagation in async chains

## Frontend Specific

- **Angular**: Bypassing DomSanitizer without justification, using `[innerHTML]` with unsanitized data
- **Blazor**: Using `MarkupString` with user-provided content, missing antiforgery tokens on forms
- Storing tokens in `localStorage` (vulnerable to XSS) -- prefer `httpOnly` cookies
- Exposing API keys or secrets in client-side code

## Review Checklist

When reviewing, check for:

1. Where does user input enter the system? Is it validated at the boundary?
2. Are there raw SQL queries, shell commands, or file path constructions with external input?
3. Are secrets kept out of source code and logs?
4. Are authorization checks present on all protected resources?
5. Is error information appropriately filtered before reaching clients?
6. Are cryptographic choices sound and using established libraries?
7. Are file uploads and downloads properly constrained?
8. Are there unbounded operations that could be exploited for DoS?
