require 'terser'
require 'htmlcompressor'
require 'cssminify2'
require 'json/minify'

module Jekyll
  module Minifier
    # ValidationHelpers module provides comprehensive input validation
    # for Jekyll Minifier configurations and content processing
    module ValidationHelpers
      module_function

      # Maximum safe file size for processing (50MB)
      MAX_SAFE_FILE_SIZE = 50 * 1024 * 1024

      # Maximum safe configuration value sizes
      MAX_SAFE_STRING_LENGTH = 10_000
      MAX_SAFE_ARRAY_SIZE = 1_000
      MAX_SAFE_HASH_SIZE = 100

      # Validates boolean configuration values
      # @param [Object] value The value to validate
      # @param [String] key Configuration key name for error messages
      # @return [Boolean, nil] Validated boolean value or nil for invalid
      def validate_boolean(value, key = 'unknown')
        return nil if value.nil?

        case value
        when true, false
          value
        when 'true', '1', 1
          true
        when 'false', '0', 0
          false
        else
          Jekyll.logger.warn("Jekyll Minifier:", "Invalid boolean value for '#{key}': #{value.inspect}. Using default.")
          nil
        end
      end

      # Validates integer configuration values with range checking
      # @param [Object] value The value to validate
      # @param [String] key Configuration key name
      # @param [Integer] min Minimum allowed value
      # @param [Integer] max Maximum allowed value
      # @return [Integer, nil] Validated integer or nil for invalid
      def validate_integer(value, key = 'unknown', min = 0, max = 1_000_000)
        return nil if value.nil?

        begin
          int_value = Integer(value)

          if int_value < min || int_value > max
            Jekyll.logger.warn("Jekyll Minifier:", "Integer value for '#{key}' out of range [#{min}-#{max}]: #{int_value}. Using default.")
            return nil
          end

          int_value
        rescue ArgumentError, TypeError
          Jekyll.logger.warn("Jekyll Minifier:", "Invalid integer value for '#{key}': #{value.inspect}. Using default.")
          nil
        end
      end

      # Validates string configuration values with length and safety checks
      # @param [Object] value The value to validate
      # @param [String] key Configuration key name
      # @param [Integer] max_length Maximum allowed string length
      # @return [String, nil] Validated string or nil for invalid
      def validate_string(value, key = 'unknown', max_length = MAX_SAFE_STRING_LENGTH)
        return nil if value.nil?
        return nil unless value.respond_to?(:to_s)

        str_value = value.to_s

        if str_value.length > max_length
          Jekyll.logger.warn("Jekyll Minifier:", "String value for '#{key}' too long (#{str_value.length} > #{max_length}). Using default.")
          return nil
        end

        # Basic safety check for control characters
        if str_value.match?(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/)
          Jekyll.logger.warn("Jekyll Minifier:", "String value for '#{key}' contains unsafe control characters. Using default.")
          return nil
        end

        str_value
      end

      # Validates array configuration values with size and content checks
      # @param [Object] value The value to validate
      # @param [String] key Configuration key name
      # @param [Integer] max_size Maximum allowed array size
      # @return [Array, nil] Validated array or empty array for invalid
      def validate_array(value, key = 'unknown', max_size = MAX_SAFE_ARRAY_SIZE)
        return [] if value.nil?

        # Convert single values to arrays
        array_value = value.respond_to?(:to_a) ? value.to_a : [value]

        if array_value.size > max_size
          Jekyll.logger.warn("Jekyll Minifier:", "Array value for '#{key}' too large (#{array_value.size} > #{max_size}). Truncating.")
          array_value = array_value.take(max_size)
        end

        # Filter out invalid elements
        valid_elements = array_value.filter_map do |element|
          next nil if element.nil?

          if element.respond_to?(:to_s)
            str_element = element.to_s
            next nil if str_element.empty? || str_element.length > MAX_SAFE_STRING_LENGTH
            str_element
          else
            nil
          end
        end

        valid_elements
      end

      # Validates hash configuration values with size and content checks
      # @param [Object] value The value to validate
      # @param [String] key Configuration key name
      # @param [Integer] max_size Maximum allowed hash size
      # @return [Hash, nil] Validated hash or nil for invalid
      def validate_hash(value, key = 'unknown', max_size = MAX_SAFE_HASH_SIZE)
        return nil if value.nil?
        return nil unless value.respond_to?(:to_h)

        begin
          hash_value = value.to_h

          if hash_value.size > max_size
            Jekyll.logger.warn("Jekyll Minifier:", "Hash value for '#{key}' too large (#{hash_value.size} > #{max_size}). Using default.")
            return nil
          end

          # Validate hash keys and values
          validated_hash = {}
          hash_value.each do |k, v|
            # Convert keys to symbols for consistency
            key_sym = k.respond_to?(:to_sym) ? k.to_sym : nil
            next unless key_sym

            # Basic validation of values
            case v
            when String
              validated_value = validate_string(v, "#{key}[#{key_sym}]")
              validated_hash[key_sym] = validated_value if validated_value
            when Integer, Numeric
              validated_hash[key_sym] = v
            when true, false
              validated_hash[key_sym] = v
            when nil
              # Allow nil values
              validated_hash[key_sym] = nil
            else
              Jekyll.logger.warn("Jekyll Minifier:", "Unsupported value type for '#{key}[#{key_sym}]': #{v.class}. Skipping.")
            end
          end

          validated_hash
        rescue => e
          Jekyll.logger.warn("Jekyll Minifier:", "Failed to validate hash for '#{key}': #{e.message}. Using default.")
          nil
        end
      end

      # Validates file content size and encoding
      # @param [String] content File content to validate
      # @param [String] file_type Type of file (css, js, html, json)
      # @param [String] file_path Path to file for error messages
      # @return [Boolean] True if content is safe to process
      def validate_file_content(content, file_type = 'unknown', file_path = 'unknown')
        return false if content.nil?
        return false unless content.respond_to?(:bytesize)

        # Check file size
        if content.bytesize > MAX_SAFE_FILE_SIZE
          Jekyll.logger.warn("Jekyll Minifier:", "File too large for safe processing: #{file_path} (#{content.bytesize} bytes > #{MAX_SAFE_FILE_SIZE})")
          return false
        end

        # Check encoding validity
        unless content.valid_encoding?
          Jekyll.logger.warn("Jekyll Minifier:", "Invalid encoding in file: #{file_path}. Skipping minification.")
          return false
        end

        # Content validation is handled by the actual minification libraries
        # They will properly parse and validate the content
        true
      end

      # Validates file paths for security issues
      # @param [String] path File path to validate
      # @return [Boolean] True if path is safe
      def validate_file_path(path)
        return false if path.nil? || path.empty?
        return false unless path.respond_to?(:to_s)

        path_str = path.to_s

        # Check for directory traversal attempts
        if path_str.include?('../') || path_str.include?('..\\') || path_str.include?('~/')
          Jekyll.logger.warn("Jekyll Minifier:", "Unsafe file path detected: #{path_str}")
          return false
        end

        # Check for null bytes
        if path_str.include?("\0")
          Jekyll.logger.warn("Jekyll Minifier:", "File path contains null byte: #{path_str}")
          return false
        end

        true
      end
    end

    # CompressorCache module provides thread-safe caching for compressor objects
    # to improve performance by reusing configured compressor instances
    module CompressorCache
      module_function

      # Cache storage with thread-safe access
      @cache_mutex = Mutex.new
      @compressor_caches = {
        css: {},
        js: {},
        html: {}
      }
      @cache_stats = {
        hits: 0,
        misses: 0,
        evictions: 0
      }

      # Maximum cache size per compressor type (reasonable memory limit)
      MAX_CACHE_SIZE = 10

      # Get cached compressor or create and cache new one
      # @param [Symbol] type Compressor type (:css, :js, :html)
      # @param [String] cache_key Unique key for this configuration
      # @param [Proc] factory_block Block that creates the compressor if not cached
      # @return [Object] Cached or newly created compressor instance
      def get_or_create(type, cache_key, &factory_block)
        @cache_mutex.synchronize do
          cache = @compressor_caches[type]

          if cache.key?(cache_key)
            # Cache hit - move to end for LRU
            compressor = cache.delete(cache_key)
            cache[cache_key] = compressor
            @cache_stats[:hits] += 1
            compressor
          else
            # Cache miss - create new compressor
            compressor = factory_block.call

            # Evict oldest entry if cache is full
            if cache.size >= MAX_CACHE_SIZE
              evicted_key = cache.keys.first
              cache.delete(evicted_key)
              @cache_stats[:evictions] += 1
            end

            cache[cache_key] = compressor
            @cache_stats[:misses] += 1
            compressor
          end
        end
      end

      # Generate cache key from configuration hash
      # @param [Hash] config_hash Configuration parameters
      # @return [String] Unique cache key
      def generate_cache_key(config_hash)
        return 'default' if config_hash.nil? || config_hash.empty?

        # Sort keys for consistent hashing
        sorted_config = config_hash.sort.to_h
        # Use SHA256 for consistent, collision-resistant keys
        require 'digest'
        Digest::SHA256.hexdigest(sorted_config.to_s)[0..16] # First 16 chars for brevity
      end

      # Clear all caches (useful for testing and memory management)
      def clear_all
        @cache_mutex.synchronize do
          @compressor_caches.each { |_, cache| cache.clear }
          @cache_stats = { hits: 0, misses: 0, evictions: 0 }
        end
      end

      # Get cache statistics (for monitoring and testing)
      # @return [Hash] Cache hit/miss/eviction statistics
      def stats
        @cache_mutex.synchronize { @cache_stats.dup }
      end

      # Get cache sizes (for monitoring)
      # @return [Hash] Current cache sizes by type
      def cache_sizes
        @cache_mutex.synchronize do
          {
            css: @compressor_caches[:css].size,
            js: @compressor_caches[:js].size,
            html: @compressor_caches[:html].size,
            total: @compressor_caches.values.sum(&:size)
          }
        end
      end

      # Check if caching is effectively working
      # @return [Float] Cache hit ratio (0.0 to 1.0)
      def hit_ratio
        @cache_mutex.synchronize do
          total = @cache_stats[:hits] + @cache_stats[:misses]
          return 0.0 if total == 0
          @cache_stats[:hits].to_f / total
        end
      end
    end

    # Wrapper class to provide enhanced CSS compression for HTML compressor
    # This maintains the same interface as CSSminify2 while adding enhanced features
    class CSSEnhancedWrapper
      def initialize(enhanced_options = {})
        @enhanced_options = enhanced_options
      end

      # Interface method expected by HtmlCompressor
      # @param [String] css CSS content to compress
      # @return [String] Compressed CSS
      def compress(css)
        CSSminify2.compress_enhanced(css, @enhanced_options)
      end
    end

    # CompressorFactory module extracts complex compressor setup logic
    # Reduces complexity and centralizes compressor configuration
    module CompressorFactory
      module_function

      # Creates CSS compressor based on configuration
      # @param [CompressionConfig] config Configuration instance
      # @return [Object] CSS compressor instance
      def create_css_compressor(config)
        # Generate cache key from configuration
        if config.css_enhanced_mode? && config.css_enhanced_options
          cache_key = CompressorCache.generate_cache_key({
            enhanced_mode: true,
            options: config.css_enhanced_options
          })
        else
          cache_key = CompressorCache.generate_cache_key({ enhanced_mode: false })
        end

        # Use cache to get or create compressor
        CompressorCache.get_or_create(:css, cache_key) do
          if config.css_enhanced_mode? && config.css_enhanced_options
            CSSEnhancedWrapper.new(config.css_enhanced_options)
          else
            CSSminify2.new()
          end
        end
      end

      # Creates JavaScript compressor based on configuration
      # @param [CompressionConfig] config Configuration instance
      # @return [Terser] JavaScript compressor instance
      def create_js_compressor(config)
        # Generate cache key from Terser configuration
        cache_key = if config.has_terser_args?
          CompressorCache.generate_cache_key({ terser_args: config.terser_args })
        else
          CompressorCache.generate_cache_key({ terser_args: nil })
        end

        # Use cache to get or create compressor
        CompressorCache.get_or_create(:js, cache_key) do
          if config.has_terser_args?
            ::Terser.new(config.terser_args)
          else
            ::Terser.new()
          end
        end
      end

      # Creates HTML compressor with configured CSS and JS compressors
      # @param [CompressionConfig] config Configuration instance
      # @return [HtmlCompressor::Compressor] HTML compressor instance
      def create_html_compressor(config)
        # Generate cache key from HTML compressor configuration
        html_args = config.html_compressor_args
        cache_key = CompressorCache.generate_cache_key({
          html_args: html_args,
          css_enhanced: config.css_enhanced_mode?,
          css_options: config.css_enhanced_options,
          terser_args: config.terser_args
        })

        # Use cache to get or create HTML compressor
        # Avoid deadlock by creating sub-compressors outside the cache lock
        CompressorCache.get_or_create(:html, cache_key) do
          # Create sub-compressors first (outside the HTML cache lock)
          css_compressor = create_css_compressor_uncached(config)
          js_compressor = create_js_compressor_uncached(config)

          # Create fresh args hash for this instance
          fresh_html_args = html_args.dup
          fresh_html_args[:css_compressor] = css_compressor
          fresh_html_args[:javascript_compressor] = js_compressor
          HtmlCompressor::Compressor.new(fresh_html_args)
        end
      end

      # Internal method to create CSS compressor without caching (avoids deadlock)
      # @param [CompressionConfig] config Configuration instance
      # @return [Object] CSS compressor instance
      def create_css_compressor_uncached(config)
        if config.css_enhanced_mode? && config.css_enhanced_options
          CSSEnhancedWrapper.new(config.css_enhanced_options)
        else
          CSSminify2.new()
        end
      end

      # Internal method to create JS compressor without caching (avoids deadlock)
      # @param [CompressionConfig] config Configuration instance
      # @return [Terser] JavaScript compressor instance
      def create_js_compressor_uncached(config)
        if config.has_terser_args?
          ::Terser.new(config.terser_args)
        else
          ::Terser.new()
        end
      end

      # Compresses CSS content using appropriate compressor with validation
      # @param [String] content CSS content to compress
      # @param [CompressionConfig] config Configuration instance
      # @param [String] file_path Optional file path for error messages
      # @return [String] Compressed CSS content
      def compress_css(content, config, file_path = 'unknown')
        # Validate content before processing
        unless ValidationHelpers.validate_file_content(content, 'css', file_path)
          Jekyll.logger.warn("Jekyll Minifier:", "Skipping CSS compression for unsafe content: #{file_path}")
          return content
        end

        begin
          if config.css_enhanced_mode? && config.css_enhanced_options
            CSSminify2.compress_enhanced(content, config.css_enhanced_options)
          else
            compressor = create_css_compressor(config)
            # Pass nil to disable line breaks completely for performance (PR #61)
            compressor.compress(content, nil)
          end
        rescue => e
          Jekyll.logger.warn("Jekyll Minifier:", "CSS compression failed for #{file_path}: #{e.message}. Using original content.")
          content
        end
      end

      # Compresses JavaScript content using Terser with validation
      # @param [String] content JavaScript content to compress
      # @param [CompressionConfig] config Configuration instance
      # @param [String] file_path Optional file path for error messages
      # @return [String] Compressed JavaScript content
      def compress_js(content, config, file_path = 'unknown')
        # Validate content before processing
        unless ValidationHelpers.validate_file_content(content, 'js', file_path)
          Jekyll.logger.warn("Jekyll Minifier:", "Skipping JavaScript compression for unsafe content: #{file_path}")
          return content
        end

        begin
          compressor = create_js_compressor(config)
          compressor.compile(content)
        rescue => e
          Jekyll.logger.warn("Jekyll Minifier:", "JavaScript compression failed for #{file_path}: #{e.message}. Using original content.")
          content
        end
      end

      # Compresses JSON content with validation
      # @param [String] content JSON content to compress
      # @param [String] file_path Optional file path for error messages
      # @return [String] Compressed JSON content
      def compress_json(content, file_path = 'unknown')
        # Validate content before processing
        unless ValidationHelpers.validate_file_content(content, 'json', file_path)
          Jekyll.logger.warn("Jekyll Minifier:", "Skipping JSON compression for unsafe content: #{file_path}")
          return content
        end

        begin
          JSON.minify(content)
        rescue => e
          Jekyll.logger.warn("Jekyll Minifier:", "JSON compression failed for #{file_path}: #{e.message}. Using original content.")
          content
        end
      end
    end
    # Configuration manager class that eliminates repetitive configuration handling
    # Provides clean accessors while maintaining 100% backward compatibility
    class CompressionConfig
      # Configuration key constants to eliminate magic strings
      CONFIG_ROOT = 'jekyll-minifier'

      # HTML Compression Options
      HTML_REMOVE_SPACES_INSIDE_TAGS = 'remove_spaces_inside_tags'
      HTML_REMOVE_MULTI_SPACES = 'remove_multi_spaces'
      HTML_REMOVE_COMMENTS = 'remove_comments'
      HTML_REMOVE_INTERTAG_SPACES = 'remove_intertag_spaces'
      HTML_REMOVE_QUOTES = 'remove_quotes'
      HTML_COMPRESS_CSS = 'compress_css'
      HTML_COMPRESS_JAVASCRIPT = 'compress_javascript'
      HTML_SIMPLE_DOCTYPE = 'simple_doctype'
      HTML_REMOVE_SCRIPT_ATTRIBUTES = 'remove_script_attributes'
      HTML_REMOVE_STYLE_ATTRIBUTES = 'remove_style_attributes'
      HTML_REMOVE_LINK_ATTRIBUTES = 'remove_link_attributes'
      HTML_REMOVE_FORM_ATTRIBUTES = 'remove_form_attributes'
      HTML_REMOVE_INPUT_ATTRIBUTES = 'remove_input_attributes'
      HTML_REMOVE_JAVASCRIPT_PROTOCOL = 'remove_javascript_protocol'
      HTML_REMOVE_HTTP_PROTOCOL = 'remove_http_protocol'
      HTML_REMOVE_HTTPS_PROTOCOL = 'remove_https_protocol'
      HTML_PRESERVE_LINE_BREAKS = 'preserve_line_breaks'
      HTML_SIMPLE_BOOLEAN_ATTRIBUTES = 'simple_boolean_attributes'
      HTML_COMPRESS_JS_TEMPLATES = 'compress_js_templates'

      # File Type Compression Toggles
      COMPRESS_CSS = 'compress_css'
      COMPRESS_JAVASCRIPT = 'compress_javascript'
      COMPRESS_JSON = 'compress_json'

      # Enhanced CSS Compression Options (cssminify2 v2.1.0+)
      CSS_MERGE_DUPLICATE_SELECTORS = 'css_merge_duplicate_selectors'
      CSS_OPTIMIZE_SHORTHAND_PROPERTIES = 'css_optimize_shorthand_properties'
      CSS_ADVANCED_COLOR_OPTIMIZATION = 'css_advanced_color_optimization'
      CSS_PRESERVE_IE_HACKS = 'css_preserve_ie_hacks'
      CSS_COMPRESS_VARIABLES = 'css_compress_variables'
      CSS_ENHANCED_MODE = 'css_enhanced_mode'

      # JavaScript/Terser Configuration
      TERSER_ARGS = 'terser_args'
      UGLIFIER_ARGS = 'uglifier_args' # Backward compatibility

      # Pattern Preservation
      PRESERVE_PATTERNS = 'preserve_patterns'
      PRESERVE_PHP = 'preserve_php'

      # File Exclusions
      EXCLUDE = 'exclude'

      def initialize(site_config)
        @config = site_config || {}
        @raw_minifier_config = @config[CONFIG_ROOT] || {}

        # Validate and sanitize the configuration
        @minifier_config = validate_configuration(@raw_minifier_config)

        # Pre-compute commonly used values for performance
        @computed_values = {}

        # Pre-compile terser arguments for JavaScript compression
        _compute_terser_args
      end

      # HTML Compression Configuration Accessors
      # Dynamically define accessor methods to reduce repetition
      {
        remove_spaces_inside_tags: [HTML_REMOVE_SPACES_INSIDE_TAGS, nil],
        remove_multi_spaces: [HTML_REMOVE_MULTI_SPACES, nil],
        remove_comments: [HTML_REMOVE_COMMENTS, true],
        remove_intertag_spaces: [HTML_REMOVE_INTERTAG_SPACES, nil],
        remove_quotes: [HTML_REMOVE_QUOTES, nil],
        compress_css_in_html: [HTML_COMPRESS_CSS, true],
        compress_javascript_in_html: [HTML_COMPRESS_JAVASCRIPT, true],
        simple_doctype: [HTML_SIMPLE_DOCTYPE, nil],
        remove_script_attributes: [HTML_REMOVE_SCRIPT_ATTRIBUTES, nil],
        remove_style_attributes: [HTML_REMOVE_STYLE_ATTRIBUTES, nil],
        remove_link_attributes: [HTML_REMOVE_LINK_ATTRIBUTES, nil],
        remove_form_attributes: [HTML_REMOVE_FORM_ATTRIBUTES, nil],
        remove_input_attributes: [HTML_REMOVE_INPUT_ATTRIBUTES, nil],
        remove_javascript_protocol: [HTML_REMOVE_JAVASCRIPT_PROTOCOL, nil],
        remove_http_protocol: [HTML_REMOVE_HTTP_PROTOCOL, nil],
        remove_https_protocol: [HTML_REMOVE_HTTPS_PROTOCOL, nil],
        preserve_line_breaks: [HTML_PRESERVE_LINE_BREAKS, nil],
        simple_boolean_attributes: [HTML_SIMPLE_BOOLEAN_ATTRIBUTES, nil],
        compress_js_templates: [HTML_COMPRESS_JS_TEMPLATES, nil]
      }.each do |method_name, (config_key, default_value)|
        define_method(method_name) do
          get_boolean(config_key, default_value)
        end
      end

      # File Type Compression Toggles
      def compress_css?
        get_boolean(COMPRESS_CSS, true) # Default to true
      end

      def compress_javascript?
        get_boolean(COMPRESS_JAVASCRIPT, true) # Default to true
      end

      def compress_json?
        get_boolean(COMPRESS_JSON, true) # Default to true
      end

      # Enhanced CSS Compression Configuration
      # Dynamically define CSS enhancement accessor methods
      {
        css_enhanced_mode?: [CSS_ENHANCED_MODE, false],
        css_merge_duplicate_selectors?: [CSS_MERGE_DUPLICATE_SELECTORS, false],
        css_optimize_shorthand_properties?: [CSS_OPTIMIZE_SHORTHAND_PROPERTIES, false],
        css_advanced_color_optimization?: [CSS_ADVANCED_COLOR_OPTIMIZATION, false],
        css_preserve_ie_hacks?: [CSS_PRESERVE_IE_HACKS, true],
        css_compress_variables?: [CSS_COMPRESS_VARIABLES, false]
      }.each do |method_name, (config_key, default_value)|
        define_method(method_name) do
          get_boolean(config_key, default_value)
        end
      end

      # Generate enhanced CSS compression options hash
      def css_enhanced_options
        return nil unless css_enhanced_mode?

        {
          merge_duplicate_selectors: css_merge_duplicate_selectors?,
          optimize_shorthand_properties: css_optimize_shorthand_properties?,
          advanced_color_optimization: css_advanced_color_optimization?,
          preserve_ie_hacks: css_preserve_ie_hacks?,
          compress_css_variables: css_compress_variables?
        }
      end

      # JavaScript/Terser Configuration
      def terser_args
        @computed_values[:terser_args]
      end

      def has_terser_args?
        !terser_args.nil?
      end

      # Pattern Preservation
      def preserve_patterns
        patterns = get_array(PRESERVE_PATTERNS)
        return patterns unless patterns.empty?

        # Return empty array if no patterns configured
        []
      end

      def preserve_php?
        get_boolean(PRESERVE_PHP, false)
      end

      def php_preserve_pattern
        /<\?php.*?\?>/im
      end

      # File Exclusions
      def exclude_patterns
        get_array(EXCLUDE)
      end

      # Generate HTML compressor arguments hash
      # Maintains exact same behavior as original implementation
      def html_compressor_args
        args = base_html_args
        apply_html_config_overrides(args)
        apply_preserve_patterns(args)
        args
      end

      private

      def base_html_args
        {
          remove_comments: true,
          compress_css: true,
          compress_javascript: true,
          preserve_patterns: []
        }
      end

      def apply_html_config_overrides(args)
        html_config_methods.each do |method, key|
          value = send(method)
          args[key] = value unless value.nil?
        end
      end

      def html_config_methods
        {
          remove_spaces_inside_tags: :remove_spaces_inside_tags,
          remove_multi_spaces: :remove_multi_spaces,
          remove_comments: :remove_comments,
          remove_intertag_spaces: :remove_intertag_spaces,
          remove_quotes: :remove_quotes,
          compress_css_in_html: :compress_css,
          compress_javascript_in_html: :compress_javascript,
          simple_doctype: :simple_doctype,
          remove_script_attributes: :remove_script_attributes,
          remove_style_attributes: :remove_style_attributes,
          remove_link_attributes: :remove_link_attributes,
          remove_form_attributes: :remove_form_attributes,
          remove_input_attributes: :remove_input_attributes,
          remove_javascript_protocol: :remove_javascript_protocol,
          remove_http_protocol: :remove_http_protocol,
          remove_https_protocol: :remove_https_protocol,
          preserve_line_breaks: :preserve_line_breaks,
          simple_boolean_attributes: :simple_boolean_attributes,
          compress_js_templates: :compress_js_templates
        }
      end

      def apply_preserve_patterns(args)
        args[:preserve_patterns] += [php_preserve_pattern] if preserve_php?

        configured_patterns = preserve_patterns
        if !configured_patterns.empty? && configured_patterns.respond_to?(:map)
          compiled_patterns = compile_preserve_patterns(configured_patterns)
          args[:preserve_patterns] += compiled_patterns
        end
      end

      # Validates the entire minifier configuration structure
      # @param [Hash] raw_config Raw configuration hash
      # @return [Hash] Validated and sanitized configuration
      def validate_configuration(raw_config)
        return {} unless raw_config.respond_to?(:to_h)

        validated_config = {}

        raw_config.each do |key, value|
          validated_key = ValidationHelpers.validate_string(key, "config_key", 100)
          next unless validated_key

          validated_value = validate_config_value(validated_key, value)
          validated_config[validated_key] = validated_value unless validated_value.nil?
        end

        validated_config
      rescue => e
        Jekyll.logger.warn("Jekyll Minifier:", "Configuration validation failed: #{e.message}. Using defaults.")
        {}
      end

      # Validates individual configuration values based on their key
      # @param [String] key Configuration key
      # @param [Object] value Configuration value
      # @return [Object, nil] Validated value or nil for invalid
      def validate_config_value(key, value)
        case key
        # Boolean HTML compression options
        when HTML_REMOVE_SPACES_INSIDE_TAGS, HTML_REMOVE_MULTI_SPACES, HTML_REMOVE_COMMENTS,
             HTML_REMOVE_INTERTAG_SPACES, HTML_REMOVE_QUOTES, HTML_COMPRESS_CSS,
             HTML_COMPRESS_JAVASCRIPT, HTML_SIMPLE_DOCTYPE, HTML_REMOVE_SCRIPT_ATTRIBUTES,
             HTML_REMOVE_STYLE_ATTRIBUTES, HTML_REMOVE_LINK_ATTRIBUTES, HTML_REMOVE_FORM_ATTRIBUTES,
             HTML_REMOVE_INPUT_ATTRIBUTES, HTML_REMOVE_JAVASCRIPT_PROTOCOL, HTML_REMOVE_HTTP_PROTOCOL,
             HTML_REMOVE_HTTPS_PROTOCOL, HTML_PRESERVE_LINE_BREAKS, HTML_SIMPLE_BOOLEAN_ATTRIBUTES,
             HTML_COMPRESS_JS_TEMPLATES, COMPRESS_CSS, COMPRESS_JAVASCRIPT, COMPRESS_JSON,
             CSS_MERGE_DUPLICATE_SELECTORS, CSS_OPTIMIZE_SHORTHAND_PROPERTIES,
             CSS_ADVANCED_COLOR_OPTIMIZATION, CSS_PRESERVE_IE_HACKS, CSS_COMPRESS_VARIABLES,
             CSS_ENHANCED_MODE, PRESERVE_PHP
          ValidationHelpers.validate_boolean(value, key)

        # Array configurations - for backward compatibility, don't validate these strictly
        when PRESERVE_PATTERNS, EXCLUDE
          # Let the existing get_array method handle the conversion for backward compatibility
          value

        # Hash configurations (Terser/Uglifier args)
        when TERSER_ARGS, UGLIFIER_ARGS
          validate_compressor_args(value, key)

        else
          # Pass through other values for backward compatibility
          value
        end
      end

      # Validates compressor arguments (Terser/Uglifier) with security checks
      # @param [Object] value Compressor arguments
      # @param [String] key Configuration key name
      # @return [Hash, nil] Validated compressor arguments or nil
      def validate_compressor_args(value, key)
        validated_hash = ValidationHelpers.validate_hash(value, key, 20) # Limit to 20 options
        return nil unless validated_hash

        # Additional validation for known dangerous options
        safe_args = {}
        validated_hash.each do |k, v|
          case k.to_s
          when 'eval', 'with', 'toplevel'
            # These options can be dangerous - validate more strictly
            safe_value = ValidationHelpers.validate_boolean(v, "#{key}[#{k}]")
            safe_args[k] = safe_value unless safe_value.nil?
          when 'compress', 'mangle', 'output'
            # These can be hashes or booleans
            if v.respond_to?(:to_h)
              # Handle as hash - preserve the structure for Terser compatibility
              safe_args[k] = v.to_h
            else
              safe_value = ValidationHelpers.validate_boolean(v, "#{key}[#{k}]")
              safe_args[k] = safe_value unless safe_value.nil?
            end
          when 'ecma', 'ie8', 'safari10'
            # Numeric or boolean options
            if v.is_a?(Numeric)
              safe_args[k] = ValidationHelpers.validate_integer(v, "#{key}[#{k}]", 3, 2020)
            else
              safe_value = ValidationHelpers.validate_boolean(v, "#{key}[#{k}]")
              safe_args[k] = safe_value unless safe_value.nil?
            end
          when 'harmony'
            # Legacy Uglifier option - filter out for Terser
            Jekyll.logger.info("Jekyll Minifier:", "Filtering out legacy 'harmony' option from #{key}")
            # Don't add to safe_args
          else
            # Other options - basic validation
            case v
            when String
              safe_value = ValidationHelpers.validate_string(v, "#{key}[#{k}]", 500)
              safe_args[k] = safe_value if safe_value
            when Numeric
              safe_args[k] = ValidationHelpers.validate_integer(v, "#{key}[#{k}]", -1000, 1000)
            when true, false
              safe_args[k] = v
            when nil
              safe_args[k] = nil
            else
              Jekyll.logger.warn("Jekyll Minifier:", "Unsupported option type for #{key}[#{k}]: #{v.class}")
            end
          end
        end

        safe_args.empty? ? nil : safe_args
      end

      def get_boolean(key, default = nil)
        return default unless @minifier_config.has_key?(key)
        # Additional runtime validation for boolean values
        value = @minifier_config[key]
        validated = ValidationHelpers.validate_boolean(value, key)
        validated.nil? ? default : validated
      end

      def get_array(key)
        value = @minifier_config[key]
        return [] if value.nil?

        # For backward compatibility, if value exists but isn't an array, convert it
        return value if value.respond_to?(:to_a)
        [value]
      end

      # Pre-compute terser arguments for performance
      def _compute_terser_args
        # Support both terser_args and uglifier_args for backward compatibility
        # Use validated configuration
        terser_options = @minifier_config[TERSER_ARGS] || @minifier_config[UGLIFIER_ARGS]

        if terser_options && terser_options.respond_to?(:map)
          # Apply validation to the terser options
          validated_options = validate_compressor_args(terser_options, TERSER_ARGS)

          if validated_options && !validated_options.empty?
            # Convert keys to symbols for consistency
            @computed_values[:terser_args] = Hash[validated_options.map{|(k,v)| [k.to_sym,v]}]
          else
            # Fallback to original logic if validation fails
            filtered_options = terser_options.reject { |k, v| k.to_s == 'harmony' }
            @computed_values[:terser_args] = Hash[filtered_options.map{|(k,v)| [k.to_sym,v]}] unless filtered_options.empty?
          end
        else
          @computed_values[:terser_args] = nil
        end
      end

      # Import the compile_preserve_patterns method to maintain exact same behavior
      # This will be made accessible through dependency injection
      def compile_preserve_patterns(patterns)
        return [] unless patterns.respond_to?(:map)

        patterns.filter_map { |pattern| compile_single_pattern(pattern) }
      end

      private

      def compile_single_pattern(pattern)
        begin
          # ReDoS protection: validate pattern complexity and add timeout
          if valid_regex_pattern?(pattern)
            # Use timeout to prevent ReDoS attacks during compilation
            regex = compile_regex_with_timeout(pattern, 1.0) # 1 second timeout
            return regex if regex
          else
            # Log invalid pattern but continue processing (graceful degradation)
            Jekyll.logger.warn("Jekyll Minifier:", "Skipping potentially unsafe regex pattern: #{pattern.inspect}")
          end
        rescue => e
          # Graceful error handling - log warning but don't fail the build
          Jekyll.logger.warn("Jekyll Minifier:", "Failed to compile preserve pattern #{pattern.inspect}: #{e.message}")
        end
        nil
      end

      def valid_regex_pattern?(pattern)
        return false unless pattern.is_a?(String) && !pattern.empty? && !pattern.strip.empty?
        return false if pattern.length > 1000

        # Basic ReDoS vulnerability checks using a more efficient approach
        redos_checks = [
          /\([^)]*[+*]\)[+*]/, # nested quantifiers
          /\([^)]*\|[^)]*\)[+*]/ # alternation with overlapping patterns
        ]

        return false if redos_checks.any? { |check| pattern =~ check }
        return false if pattern.count('(') > 10 # excessive nesting
        return false if pattern.scan(/[+*?]\??/).length > 20 # excessive quantifiers

        true
      end

      def compile_regex_with_timeout(pattern, timeout_seconds)
        result = nil
        thread = Thread.new { result = create_regex_safely(pattern) }

        if thread.join(timeout_seconds)
          result
        else
          thread.kill
          Jekyll.logger.warn("Jekyll Minifier:", "Regex compilation timeout for pattern: #{pattern.inspect}")
          nil
        end
      end

      def create_regex_safely(pattern)
        Regexp.new(pattern)
      rescue RegexpError => e
        Jekyll.logger.warn("Jekyll Minifier:", "Invalid regex pattern #{pattern.inspect}: #{e.message}")
        nil
      end
    end
  end
  module Compressor
    def output_file(dest, content)
      FileUtils.mkdir_p(File.dirname(dest))
      File.open(dest, 'w') do |f|
        f.write(content)
      end
    end

    def output_compressed(path, context)
      extension = File.extname(path)

      case extension
      when '.js'
        output_js_or_file(path, context)
      when '.json'
        output_json(path, context)
      when '.css'
        output_css_or_file(path, context)
      else
        output_html(path, context)
      end
    end

    def output_js_or_file(path, context)
      if path.end_with?('.min.js')
        output_file(path, context)
      else
        output_js(path, context)
      end
    end

    def output_css_or_file(path, context)
      if path.end_with?('.min.css')
        output_file(path, context)
      else
        output_css(path, context)
      end
    end

    def output_html(path, content)
      return output_file(path, content) unless production_environment?

      # Validate file path for security
      unless Jekyll::Minifier::ValidationHelpers.validate_file_path(path)
        Jekyll.logger.warn("Jekyll Minifier:", "Unsafe file path detected, skipping compression: #{path}")
        return # Don't write anything for unsafe paths
      end

      # Validate content before compression
      unless Jekyll::Minifier::ValidationHelpers.validate_file_content(content, 'html', path)
        Jekyll.logger.warn("Jekyll Minifier:", "Unsafe HTML content detected, skipping compression: #{path}")
        return output_file(path, content)
      end

      config = Jekyll::Minifier::CompressionConfig.new(@site.config)

      begin
        compressor = Jekyll::Minifier::CompressorFactory.create_html_compressor(config)
        compressed_content = compressor.compress(content)
        output_file(path, compressed_content)
      rescue => e
        Jekyll.logger.warn("Jekyll Minifier:", "HTML compression failed for #{path}: #{e.message}. Using original content.")
        output_file(path, content)
      end
    end

    def output_js(path, content)
      return output_file(path, content) unless production_environment?

      # Validate file path for security
      unless Jekyll::Minifier::ValidationHelpers.validate_file_path(path)
        Jekyll.logger.warn("Jekyll Minifier:", "Unsafe file path detected, skipping compression: #{path}")
        return # Don't write anything for unsafe paths
      end

      config = Jekyll::Minifier::CompressionConfig.new(@site.config)
      return output_file(path, content) unless config.compress_javascript?

      compressed_content = Jekyll::Minifier::CompressorFactory.compress_js(content, config, path)
      output_file(path, compressed_content)
    end

    def output_json(path, content)
      return output_file(path, content) unless production_environment?

      # Validate file path for security
      unless Jekyll::Minifier::ValidationHelpers.validate_file_path(path)
        Jekyll.logger.warn("Jekyll Minifier:", "Unsafe file path detected, skipping compression: #{path}")
        return # Don't write anything for unsafe paths
      end

      config = Jekyll::Minifier::CompressionConfig.new(@site.config)
      return output_file(path, content) unless config.compress_json?

      compressed_content = Jekyll::Minifier::CompressorFactory.compress_json(content, path)
      output_file(path, compressed_content)
    end

    def output_css(path, content)
      return output_file(path, content) unless production_environment?

      # Validate file path for security
      unless Jekyll::Minifier::ValidationHelpers.validate_file_path(path)
        Jekyll.logger.warn("Jekyll Minifier:", "Unsafe file path detected, skipping compression: #{path}")
        return # Don't write anything for unsafe paths
      end

      config = Jekyll::Minifier::CompressionConfig.new(@site.config)
      return output_file(path, content) unless config.compress_css?

      compressed_content = Jekyll::Minifier::CompressorFactory.compress_css(content, config, path)
      output_file(path, compressed_content)
    end

    private

    def production_environment?
      ENV['JEKYLL_ENV'] == "production"
    end

    # Delegator methods for backward compatibility with existing tests
    # These delegate to the CompressionConfig class methods
    def compile_preserve_patterns(patterns)
      config = Jekyll::Minifier::CompressionConfig.new(@site.config)
      config.send(:compile_preserve_patterns, patterns)
    end

    def valid_regex_pattern?(pattern)
      config = Jekyll::Minifier::CompressionConfig.new(@site.config)
      config.send(:valid_regex_pattern?, pattern)
    end

    def compile_regex_with_timeout(pattern, timeout_seconds)
      config = Jekyll::Minifier::CompressionConfig.new(@site.config)
      config.send(:compile_regex_with_timeout, pattern, timeout_seconds)
    end


    def exclude?(dest, dest_path)
      file_name = dest_path.slice(dest.length+1..dest_path.length)
      exclude.any? { |e| e == file_name || File.fnmatch(e, file_name) }
    end

    def exclude
      @exclude ||= begin
        config = Jekyll::Minifier::CompressionConfig.new(@site.config)
        config.exclude_patterns
      end
    end
  end

  class Document
    include Compressor

    def write(dest)
      dest_path = destination(dest)
      if exclude?(dest, dest_path)
        output_file(dest_path, output)
      else
        output_compressed(dest_path, output)
      end
      trigger_hooks(:post_write)
    end
  end

  class Page
    include Compressor

    def write(dest)
      dest_path = destination(dest)
      if exclude?(dest, dest_path)
        output_file(dest_path, output)
      else
        output_compressed(dest_path, output)
      end
      Jekyll::Hooks.trigger hook_owner, :post_write, self
    end
  end

  class StaticFile
    include Compressor

    def copy_file(path, dest_path)
      FileUtils.mkdir_p(File.dirname(dest_path))
      FileUtils.cp(path, dest_path)
    end

    def write(dest)
      dest_path = destination(dest)

      return false if File.exist?(dest_path) and !modified?
      self.class.mtimes[path] = mtime

      if exclude?(dest, dest_path)
        copy_file(path, dest_path)
      else
        process_static_file(dest_path)
      end
      true
    end

    private

    def process_static_file(dest_path)
      extension = File.extname(dest_path)
      content = File.read(path)

      case extension
      when '.js'
        process_js_file(dest_path, content)
      when '.json'
        output_json(dest_path, content)
      when '.css'
        process_css_file(dest_path, content)
      when '.xml'
        output_html(dest_path, content)
      else
        copy_file(path, dest_path)
      end
    end

    def process_js_file(dest_path, content)
      if dest_path.end_with?('.min.js')
        copy_file(path, dest_path)
      else
        output_js(dest_path, content)
      end
    end

    def process_css_file(dest_path, content)
      if dest_path.end_with?('.min.css')
        copy_file(path, dest_path)
      else
        output_css(dest_path, content)
      end
    end
  end
end
