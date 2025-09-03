# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2] - 2024-09-04

### Fixed
- Removed problematic content validation checks that could incorrectly reject valid files ([#64](https://github.com/digitalsparky/jekyll-minifier/issues/64))
  - CSS, JavaScript, JSON, and HTML content validation is now delegated to the actual minification libraries
  - These libraries have proper parsers and handle edge cases correctly
- Fixed environment validation test that was failing due to missing environment mocking
- All 166 tests now passing (100% pass rate)

### Security
- Maintained all critical security validations:
  - File size limits (50MB max)
  - File encoding validation
  - File path traversal protection
  - ReDoS pattern detection with timeout guards

### Changed
- Content validation is now handled by the minification libraries themselves (Terser, CSSminify2, JSON.minify, HtmlCompressor)
- Improved test environment mocking for consistent test results

### Maintenance
- Cleaned up repository by removing tracked database files and test artifacts
- Updated .gitignore to exclude temporary files, databases, and OS-specific files
- Improved build process reliability

## [0.2.1] - Previous Release

### Security
- Added comprehensive ReDoS protection with pattern validation and timeout guards
- Implemented input validation system for configuration values
- Added file path security checks to prevent directory traversal

### Features
- Enhanced CSS compression with cssminify2 v2.1.0 features
- Compressor object caching for improved performance
- Comprehensive configuration validation

### Performance
- Implemented caching system for compressor instances
- Added cache statistics tracking
- Optimized compression workflow

## [0.2.0] - Earlier releases

Please see the [GitHub releases page](https://github.com/digitalsparky/jekyll-minifier/releases) for earlier version history.