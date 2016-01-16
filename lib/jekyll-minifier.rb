require 'yui/compressor'
require 'htmlcompressor'

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
      compressor = HtmlCompressor::Compressor.new({ :compress_css => true, :compress_javascript => true, :css_compressor => :yui, :javascript_compressor => :yui })
      output_file(path, compressor.compress(content))
    end

    def output_js(path, content)
      compressor = YUI::JavaScriptCompressor.new({ :munge => true, :preserve_semicolons => true, :optimize => true, :line_break => nil })
      output_file(path, compressor.compress(content))
    rescue compressor::ParseError => e
      warn "Warning: parse error in #{path}. Don't panic - copying initial file"
      warn "Details: #{e.message.strip}"
      output_file(path, content)
    end

    def output_css(path, content)
      compressor = YUI::CssCompressor.new({ :line_break =>  -1 })
      output_file(path, compressor.compress(content))
    rescue compressor::RuntimeError => e
      warn "Warning: parse error in #{path}. Don't panic - copying initial file"
      warn "Details: #{e.message.strip}"
      output_file(path, content)
    end
  end

  class Document
    include Compressor

    def write(dest)
      dest_path = destination(dest)
      output_html(dest_path, output)
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
      @@mtimes[path] = mtime

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
