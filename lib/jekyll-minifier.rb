require 'uglifier'
require 'htmlcompressor'
require 'cssminify2'

module Jekyll
  module Compressor
    def exclude?(dest, dest_path)
      res = false
      file_name = dest_path.slice(dest.length+1..dest_path.length)
      exclude = @site.config['jekyll-minifier'] && @site.config['jekyll-minifier']['exclude']
      if exclude
        if exclude.is_a? String
          exclude = [exclude]
        end
        exclude.each do |e|
          if e == file_name || File.fnmatch(e, file_name)
            res = true
            break
          end
        end
      end
      res
    end

    def output_file(dest, content)
      FileUtils.mkdir_p(File.dirname(dest))
      File.open(dest, 'w') do |f|
        f.write(content)
      end
    end

    def output_html(path, content)
      args = { remove_comments: true, compress_css: true, compress_javascript: true, preserve_patterns: [] }
      args[:css_compressor] = CSSminify2.new
      args[:javascript_compressor] = Uglifier.new

      opts = @site.config['jekyll-minifier']

      if ( !opts.nil? )
        # Convert keys to symboles
        opts.keys.each { |key| opts[(key.to_sym rescue key) || key] = opts.delete(key) }

        args[:remove_spaces_inside_tags]   = opts[:remove_spaces_inside_tags]  if opts.has_key?(:remove_spaces_inside_tags)
        args[:remove_multi_spaces]         = opts[:remove_multi_spaces]        if opts.has_key?(:remove_multi_spaces)
        args[:remove_comments]             = opts[:remove_comments]            if opts.has_key?(:remove_comments)
        args[:remove_intertag_spaces]      = opts[:remove_intertag_spaces]     if opts.has_key?(:remove_intertag_spaces)
        args[:remove_quotes]               = opts[:remove_quotes]              if opts.has_key?(:remove_quotes)
        args[:compress_css]                = opts[:compress_css]               if opts.has_key?(:compress_css)
        args[:compress_javascript]         = opts[:compress_javascript]        if opts.has_key?(:compress_javascript)
        args[:simple_doctype]              = opts[:simple_doctype]             if opts.has_key?(:simple_doctype)
        args[:remove_script_attributes]    = opts[:remove_script_attributes]   if opts.has_key?(:remove_script_attributes)
        args[:remove_style_attributes]     = opts[:remove_style_attributes]    if opts.has_key?(:remove_style_attributes)
        args[:remove_link_attributes]      = opts[:remove_link_attributes]     if opts.has_key?(:remove_link_attributes)
        args[:remove_form_attributes]      = opts[:remove_form_attributes]     if opts.has_key?(:remove_form_attributes)
        args[:remove_input_attributes]     = opts[:remove_input_attributes]    if opts.has_key?(:remove_input_attributes)
        args[:remove_javascript_protocol]  = opts[:remove_javascript_protocol] if opts.has_key?(:remove_javascript_protocol)
        args[:remove_http_protocol]        = opts[:remove_http_protocol]       if opts.has_key?(:remove_http_protocol)
        args[:remove_https_protocol]       = opts[:remove_https_protocol]      if opts.has_key?(:remove_https_protocol)
        args[:preserve_line_breaks]        = opts[:preserve_line_breaks]       if opts.has_key?(:preserve_line_breaks)
        args[:simple_boolean_attributes]   = opts[:simple_boolean_attributes]  if opts.has_key?(:simple_boolean_attributes)
        args[:compress_js_templates]       = opts[:compress_js_templates]      if opts.has_key?(:compress_js_templates)
        args[:preserve_patterns]          += [/<\?php.*?\?>/im]                if opts[:preserve_php] == true

        # Potential to add patterns from YAML
        #args[:preserve_patterns]          += opts[:preserve_patterns].map { |pattern| Regexp.new(pattern)} if opts.has_key?(:preserve_patterns)
      end

      compressor = HtmlCompressor::Compressor.new(args)
      output_file(path, compressor.compress(content))
    end

    def output_js(path, content)
      compressed = Uglifier.new
      output_file(path, compressed.compile(content))
    end

    def output_css(path, content)
      compressor = CSSminify2.new
      output_file(path, compressor.compress(content))
    end
  end

  class Document
    include Compressor

    def write(dest)
      dest_path = destination(dest)
      output_html(dest_path, output)
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
        output_html(dest_path, output)
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
            if dest_path =~ /.min.js$/
              copy_file(path, dest_path)
            else
              output_js(dest_path, File.read(path))
            end
          when '.css'
            if dest_path =~ /.min.css$/
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
