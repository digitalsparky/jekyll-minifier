# jekyll-minifier [![Build Status](https://travis-ci.org/digitalsparky/jekyll-minifier.svg?branch=master)](https://travis-ci.org/digitalsparky/jekyll-minifier) [![Gem Version](https://badge.fury.io/rb/jekyll-minifier.svg)](http://badge.fury.io/rb/jekyll-minifier)

Minifies HTML, XML, CSS, and Javascript both inline and as separate files utilising yui-compressor and htmlcompressor.

This was created due to the previous minifier (jekyll-press) not being CSS3 compatible, which made me frown.

Note: this is my first ever gem, I'm learning, so feedback is much appreciated.

Easy to use, just install the jekyll-minifier gem:

<pre><code>gem install jekyll-minifier</code></pre>

Then add this to your _config.yml:

<pre><code>gems:
    - jekyll-minifier
</code></pre>

Optionally, you can also add exclusions using:
<pre><code>jekyll-minifier:
  exclude: 'atom.xml' # Exclude files from processing - file name, glob pattern or array of file names and glob patterns
</code></pre>
and toggle htmlcompressor features using:
<pre><code>jekyll-minifier:
  preserve_php: true                # Default: false
  remove_spaces_inside_tags: true   # Default: true
  remove_multi_spaces: true         # Default: true
  remove_comments: true             # Default: true
  remove_intertag_spaces: true      # Default: false
  remove_quotes: false              # Default: false
  compress_css: true                # Default: true
  compress_javascript: true         # Default: true
  simple_doctype: false             # Default: false
  remove_script_attributes: false   # Default: false
  remove_style_attributes: false    # Default: false
  remove_link_attributes: false     # Default: false
  remove_form_attributes: false     # Default: false
  remove_input_attributes: false    # Default: false
  remove_javascript_protocol: false # Default: false
  remove_http_protocol: false       # Default: false
  remove_https_protocol: false      # Default: false
  preserve_line_breaks: false       # Default: false
  simple_boolean_attributes: false  # Default: false
  compress_js_templates: false      # Default: false
</code></pre>

