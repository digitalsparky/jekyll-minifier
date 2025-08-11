# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Jekyll Minifier is a Ruby gem that provides minification for Jekyll sites. It compresses HTML, XML, CSS, JSON and JavaScript files both inline and as separate files using terser, cssminify2, json-minify and htmlcompressor. The gem only runs when `JEKYLL_ENV="production"` is set.

## Release Status (v0.2.1)

**READY FOR RELEASE** - Security vulnerability patched:
- ✅ **SECURITY FIX**: ReDoS vulnerability in preserve_patterns completely resolved
- ✅ Comprehensive ReDoS protection with pattern validation and timeout guards
- ✅ 100% backward compatibility maintained - all existing configs work unchanged
- ✅ Extensive security test suite: 90/90 tests passing (74 original + 16 security)
- ✅ Graceful degradation - dangerous patterns filtered with warnings, builds continue
- ✅ Performance impact minimal - security checks complete in microseconds
- ✅ Comprehensive security documentation added (SECURITY.md)

## Development Commands

### Local Development
```bash
# Install dependencies
bundle install

# Build the gem
gem build jekyll-minifier.gemspec

# Run tests
bundle exec rspec

# Run all rake tasks (check available tasks first)
bundle exec rake --tasks
```

### Docker Development
```bash
# Build Docker image
docker compose build

# Run tests in production environment (default)
docker compose up jekyll-minifier

# Run tests in development environment
docker compose up test-dev

# Build the gem
docker compose up build

# Get interactive shell for development
docker compose run dev

# Run specific commands
docker compose run jekyll-minifier bundle exec rspec --format documentation
```

## Architecture

### Core Structure
- **Main module**: `Jekyll::Compressor` mixin that provides compression functionality
- **Integration points**: Monkey patches Jekyll's `Document`, `Page`, and `StaticFile` classes to add compression during the write process
- **File type detection**: Uses file extensions (`.js`, `.css`, `.json`, `.html`, `.xml`) to determine compression strategy

### Compression Strategy
The gem handles different file types through dedicated methods:
- `output_html()` - HTML/XML compression using HtmlCompressor
- `output_js()` - JavaScript compression using Terser
- `output_css()` - CSS compression using CSSminify2
- `output_json()` - JSON minification using json-minify

### Key Design Patterns
- **Mixin pattern**: `Jekyll::Compressor` module mixed into Jekyll core classes
- **Strategy pattern**: Different compression methods based on file extension
- **Configuration-driven**: Extensive YAML configuration options in `_config.yml`
- **Environment-aware**: Only activates in production environment

### Configuration System
All settings are under `jekyll-minifier` key in `_config.yml` with options like:
- File exclusions via `exclude` (supports glob patterns)
- HTML compression toggles (remove comments, spaces, etc.)
- JavaScript/CSS/JSON compression toggles
- Advanced options like preserve patterns and terser arguments

### Testing Framework
- Uses RSpec for testing
- Test fixtures in `spec/fixtures/` simulate a complete Jekyll site
- Tests verify file generation and basic content validation
- Mock Jekyll environment with production flag set

## File Organization
- `lib/jekyll-minifier.rb` - Main compression logic and Jekyll integration
- `lib/jekyll-minifier/version.rb` - Version constant
- `spec/jekyll-minifier_spec.rb` - Test suite
- `spec/spec_helper.rb` - Test configuration
- `spec/fixtures/` - Test Jekyll site with layouts, posts, and assets