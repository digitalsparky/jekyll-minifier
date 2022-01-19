# jekyll-minifier [![Build Status](https://travis-ci.org/digitalsparky/jekyll-minifier.svg?branch=master)](https://travis-ci.org/digitalsparky/jekyll-minifier) [![Gem Version](https://badge.fury.io/rb/jekyll-minifier.svg)](http://badge.fury.io/rb/jekyll-minifier)

Requires Ruby 2.3+

Minifies HTML, XML, CSS, JSON and JavaScript both inline and as separate files utilising yui-compressor and htmlcompressor.

This was created due to the previous minifier (jekyll-press) not being CSS3 compatible, which made me frown.

Note: this is my first ever gem, I'm learning, so feedback is much appreciated.

**This minifier now only runs when `JEKYLL_ENV="production"` is set in the environment **

Easy to use, just install the jekyll-minifier gem:

```
gem install jekyll-minifier
```

Then add this to your `_config.yml`:

```yaml
plugins:
  - jekyll-minifier
```  

Optionally, you can also add exclusions using:

```yaml
jekyll-minifier:
  exclude: 'atom.xml' # Exclude files from processing - file name, glob pattern or array of file names and glob patterns
```

and toggle features and settings using:

```yaml
jekyll-minifier:
  preserve_php: true                # Default: false
  remove_spaces_inside_tags: true   # Default: true
  remove_multi_spaces: true         # Default: true
  remove_comments: true             # Default: true
  remove_intertag_spaces: true      # Default: false
  remove_quotes: false              # Default: false
  compress_css: true                # Default: true
  compress_javascript: true         # Default: true
  compress_json: true               # Default: true
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
  preserve_patterns:                # Default: (empty)
  uglifier_args:                    # Default: (empty)
```

`js_args` can be found in the the uglifier documentation at listed below

Note: es6 has been implemented as experimental only via the upstream uglifier package.
See https://github.com/lautis/uglifier for more information.

To enable es6 syntax use:

```yaml
jekyll-minifier:
  uglifier_args:
    harmony: true
```


# Like my stuff?

Would you like to buy me a coffee or send me a tip?
While it's not expected, I would really appreciate it.

[![Paypal](https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png)](https://paypal.me/MattSpurrier) <a href="https://www.buymeacoffee.com/digitalsparky" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/white_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>
