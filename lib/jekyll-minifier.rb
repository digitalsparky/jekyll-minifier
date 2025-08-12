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

    # CompressorFactory module extracts complex compressor setup logic
    # Reduces complexity and centralizes compressor configuration
    module CompressorFactory
      module_function

      # Creates CSS compressor based on configuration
      # @param [CompressionConfig] config Configuration instance
      # @return [Object] CSS compressor instance
      def create_css_compressor(config)
        if config.css_enhanced_mode? && config.css_enhanced_options
          CSSEnhancedWrapper.new(config.css_enhanced_options)
        else
          CSSminify2.new()
        end
      end

      # Creates JavaScript compressor based on configuration
      # @param [CompressionConfig] config Configuration instance
      # @return [Terser] JavaScript compressor instance
      def create_js_compressor(config)
        if config.has_terser_args?
          ::Terser.new(config.terser_args)
        else
          ::Terser.new()
        end
      end

      # Creates HTML compressor with configured CSS and JS compressors
      # @param [CompressionConfig] config Configuration instance
      # @return [HtmlCompressor::Compressor] HTML compressor instance
      def create_html_compressor(config)
        html_args = config.html_compressor_args
        html_args[:css_compressor] = create_css_compressor(config)
        html_args[:javascript_compressor] = create_js_compressor(config)
        HtmlCompressor::Compressor.new(html_args)
      end

      # Compresses CSS content using appropriate compressor
      # @param [String] content CSS content to compress
      # @param [CompressionConfig] config Configuration instance
      # @return [String] Compressed CSS content
      def compress_css(content, config)
        if config.css_enhanced_mode? && config.css_enhanced_options
          CSSminify2.compress_enhanced(content, config.css_enhanced_options)
        else
          compressor = CSSminify2.new()
          # Pass nil to disable line breaks completely for performance (PR #61)
          compressor.compress(content, nil)
        end
      end

      # Compresses JavaScript content using Terser
      # @param [String] content JavaScript content to compress
      # @param [CompressionConfig] config Configuration instance
      # @return [String] Compressed JavaScript content
      def compress_js(content, config)
        compressor = create_js_compressor(config)
        compressor.compile(content)
      end

      # Compresses JSON content
      # @param [String] content JSON content to compress
      # @return [String] Compressed JSON content
      def compress_json(content)
        JSON.minify(content)
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
      
      config = Jekyll::Minifier::CompressionConfig.new(@site.config)
      compressor = Jekyll::Minifier::CompressorFactory.create_html_compressor(config)
      output_file(path, compressor.compress(content))
    end

    def output_js(path, content)
      return output_file(path, content) unless production_environment?
      
      config = Jekyll::Minifier::CompressionConfig.new(@site.config)
      return output_file(path, content) unless config.compress_javascript?
      
      compressed_content = Jekyll::Minifier::CompressorFactory.compress_js(content, config)
      output_file(path, compressed_content)
    end

    def output_json(path, content)
      return output_file(path, content) unless production_environment?
      
      config = Jekyll::Minifier::CompressionConfig.new(@site.config)
      return output_file(path, content) unless config.compress_json?
      
      compressed_content = Jekyll::Minifier::CompressorFactory.compress_json(content)
      output_file(path, compressed_content)
    end

    def output_css(path, content)
      return output_file(path, content) unless production_environment?
      
      config = Jekyll::Minifier::CompressionConfig.new(@site.config)
      return output_file(path, content) unless config.compress_css?
      
      compressed_content = Jekyll::Minifier::CompressorFactory.compress_css(content, config)
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
