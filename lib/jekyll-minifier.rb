require 'terser'
require 'htmlcompressor'
require 'cssminify2'
require 'json/minify'

module Jekyll
  module Minifier
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
        @minifier_config = @config[CONFIG_ROOT] || {}
        
        # Pre-compute commonly used values for performance
        @computed_values = {}
        
        # Pre-compile terser arguments for JavaScript compression
        _compute_terser_args
      end

      # HTML Compression Configuration Accessors
      def remove_spaces_inside_tags
        get_boolean(HTML_REMOVE_SPACES_INSIDE_TAGS)
      end

      def remove_multi_spaces
        get_boolean(HTML_REMOVE_MULTI_SPACES)
      end

      def remove_comments
        get_boolean(HTML_REMOVE_COMMENTS, true) # Default to true
      end

      def remove_intertag_spaces
        get_boolean(HTML_REMOVE_INTERTAG_SPACES)
      end

      def remove_quotes
        get_boolean(HTML_REMOVE_QUOTES)
      end

      def compress_css_in_html
        get_boolean(HTML_COMPRESS_CSS, true) # Default to true
      end

      def compress_javascript_in_html
        get_boolean(HTML_COMPRESS_JAVASCRIPT, true) # Default to true
      end

      def simple_doctype
        get_boolean(HTML_SIMPLE_DOCTYPE)
      end

      def remove_script_attributes
        get_boolean(HTML_REMOVE_SCRIPT_ATTRIBUTES)
      end

      def remove_style_attributes
        get_boolean(HTML_REMOVE_STYLE_ATTRIBUTES)
      end

      def remove_link_attributes
        get_boolean(HTML_REMOVE_LINK_ATTRIBUTES)
      end

      def remove_form_attributes
        get_boolean(HTML_REMOVE_FORM_ATTRIBUTES)
      end

      def remove_input_attributes
        get_boolean(HTML_REMOVE_INPUT_ATTRIBUTES)
      end

      def remove_javascript_protocol
        get_boolean(HTML_REMOVE_JAVASCRIPT_PROTOCOL)
      end

      def remove_http_protocol
        get_boolean(HTML_REMOVE_HTTP_PROTOCOL)
      end

      def remove_https_protocol
        get_boolean(HTML_REMOVE_HTTPS_PROTOCOL)
      end

      def preserve_line_breaks
        get_boolean(HTML_PRESERVE_LINE_BREAKS)
      end

      def simple_boolean_attributes
        get_boolean(HTML_SIMPLE_BOOLEAN_ATTRIBUTES)
      end

      def compress_js_templates
        get_boolean(HTML_COMPRESS_JS_TEMPLATES)
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
      def css_enhanced_mode?
        get_boolean(CSS_ENHANCED_MODE, false) # Default to false for backward compatibility
      end

      def css_merge_duplicate_selectors?
        get_boolean(CSS_MERGE_DUPLICATE_SELECTORS, false)
      end

      def css_optimize_shorthand_properties?
        get_boolean(CSS_OPTIMIZE_SHORTHAND_PROPERTIES, false)
      end

      def css_advanced_color_optimization?
        get_boolean(CSS_ADVANCED_COLOR_OPTIMIZATION, false)
      end

      def css_preserve_ie_hacks?
        get_boolean(CSS_PRESERVE_IE_HACKS, true) # Default to true to preserve IE hacks
      end

      def css_compress_variables?
        get_boolean(CSS_COMPRESS_VARIABLES, false)
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
        args = { 
          remove_comments: true, 
          compress_css: true, 
          compress_javascript: true, 
          preserve_patterns: [] 
        }

        # Apply configuration overrides - same logic as original
        args[:remove_spaces_inside_tags] = remove_spaces_inside_tags unless remove_spaces_inside_tags.nil?
        args[:remove_multi_spaces] = remove_multi_spaces unless remove_multi_spaces.nil?
        args[:remove_comments] = remove_comments unless remove_comments.nil?
        args[:remove_intertag_spaces] = remove_intertag_spaces unless remove_intertag_spaces.nil?
        args[:remove_quotes] = remove_quotes unless remove_quotes.nil?
        args[:compress_css] = compress_css_in_html unless compress_css_in_html.nil?
        args[:compress_javascript] = compress_javascript_in_html unless compress_javascript_in_html.nil?
        args[:simple_doctype] = simple_doctype unless simple_doctype.nil?
        args[:remove_script_attributes] = remove_script_attributes unless remove_script_attributes.nil?
        args[:remove_style_attributes] = remove_style_attributes unless remove_style_attributes.nil?
        args[:remove_link_attributes] = remove_link_attributes unless remove_link_attributes.nil?
        args[:remove_form_attributes] = remove_form_attributes unless remove_form_attributes.nil?
        args[:remove_input_attributes] = remove_input_attributes unless remove_input_attributes.nil?
        args[:remove_javascript_protocol] = remove_javascript_protocol unless remove_javascript_protocol.nil?
        args[:remove_http_protocol] = remove_http_protocol unless remove_http_protocol.nil?
        args[:remove_https_protocol] = remove_https_protocol unless remove_https_protocol.nil?
        args[:preserve_line_breaks] = preserve_line_breaks unless preserve_line_breaks.nil?
        args[:simple_boolean_attributes] = simple_boolean_attributes unless simple_boolean_attributes.nil?
        args[:compress_js_templates] = compress_js_templates unless compress_js_templates.nil?

        # Handle preserve patterns - exact same logic as original
        args[:preserve_patterns] += [php_preserve_pattern] if preserve_php?
        
        configured_patterns = preserve_patterns
        if !configured_patterns.empty? && configured_patterns.respond_to?(:map)
          # Use the same compile_preserve_patterns method as original implementation
          compiled_patterns = compile_preserve_patterns(configured_patterns)
          args[:preserve_patterns] += compiled_patterns
        end

        args
      end

      private

      def get_boolean(key, default = nil)
        return default unless @minifier_config.has_key?(key)
        @minifier_config[key]
      end

      def get_array(key)
        value = @minifier_config[key]
        return [] if value.nil?
        return value if value.respond_to?(:to_a)
        [value]
      end

      # Pre-compute terser arguments for performance
      def _compute_terser_args
        # Support both terser_args and uglifier_args for backward compatibility
        # Exact same logic as original implementation
        terser_options = @minifier_config[TERSER_ARGS] || @minifier_config[UGLIFIER_ARGS]
        
        if terser_options && terser_options.respond_to?(:map)
          # Filter out Uglifier-specific options that don't have Terser equivalents
          filtered_options = terser_options.reject { |k, v| k.to_s == 'harmony' }
          @computed_values[:terser_args] = Hash[filtered_options.map{|(k,v)| [k.to_sym,v]}] unless filtered_options.empty?
        else
          @computed_values[:terser_args] = nil
        end
      end

      # Import the compile_preserve_patterns method to maintain exact same behavior
      # This will be made accessible through dependency injection
      def compile_preserve_patterns(patterns)
        return [] unless patterns.respond_to?(:map)
        
        compiled_patterns = []
        patterns.each do |pattern|
          begin
            # ReDoS protection: validate pattern complexity and add timeout
            if valid_regex_pattern?(pattern)
              # Use timeout to prevent ReDoS attacks during compilation
              regex = compile_regex_with_timeout(pattern, 1.0) # 1 second timeout
              compiled_patterns << regex if regex
            else
              # Log invalid pattern but continue processing (graceful degradation)
              Jekyll.logger.warn("Jekyll Minifier:", "Skipping potentially unsafe regex pattern: #{pattern.inspect}")
            end
          rescue => e
            # Graceful error handling - log warning but don't fail the build
            Jekyll.logger.warn("Jekyll Minifier:", "Failed to compile preserve pattern #{pattern.inspect}: #{e.message}")
          end
        end
        
        compiled_patterns
      end

      def valid_regex_pattern?(pattern)
        return false unless pattern.is_a?(String)
        return false if pattern.empty?
        return false if pattern.strip.empty? # Reject whitespace-only patterns
        return false if pattern.length > 1000 # Prevent excessively long patterns
        
        # Basic ReDoS vulnerability checks
        # Check for nested quantifiers (e.g., (a+)+ or (a*)*) which are common ReDoS vectors
        return false if pattern =~ /\([^)]*[+*]\)[+*]/
        
        # Check for alternation with overlapping patterns (e.g., (a|a)*) 
        return false if pattern =~ /\([^)]*\|[^)]*\)[+*]/
        
        # Check for excessive nesting depth (simple heuristic)
        open_parens = pattern.count('(')
        return false if open_parens > 10
        
        # Check for excessive quantifier usage
        quantifiers = pattern.scan(/[+*?]\??/).length
        return false if quantifiers > 20
        
        true
      end

      def compile_regex_with_timeout(pattern, timeout_seconds)
        # Create a thread to compile the regex with timeout
        result = nil
        thread = Thread.new do
          begin
            result = Regexp.new(pattern)
          rescue RegexpError => e
            Jekyll.logger.warn("Jekyll Minifier:", "Invalid regex pattern #{pattern.inspect}: #{e.message}")
            result = nil
          end
        end
        
        # Wait for compilation with timeout
        if thread.join(timeout_seconds)
          result
        else
          # Kill the thread and return nil if timeout exceeded
          thread.kill
          Jekyll.logger.warn("Jekyll Minifier:", "Regex compilation timeout for pattern: #{pattern.inspect}")
          nil
        end
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
      case File.extname(path)
        when '.js'
          if path.end_with?('.min.js')
            output_file(path, context)
          else
            output_js(path, context)
          end
        when '.json'
          output_json(path, context)
        when '.css'
          if path.end_with?('.min.css')
            output_file(path, context)
          else
            output_css(path, context)
          end
        else
          output_html(path, context)
      end
    end

    def output_html(path, content)
      if production_environment?
        config = Jekyll::Minifier::CompressionConfig.new(@site.config)
        html_args = config.html_compressor_args

        # Configure CSS compressor based on enhanced mode setting
        if config.css_enhanced_mode? && config.css_enhanced_options
          # Create a wrapper for enhanced CSS compression in HTML
          html_args[:css_compressor] = Jekyll::Minifier::CSSEnhancedWrapper.new(config.css_enhanced_options)
        else
          html_args[:css_compressor] = CSSminify2.new()
        end

        if config.has_terser_args?
          html_args[:javascript_compressor] = ::Terser.new(config.terser_args)
        else
          html_args[:javascript_compressor] = ::Terser.new()
        end

        compressor = HtmlCompressor::Compressor.new(html_args)
        output_file(path, compressor.compress(content))
      else
        output_file(path, content)
      end
    end

    def output_js(path, content)
      if production_environment?
        config = Jekyll::Minifier::CompressionConfig.new(@site.config)

        if config.compress_javascript?
          if config.has_terser_args?
            compressor = ::Terser.new(config.terser_args)
          else
            compressor = ::Terser.new()
          end

          output_file(path, compressor.compile(content))
        else
          output_file(path, content)
        end
      else
        output_file(path, content)
      end
    end

    def output_json(path, content)
      if production_environment?
        config = Jekyll::Minifier::CompressionConfig.new(@site.config)

        if config.compress_json?
          output_file(path, JSON.minify(content))
        else
          output_file(path, content)
        end
      else
        output_file(path, content)
      end
    end

    def output_css(path, content)
      if production_environment?
        config = Jekyll::Minifier::CompressionConfig.new(@site.config)

        if config.compress_css?
          if config.css_enhanced_mode? && config.css_enhanced_options
            # Use enhanced compression with configurable options
            compressed_content = CSSminify2.compress_enhanced(content, config.css_enhanced_options)
          else
            # Use standard compression (maintains backward compatibility)
            compressor = CSSminify2.new()
            # Pass nil to disable line breaks completely for performance (PR #61)
            compressed_content = compressor.compress(content, nil)
          end
          output_file(path, compressed_content)
        else
          output_file(path, content)
        end
      else
        output_file(path, content)
      end
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
        case File.extname(dest_path)
          when '.js'
            if dest_path.end_with?('.min.js')
              copy_file(path, dest_path)
            else
              output_js(dest_path, File.read(path))
            end
          when '.json'
            output_json(dest_path, File.read(path))
          when '.css'
            if dest_path.end_with?('.min.css')
              copy_file(path, dest_path)
            else
              output_css(dest_path, File.read(path))
            end
          when '.xml'
            output_html(dest_path, File.read(path))
          else
            copy_file(path, dest_path)
        end
      end
      true
    end
  end
end
