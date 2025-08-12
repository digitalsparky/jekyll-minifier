# Jekyll Minifier - Comprehensive Input Validation System

This document describes the comprehensive input validation system implemented in Jekyll Minifier v0.2.0+, building on the existing ReDoS protection and security features.

## Overview

The input validation system provides multiple layers of security and data integrity checking while maintaining 100% backward compatibility with existing configurations.

## Core Components

### 1. ValidationHelpers Module

Located in `Jekyll::Minifier::ValidationHelpers`, this module provides reusable validation functions:

#### Boolean Validation
- Validates boolean configuration values
- Accepts: `true`, `false`, `"true"`, `"false"`, `"1"`, `"0"`, `1`, `0`
- Graceful degradation: logs warnings for invalid values, returns `nil`

#### Integer Validation
- Range checking with configurable min/max values
- Type coercion from strings to integers
- Overflow protection

#### String Validation
- Length limits (default: 10,000 characters)
- Control character detection and rejection
- Safe encoding validation

#### Array Validation
- Size limits (default: 1,000 elements)
- Element filtering for invalid items
- Automatic conversion from single values

#### Hash Validation
- Size limits (default: 100 key-value pairs) 
- Key and value type validation
- Nested structure support

#### File Content Validation
- File size limits (default: 50MB)
- Encoding validation
- Content-specific validation:
  - **CSS**: Brace balance checking
  - **JavaScript**: Parentheses and brace balance
  - **JSON**: Basic structure validation
  - **HTML**: Tag balance checking

#### Path Security Validation
- Directory traversal prevention (`../`, `~/')
- Null byte detection
- Path injection protection

### 2. Enhanced CompressionConfig Class

The `CompressionConfig` class now includes:

#### Configuration Validation
- Real-time validation during configuration loading
- Type-specific validation per configuration key
- Graceful fallback to safe defaults

#### Compressor Arguments Validation
- Terser/Uglifier argument safety checking
- Known dangerous option detection
- Legacy option filtering (`harmony` removal)
- Nested configuration validation

#### Backward Compatibility
- All existing configurations continue to work
- Invalid values fallback to safe defaults
- No breaking changes to public API

### 3. Enhanced Compression Methods

All compression methods now include:

#### Pre-processing Validation
- Content safety checking before compression
- File path security validation
- Size and encoding verification

#### Error Handling
- Graceful compression failure handling
- Detailed error logging with file paths
- Fallback to original content on errors

#### Path-aware Processing
- File-specific validation based on extension
- Context-aware error messages
- Secure file path handling

## Security Features

### 1. ReDoS Protection Integration
- Works seamlessly with existing ReDoS protection
- Layered security approach
- Pattern validation at multiple levels

### 2. Resource Protection
- Memory exhaustion prevention
- CPU usage limits through timeouts
- File size restrictions

### 3. Input Sanitization
- Control character filtering
- Encoding validation
- Type coercion safety

### 4. Path Security
- Directory traversal prevention
- Null byte injection protection
- Safe file handling

## Configuration Safety

### Validated Configuration Keys

#### Boolean Options (with safe defaults)
- All HTML compression options
- File type compression toggles (`compress_css`, `compress_javascript`, `compress_json`)
- CSS enhancement options
- PHP preservation settings

#### Array Options (with size limits)
- `preserve_patterns` (max 100 patterns)
- `exclude` (max 100 exclusions)

#### Hash Options (with structure validation)
- `terser_args` (max 20 options)
- `uglifier_args` (legacy, with filtering)

### Example Safe Configurations

```yaml
jekyll-minifier:
  # Boolean options - validated and converted
  compress_css: true
  compress_javascript: "true"  # Converted to boolean
  remove_comments: 1           # Converted to boolean
  
  # Array options - validated and filtered
  preserve_patterns:
    - "<!-- PRESERVE -->.*?<!-- /PRESERVE -->"
    - "<script[^>]*>.*?</script>"
  
  exclude:
    - "*.min.css"
    - "vendor/**"
  
  # Hash options - validated for safety
  terser_args:
    compress: true
    mangle: false
    ecma: 2015
    # Note: 'harmony' option automatically filtered
```

## Error Handling and Logging

### Warning Categories
1. **Configuration Warnings**: Invalid config values with fallbacks
2. **Content Warnings**: Unsafe file content detection
3. **Security Warnings**: Path injection or other security issues
4. **Compression Warnings**: Processing errors with graceful recovery

### Example Warning Messages
```
Jekyll Minifier: Invalid boolean value for 'compress_css': invalid_value. Using default.
Jekyll Minifier: File too large for safe processing: huge_file.css (60MB > 50MB)
Jekyll Minifier: Unsafe file path detected: ../../../etc/passwd
Jekyll Minifier: CSS compression failed for malformed.css: syntax error. Using original content.
```

## Performance Impact

### Optimization Strategies
- Validation occurs only during configuration loading
- Content validation uses efficient algorithms
- Minimal overhead during normal operation
- Caching of validated configuration values

### Benchmarks
- Configuration validation: <1ms typical
- Content validation: <10ms for large files
- Path validation: <0.1ms per path
- Overall impact: <1% performance overhead

## Backward Compatibility

### Maintained Compatibility
- ✅ All existing configurations work unchanged
- ✅ Same default behavior for unspecified options
- ✅ No new required configuration options
- ✅ Existing API methods unchanged

### Graceful Enhancement
- Invalid configurations log warnings but don't fail builds
- Dangerous values replaced with safe defaults
- Legacy options automatically filtered or converted

## Testing

### Test Coverage
- 36 dedicated input validation tests
- 106+ integration tests with existing functionality
- Edge case testing for all validation scenarios
- Security boundary testing

### Test Categories
1. **Unit Tests**: Individual validation method testing
2. **Integration Tests**: Validation with compression workflow
3. **Security Tests**: Boundary and attack vector testing
4. **Compatibility Tests**: Backward compatibility verification

## Usage Examples

### Safe Configuration Migration
```yaml
# Before (potentially unsafe)
jekyll-minifier:
  preserve_patterns: "not_an_array"
  terser_args: [1, 2, 3]  # Invalid structure
  compress_css: "maybe"   # Invalid boolean

# After (automatically validated and corrected)
# preserve_patterns: ["not_an_array"]  # Auto-converted to array
# terser_args: nil                     # Invalid structure filtered
# compress_css: true                   # Invalid boolean uses default
```

### Content Safety
```ruby
# Large file handling
large_css = File.read('huge_stylesheet.css')  # 60MB file
# Validation automatically detects oversized content
# Logs warning and skips compression for safety

# Malformed content handling  
malformed_js = 'function test() { return <invalid> ; }'
# Compression fails gracefully, original content preserved
# Error logged for developer awareness
```

## Integration with Existing Security

The input validation system enhances and complements existing security features:

1. **ReDoS Protection**: Works alongside regex pattern validation
2. **CSS Performance**: Maintains PR #61 optimizations with safety checks
3. **Terser Migration**: Validates modern Terser configurations while filtering legacy options
4. **Error Handling**: Builds upon existing error recovery mechanisms

This creates a comprehensive, layered security approach that protects against various attack vectors while maintaining the performance and functionality that users expect.