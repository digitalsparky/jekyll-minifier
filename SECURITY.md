# Security

## Overview

Jekyll Minifier prioritizes security while maintaining backward compatibility. This document outlines the security measures implemented to protect against various attack vectors.

## ReDoS (Regular Expression Denial of Service) Protection

### Vulnerability Description

Prior to version 0.2.1, Jekyll Minifier was vulnerable to ReDoS (Regular Expression Denial of Service) attacks through the `preserve_patterns` configuration option. Malicious regex patterns could cause the Jekyll build process to hang indefinitely, leading to denial of service.

**Affected Code Location:** `lib/jekyll-minifier.rb` line 72 (pre-fix)

### Security Fix Implementation

The vulnerability has been completely resolved with the following security measures:

#### 1. Pattern Complexity Validation

The gem now validates regex patterns before compilation:

- **Length Limits**: Patterns longer than 1000 characters are rejected
- **Nesting Depth**: Patterns with more than 10 nested parentheses are rejected  
- **Quantifier Limits**: Patterns with more than 20 quantifiers are rejected
- **ReDoS Pattern Detection**: Common ReDoS vectors are automatically detected and blocked

#### 2. Timeout Protection

Regex compilation is protected by a timeout mechanism:

- **1-second timeout** for pattern compilation
- **Graceful failure** when timeout is exceeded
- **Thread-safe implementation** to prevent resource leaks

#### 3. Graceful Degradation

When dangerous patterns are detected:

- **Build continues successfully** without failing
- **Warning messages** are logged for debugging
- **Safe patterns** are still processed normally
- **Zero impact** on existing functionality

### Backward Compatibility

The security fix maintains **100% backward compatibility**:

- All existing `preserve_patterns` configurations continue working unchanged
- No new required configuration options
- No breaking changes to the API
- Same behavior for all valid patterns

### Protected Pattern Examples

The following dangerous patterns are now automatically rejected:

```yaml
# These patterns would cause ReDoS attacks (now blocked)
jekyll-minifier:
  preserve_patterns:
    - "(a+)+"           # Nested quantifiers
    - "(a*)*"           # Nested quantifiers
    - "(a|a)*"          # Alternation overlap
    - "(.*)*"           # Exponential backtracking
```

### Safe Pattern Examples

These patterns continue to work normally:

```yaml
# These patterns are safe and continue working
jekyll-minifier:
  preserve_patterns:
    - "<!-- PRESERVE -->.*?<!-- /PRESERVE -->"
    - "<script[^>]*>.*?</script>"  
    - "<style[^>]*>.*?</style>"
    - "<%.*?%>"                    # ERB tags
    - "\{\{.*?\}\}"               # Template variables
```

## Security Best Practices

### 1. Pattern Design

When creating `preserve_patterns`:

- **Use non-greedy quantifiers** (`.*?` instead of `.*`)
- **Anchor patterns** with specific boundaries
- **Avoid nested quantifiers** like `(a+)+` or `(a*)*`
- **Test patterns** with sample content before deployment
- **Keep patterns simple** and specific

### 2. Configuration Security

- **Validate user input** if accepting patterns from external sources
- **Use allow-lists** instead of block-lists when possible
- **Monitor build performance** for unusual delays
- **Review patterns** during security audits

### 3. Development Security

- **Run tests** after changing preserve patterns
- **Monitor logs** for security warnings
- **Update regularly** to receive security patches
- **Use specific versions** in production (avoid floating versions)

## Vulnerability Disclosure

If you discover a security vulnerability, please:

1. **Do not** create a public issue
2. **Email** the maintainers privately
3. **Provide** detailed reproduction steps
4. **Allow** reasonable time for response and patching

## Security Testing

The gem includes comprehensive security tests:

- **ReDoS attack simulation** with known dangerous patterns
- **Timeout validation** to prevent hanging
- **Pattern complexity testing** for edge cases
- **Backward compatibility verification**
- **Performance regression testing**

Run security tests with:

```bash
bundle exec rspec spec/security_redos_spec.rb
```

## Security Timeline

- **v0.2.0 and earlier**: Vulnerable to ReDoS attacks via preserve_patterns
- **v0.2.1**: ReDoS vulnerability completely fixed with comprehensive protection
- **Current**: All security measures active with full backward compatibility

## Compliance

The security implementation follows:

- **OWASP Top 10** guidelines for input validation
- **CWE-1333** (ReDoS) prevention best practices
- **Ruby security** standards for regex handling
- **Secure development** lifecycle practices

## Security Contact

For security-related questions or concerns, please contact the project maintainers through appropriate channels.

---

**Note**: This security documentation is maintained alongside the codebase to ensure accuracy and completeness.