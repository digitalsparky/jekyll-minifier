# jekyll-minifier [![Gem Version](https://badge.fury.io/rb/jekyll-minifier.svg)](http://badge.fury.io/rb/jekyll-minifier)

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

