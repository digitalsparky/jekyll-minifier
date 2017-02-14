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
      compressor = HtmlCompressor::Compressor.new({ :remove_comments => true, :compress_css => true, :compress_javascript => true, :css_compressor => CSSminify2.new, :javascript_compressor => Uglifier.new })
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
