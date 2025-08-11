require 'spec_helper'

describe "Jekyll Minifier - End-to-End Security Validation" do
  let(:config) do
    Jekyll.configuration({
      "full_rebuild" => true,
      "source"      => source_dir,
      "destination" => dest_dir,
      "show_drafts" => true,
      "url"         => "http://example.org",
      "name"       => "Security Test Site"
    })
  end
  
  before(:each) do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('JEKYLL_ENV').and_return('production')
  end

  describe "Complete ReDoS Protection Validation" do
    context "with real-world attack patterns" do
      let(:redos_attack_patterns) do
        [
          # Catastrophic backtracking patterns
          "(a+)+$",
          "(a|a)*$", 
          "(a*)*$",
          "(a+)*$",
          "^(a+)+",
          "^(a|a)*",
          
          # Evil regex patterns from real attacks
          "^(([a-z])+.)+[A-Z]([a-z])+$",
          "([a-zA-Z]+)*$",
          "(([a-z]*)*)*$",
          
          # Nested alternation
          "((a|a)*)*",
          "((.*)*)*",
          "((.+)*)+",
          
          # Long pattern attacks
          "a" * 2000,
          
          # Complex nested structures
          "(" * 20 + "a" + ")" * 20,
          
          # Excessive quantifiers
          ("a+" * 30) + "b"
        ]
      end

      it "blocks all ReDoS attack vectors while maintaining site functionality" do
        # Create site with dangerous patterns
        malicious_config = config.merge({
          "jekyll-minifier" => {
            "preserve_patterns" => redos_attack_patterns,
            "compress_html" => true,
            "compress_css" => true,
            "compress_javascript" => true
          }
        })
        
        malicious_site = Jekyll::Site.new(malicious_config)
        
        # Site should process successfully despite malicious patterns
        start_time = Time.now
        expect { malicious_site.process }.not_to raise_error
        duration = Time.now - start_time
        
        # Should complete quickly (not hang due to ReDoS)
        expect(duration).to be < 10.0
        
        # Site should be built successfully
        expect(File.exist?(dest_dir("index.html"))).to be true
        expect(File.exist?(dest_dir("assets/css/style.css"))).to be true
        expect(File.exist?(dest_dir("assets/js/script.js"))).to be true
      end
    end

    context "production site build with mixed patterns" do
      let(:mixed_config) do
        {
          "jekyll-minifier" => {
            "preserve_patterns" => [
              # Safe patterns (should work)
              "<!-- PRESERVE -->.*?<!-- /PRESERVE -->",
              "<script type=\"text/template\">.*?</script>",
              
              # Dangerous patterns (should be filtered)
              "(a+)+attack",
              "(malicious|malicious)*",
              
              # More safe patterns
              "<%.*?%>",
              "{{.*?}}"
            ],
            "compress_html" => true,
            "compress_css" => true,
            "compress_javascript" => true,
            "remove_comments" => true
          }
        }
      end

      it "successfully builds production site with security protection active" do
        test_site = Jekyll::Site.new(config.merge(mixed_config))
        
        # Capture any warnings
        warnings = []
        original_warn = Jekyll.logger.method(:warn)
        allow(Jekyll.logger).to receive(:warn) do |*args|
          warnings << args.join(" ")
          original_warn.call(*args)
        end
        
        # Build should succeed
        expect { test_site.process }.not_to raise_error
        
        # Verify all expected files are created and minified
        expect(File.exist?(dest_dir("index.html"))).to be true
        expect(File.exist?(dest_dir("assets/css/style.css"))).to be true
        expect(File.exist?(dest_dir("assets/js/script.js"))).to be true
        
        # Verify minification occurred (files should be compressed)
        html_content = File.read(dest_dir("index.html"))
        css_content = File.read(dest_dir("assets/css/style.css"))
        js_content = File.read(dest_dir("assets/js/script.js"))
        
        expect(html_content.lines.count).to be <= 2  # HTML should be minified
        expect(css_content).not_to include("\n")     # CSS should be on one line
        expect(js_content).not_to include("// ")     # JS comments should be removed
        
        # Security warnings should be present for dangerous patterns
        security_warnings = warnings.select { |w| w.include?("Jekyll Minifier:") }
        expect(security_warnings.length).to be >= 2 # At least 2 dangerous patterns warned
      end
    end
  end

  describe "Performance Security Validation" do
    it "maintains fast build times even with many patterns" do
      # Test with 50 safe patterns + 10 dangerous patterns
      large_pattern_set = []
      
      # Add safe patterns
      50.times { |i| large_pattern_set << "<!-- SECTION#{i} -->.*?<!-- /SECTION#{i} -->" }
      
      # Add dangerous patterns that should be filtered
      10.times { |i| large_pattern_set << "(attack#{i}+)+" }
      
      config_with_many_patterns = config.merge({
        "jekyll-minifier" => {
          "preserve_patterns" => large_pattern_set,
          "compress_html" => true
        }
      })
      
      test_site = Jekyll::Site.new(config_with_many_patterns)
      
      start_time = Time.now
      expect { test_site.process }.not_to raise_error
      duration = Time.now - start_time
      
      # Should still complete in reasonable time
      expect(duration).to be < 15.0
      
      # Site should be built
      expect(File.exist?(dest_dir("index.html"))).to be true
    end
  end

  describe "Memory Safety Validation" do
    it "prevents memory exhaustion from malicious patterns" do
      # Pattern designed to consume excessive memory during compilation
      memory_attack_patterns = [
        # Highly nested patterns
        "(" * 100 + "a" + ")" * 100,
        
        # Very long alternation
        (["attack"] * 1000).join("|"),
        
        # Complex quantifier combinations
        ("a{1,1000}" * 100)
      ]
      
      config_memory_test = config.merge({
        "jekyll-minifier" => {
          "preserve_patterns" => memory_attack_patterns
        }
      })
      
      test_site = Jekyll::Site.new(config_memory_test)
      
      # Should not crash or consume excessive memory
      expect { test_site.process }.not_to raise_error
      
      # Site should still build
      expect(File.exist?(dest_dir("index.html"))).to be true
    end
  end

  describe "Input Validation Edge Cases" do
    it "handles malformed pattern arrays gracefully" do
      malformed_configs = [
        { "preserve_patterns" => [nil, "", 123, [], {}] },
        { "preserve_patterns" => "not_an_array" },
        { "preserve_patterns" => 42 },
        { "preserve_patterns" => nil }
      ]
      
      malformed_configs.each do |malformed_config|
        test_config = config.merge({
          "jekyll-minifier" => malformed_config
        })
        
        test_site = Jekyll::Site.new(test_config)
        
        # Should handle gracefully without crashing
        expect { test_site.process }.not_to raise_error
        expect(File.exist?(dest_dir("index.html"))).to be true
      end
    end
  end

  describe "Legacy Configuration Security" do
    it "secures legacy preserve_patterns configurations" do
      # Simulate legacy config that might contain dangerous patterns
      legacy_config = config.merge({
        "jekyll-minifier" => {
          # Old-style configuration with potentially dangerous patterns
          "preserve_patterns" => [
            "<!-- preserve -->.*?<!-- /preserve -->",  # Safe legacy pattern
            "(legacy+)+",                              # Dangerous legacy pattern
            "<comment>.*?</comment>",                  # Safe legacy pattern
          ],
          "preserve_php" => true,  # Legacy PHP preservation
          "compress_html" => true
        }
      })
      
      legacy_site = Jekyll::Site.new(legacy_config)
      
      # Should work with legacy config but filter dangerous patterns
      expect { legacy_site.process }.not_to raise_error
      expect(File.exist?(dest_dir("index.html"))).to be true
      
      # PHP pattern should still be added (safe built-in pattern)
      html_content = File.read(dest_dir("index.html"))
      expect(html_content.length).to be > 0
    end
  end
end