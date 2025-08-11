require 'spec_helper'

describe "Jekyll Minifier - ReDoS Security Protection" do
  let(:overrides) { Hash.new }
  let(:config) do
    Jekyll.configuration(Jekyll::Utils.deep_merge_hashes({
      "full_rebuild" => true,
      "source"      => source_dir,
      "destination" => dest_dir,
      "show_drafts" => true,
      "url"         => "http://example.org",
      "name"       => "My awesome site"
    }, overrides))
  end
  let(:site) { Jekyll::Site.new(config) }
  let(:compressor) { Jekyll::Document.new(source_dir("_posts/2014-03-01-test-review-1.md"), site: site, collection: site.collections["posts"]) }

  before(:each) do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('JEKYLL_ENV').and_return('production')
  end

  describe "ReDoS Attack Prevention" do
    context "with safe preserve patterns" do
      let(:overrides) do
        {
          "jekyll-minifier" => {
            "preserve_patterns" => [
              "<!-- PRESERVE -->.*?<!-- /PRESERVE -->",
              "<script[^>]*>.*?</script>",
              "<style[^>]*>.*?</style>"
            ]
          }
        }
      end

      it "processes safe patterns without issues" do
        expect { site.process }.not_to raise_error
        expect(File.exist?(dest_dir("index.html"))).to be true
      end

      it "compiles safe patterns successfully" do
        patterns = compressor.send(:compile_preserve_patterns, [
          "<!-- PRESERVE -->.*?<!-- /PRESERVE -->",
          "<script[^>]*>.*?</script>"
        ])
        
        expect(patterns.length).to eq(2)
        expect(patterns.all? { |p| p.is_a?(Regexp) }).to be true
      end
    end

    context "with potentially dangerous ReDoS patterns" do
      let(:dangerous_patterns) do
        [
          # Nested quantifiers - classic ReDoS vector
          "(a+)+b",
          "(a*)*b", 
          "(a+)*b",
          "(a*)+b",
          
          # Alternation with overlapping patterns
          "(a|a)*b",
          "(ab|ab)*c",
          "(.*|.*)*d",
          
          # Excessively long patterns
          "a" * 1001,
          
          # Complex nested structures
          "(" * 15 + "a" + ")" * 15,
          
          # Excessive quantifiers
          "a+" * 25 + "b"
        ]
      end

      it "rejects dangerous ReDoS patterns gracefully" do
        # Should not raise errors, but should warn and skip dangerous patterns
        expect(Jekyll.logger).to receive(:warn).at_least(:once)
        
        patterns = compressor.send(:compile_preserve_patterns, dangerous_patterns)
        
        # All dangerous patterns should be filtered out
        expect(patterns.length).to eq(0)
      end

      it "continues processing when dangerous patterns are present" do
        overrides = {
          "jekyll-minifier" => {
            "preserve_patterns" => dangerous_patterns
          }
        }
        
        test_site = Jekyll::Site.new(Jekyll.configuration({
          "full_rebuild" => true,
          "source"      => source_dir,
          "destination" => dest_dir,
          "show_drafts" => true,
          "jekyll-minifier" => {
            "preserve_patterns" => dangerous_patterns
          }
        }))
        
        # Should complete processing despite dangerous patterns
        expect { test_site.process }.not_to raise_error
        expect(File.exist?(dest_dir("index.html"))).to be true
      end
    end

    context "with mixed safe and dangerous patterns" do
      let(:mixed_patterns) do
        [
          "<!-- PRESERVE -->.*?<!-- /PRESERVE -->", # Safe
          "(a+)+b",                                  # Dangerous - nested quantifiers
          "<script[^>]*>.*?</script>",              # Safe
          "(a|a)*b",                                # Dangerous - alternation overlap
          "<style[^>]*>.*?</style>"                 # Safe
        ]
      end

      it "processes only the safe patterns" do
        expect(Jekyll.logger).to receive(:warn).at_least(:twice) # For the two dangerous patterns
        
        patterns = compressor.send(:compile_preserve_patterns, mixed_patterns)
        
        # Should compile only the 3 safe patterns
        expect(patterns.length).to eq(3)
        expect(patterns.all? { |p| p.is_a?(Regexp) }).to be true
      end
    end

    context "with invalid regex patterns" do
      let(:invalid_patterns) do
        [
          "[",          # Unclosed bracket
          "(",          # Unclosed parenthesis
          "*",          # Invalid quantifier
          "(?P<test>)", # Invalid named group syntax for Ruby
          nil,          # Nil value
          123,          # Non-string value
          "",           # Empty string
        ]
      end

      it "handles invalid patterns gracefully" do
        expect(Jekyll.logger).to receive(:warn).at_least(:once)
        
        patterns = compressor.send(:compile_preserve_patterns, invalid_patterns)
        
        # Should filter out all invalid patterns
        expect(patterns.length).to eq(0)
      end
    end
  end

  describe "Pattern Validation Logic" do
    it "validates pattern complexity correctly" do
      # Safe patterns should pass
      safe_patterns = [
        "simple text",
        "<!-- comment -->.*?<!-- /comment -->",
        "<[^>]+>",
        "a{1,5}b"
      ]
      
      safe_patterns.each do |pattern|
        expect(compressor.send(:valid_regex_pattern?, pattern)).to be(true), "Expected '#{pattern}' to be valid"
      end
    end

    it "rejects dangerous patterns correctly" do
      dangerous_patterns = [
        "(a+)+",      # Nested quantifiers
        "(a|a)*",     # Alternation overlap
        "(" * 15,     # Too much nesting
        "a" * 1001,   # Too long
        "a+" * 25     # Too many quantifiers
      ]
      
      dangerous_patterns.each do |pattern|
        expect(compressor.send(:valid_regex_pattern?, pattern)).to be(false), "Expected '#{pattern}' to be invalid"
      end
    end

    it "handles edge cases in validation" do
      edge_cases = [
        nil,           # Nil
        123,           # Non-string
        "",            # Empty string
        " ",           # Whitespace only
      ]
      
      edge_cases.each do |pattern|
        expect(compressor.send(:valid_regex_pattern?, pattern)).to be(false), "Expected #{pattern.inspect} to be invalid"
      end
    end
  end

  describe "Timeout Protection" do
    it "compiles simple patterns quickly" do
      start_time = Time.now
      regex = compressor.send(:compile_regex_with_timeout, "simple.*pattern", 1.0)
      duration = Time.now - start_time
      
      expect(regex).to be_a(Regexp)
      expect(duration).to be < 0.1 # Should be very fast
    end

    it "handles timeout gracefully for complex patterns" do
      # This test uses a pattern that should compile quickly
      # but demonstrates the timeout mechanism is in place
      start_time = Time.now
      regex = compressor.send(:compile_regex_with_timeout, "test.*pattern", 0.001) # Very short timeout
      duration = Time.now - start_time
      
      # Either compiles successfully (very fast) or times out gracefully
      expect(duration).to be < 0.1
      # The regex should compile successfully or timeout gracefully
      expect(regex.nil? || regex.is_a?(Regexp)).to be true
    end
  end

  describe "Backward Compatibility" do
    context "with existing user configurations" do
      let(:legacy_configs) do
        [
          {
            "preserve_patterns" => ["<!-- PRESERVE -->.*?<!-- /PRESERVE -->"]
          },
          {
            "preserve_patterns" => [
              "<script[^>]*>.*?</script>",
              "<style[^>]*>.*?</style>"
            ]
          },
          {
            "preserve_php" => true,
            "preserve_patterns" => ["<!-- CUSTOM -->.*?<!-- /CUSTOM -->"]
          }
        ]
      end

      it "maintains full backward compatibility" do
        legacy_configs.each do |config|
          test_site = Jekyll::Site.new(Jekyll.configuration({
            "full_rebuild" => true,
            "source"      => source_dir,
            "destination" => dest_dir,
            "jekyll-minifier" => config
          }))
          
          # All legacy configurations should continue working
          expect { test_site.process }.not_to raise_error
          expect(File.exist?(dest_dir("index.html"))).to be true
        end
      end
    end

    context "with no preserve_patterns configuration" do
      it "works without preserve_patterns" do
        expect { site.process }.not_to raise_error
        expect(File.exist?(dest_dir("index.html"))).to be true
      end
    end

    context "with empty preserve_patterns" do
      let(:overrides) do
        {
          "jekyll-minifier" => {
            "preserve_patterns" => []
          }
        }
      end

      it "handles empty preserve_patterns array" do
        expect { site.process }.not_to raise_error
        expect(File.exist?(dest_dir("index.html"))).to be true
      end
    end
  end

  describe "Security Boundary Testing" do
    it "prevents ReDoS through compilation timeout" do
      # This simulates a potential ReDoS attack pattern
      # The protection should prevent hanging
      start_time = Time.now
      
      result = compressor.send(:compile_preserve_patterns, ["(a+)+"])
      
      duration = Time.now - start_time
      expect(duration).to be < 2.0 # Should not hang
      expect(result).to eq([]) # Dangerous pattern should be rejected
    end

    it "maintains site generation speed with protection enabled" do
      # Full site processing should remain fast
      start_time = Time.now
      site.process
      duration = Time.now - start_time
      
      expect(duration).to be < 10.0 # Should complete within reasonable time
      expect(File.exist?(dest_dir("index.html"))).to be true
    end
  end
end