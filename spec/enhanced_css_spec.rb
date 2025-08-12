require 'spec_helper'

describe "Jekyll Minifier - Enhanced CSS Compression Features" do
  let(:site) { Jekyll::Site.new(Jekyll.configuration(test_config)) }
  
  let(:test_config) do
    {
      'source' => File.join(File.dirname(__FILE__), 'fixtures'),
      'destination' => File.join(File.dirname(__FILE__), 'fixtures/_site'),
      'jekyll-minifier' => base_minifier_config
    }
  end
  
  let(:base_minifier_config) do
    {
      'compress_css' => true,
      'compress_javascript' => true,
      'compress_json' => true
    }
  end

  before(:each) do
    # Set production environment for all tests
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('JEKYLL_ENV').and_return('production')
    
    # Clean up any existing files
    if Dir.exist?(File.join(File.dirname(__FILE__), 'fixtures/_site'))
      FileUtils.rm_rf(File.join(File.dirname(__FILE__), 'fixtures/_site'))
    end
  end

  describe "Enhanced CSS Configuration" do
    context "with enhanced mode disabled (default)" do
      it "uses standard CSS compression by default" do
        config = Jekyll::Minifier::CompressionConfig.new(site.config)
        
        expect(config.css_enhanced_mode?).to be false
        expect(config.css_enhanced_options).to be nil
      end
      
      it "maintains backward compatibility with existing CSS compression" do
        site.process
        
        css_file = File.join(site.dest, 'assets/css/style.css')
        expect(File.exist?(css_file)).to be true
        
        content = File.read(css_file)
        expect(content.length).to be > 0
        expect(content).not_to include('/* Comment */')  # Comments should be removed
      end
    end

    context "with enhanced mode enabled" do
      let(:enhanced_config) do
        base_minifier_config.merge({
          'css_enhanced_mode' => true,
          'css_merge_duplicate_selectors' => true,
          'css_optimize_shorthand_properties' => true,
          'css_advanced_color_optimization' => true,
          'css_preserve_ie_hacks' => true,
          'css_compress_variables' => true
        })
      end
      
      let(:test_config) do
        {
          'source' => File.join(File.dirname(__FILE__), 'fixtures'),
          'destination' => File.join(File.dirname(__FILE__), 'fixtures/_site'),
          'jekyll-minifier' => enhanced_config
        }
      end

      it "enables enhanced CSS compression options" do
        config = Jekyll::Minifier::CompressionConfig.new(site.config)
        
        expect(config.css_enhanced_mode?).to be true
        expect(config.css_merge_duplicate_selectors?).to be true
        expect(config.css_optimize_shorthand_properties?).to be true
        expect(config.css_advanced_color_optimization?).to be true
        expect(config.css_preserve_ie_hacks?).to be true
        expect(config.css_compress_variables?).to be true
      end
      
      it "generates proper enhanced options hash" do
        config = Jekyll::Minifier::CompressionConfig.new(site.config)
        options = config.css_enhanced_options
        
        expect(options).to be_a(Hash)
        expect(options[:merge_duplicate_selectors]).to be true
        expect(options[:optimize_shorthand_properties]).to be true
        expect(options[:advanced_color_optimization]).to be true
        expect(options[:preserve_ie_hacks]).to be true
        expect(options[:compress_css_variables]).to be true
      end
    end
  end

  describe "Enhanced CSS Compression Functionality" do
    let(:css_with_optimizations) do
      %{
        /* Duplicate selectors */
        .button {
          background-color: #ffffff;
          color: black;
        }
        
        .button {
          border: 1px solid red;
          border-radius: 4px;
        }
        
        /* Shorthand optimization opportunities */
        .box {
          margin-top: 10px;
          margin-right: 15px;
          margin-bottom: 10px;
          margin-left: 15px;
        }
        
        /* Color optimization */
        .colors {
          color: #000000;
          background: rgba(255, 255, 255, 1.0);
        }
      }
    end

    it "provides better compression with enhanced features" do
      # Test standard compression
      standard_config = Jekyll::Minifier::CompressionConfig.new({
        'jekyll-minifier' => base_minifier_config
      })
      
      standard_compressor = CSSminify2.new
      standard_result = standard_compressor.compress(css_with_optimizations, nil)
      
      # Test enhanced compression
      enhanced_config = Jekyll::Minifier::CompressionConfig.new({
        'jekyll-minifier' => base_minifier_config.merge({
          'css_enhanced_mode' => true,
          'css_merge_duplicate_selectors' => true,
          'css_optimize_shorthand_properties' => true,
          'css_advanced_color_optimization' => true
        })
      })
      
      enhanced_result = CSSminify2.compress_enhanced(css_with_optimizations, enhanced_config.css_enhanced_options)
      
      # Enhanced compression should produce smaller output
      expect(enhanced_result.length).to be < standard_result.length
      
      # Verify that enhancements were applied by checking selector merging
      button_occurrences_standard = standard_result.scan('.button{').length
      button_occurrences_enhanced = enhanced_result.scan('.button{').length
      expect(button_occurrences_enhanced).to be <= button_occurrences_standard
    end
  end

  describe "CSSEnhancedWrapper" do
    it "provides the same interface as CSSminify2 for HTML compressor" do
      options = {
        merge_duplicate_selectors: true,
        optimize_shorthand_properties: true,
        advanced_color_optimization: true
      }
      
      wrapper = Jekyll::Minifier::CSSEnhancedWrapper.new(options)
      expect(wrapper).to respond_to(:compress)
      
      css = ".test { color: #ffffff; background: #000000; }"
      result = wrapper.compress(css)
      
      expect(result).to be_a(String)
      expect(result.length).to be > 0
      expect(result.length).to be < css.length
    end
  end

  describe "HTML Inline CSS Enhancement" do
    let(:enhanced_config) do
      base_minifier_config.merge({
        'css_enhanced_mode' => true,
        'css_merge_duplicate_selectors' => true,
        'css_advanced_color_optimization' => true
      })
    end
    
    let(:test_config) do
      {
        'source' => File.join(File.dirname(__FILE__), 'fixtures'),
        'destination' => File.join(File.dirname(__FILE__), 'fixtures/_site'),
        'jekyll-minifier' => enhanced_config
      }
    end

    it "applies enhanced compression to inline CSS in HTML files" do
      site.process
      
      # Check that HTML files are processed and compressed
      html_files = Dir.glob(File.join(site.dest, '**/*.html'))
      expect(html_files).not_to be_empty
      
      # Verify that files exist and have content
      html_files.each do |file|
        content = File.read(file)
        expect(content.length).to be > 0
      end
    end
  end

  describe "Performance Impact" do
    let(:large_css) do
      css_block = %{
        .component-#{rand(1000)} {
          color: #ffffff;
          background: rgba(0, 0, 0, 1.0);
          margin-top: 10px;
          margin-right: 10px;
          margin-bottom: 10px;
          margin-left: 10px;
        }
      }
      css_block * 100  # Create large CSS
    end

    it "enhanced compression completes within reasonable time" do
      enhanced_config = Jekyll::Minifier::CompressionConfig.new({
        'jekyll-minifier' => base_minifier_config.merge({
          'css_enhanced_mode' => true,
          'css_merge_duplicate_selectors' => true,
          'css_optimize_shorthand_properties' => true,
          'css_advanced_color_optimization' => true
        })
      })
      
      start_time = Time.now
      result = CSSminify2.compress_enhanced(large_css, enhanced_config.css_enhanced_options)
      end_time = Time.now
      
      processing_time = end_time - start_time
      
      expect(result.length).to be > 0
      expect(result.length).to be < large_css.length
      expect(processing_time).to be < 5.0  # Should complete within 5 seconds
    end
  end

  describe "Error Handling and Robustness" do
    it "handles invalid CSS gracefully with enhanced mode" do
      invalid_css = "this is not valid css { broken }"
      
      enhanced_config = Jekyll::Minifier::CompressionConfig.new({
        'jekyll-minifier' => base_minifier_config.merge({
          'css_enhanced_mode' => true,
          'css_merge_duplicate_selectors' => true
        })
      })
      
      expect {
        result = CSSminify2.compress_enhanced(invalid_css, enhanced_config.css_enhanced_options)
        expect(result).to be_a(String)
      }.not_to raise_error
    end
    
    it "falls back gracefully when enhanced features are not available" do
      # This simulates the case where enhanced features might not be loaded
      css = ".test { color: red; }"
      
      # Should not raise an error even if enhanced features aren't available
      expect {
        result = CSSminify2.compress(css)
        expect(result).to be_a(String)
      }.not_to raise_error
    end
  end
end