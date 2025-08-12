require 'spec_helper'

describe "Jekyll::Minifier::CompressorCache" do
  let(:cache) { Jekyll::Minifier::CompressorCache }

  before(:each) do
    # Clear cache before each test
    cache.clear_all
  end

  after(:all) do
    # Clean up after all tests
    Jekyll::Minifier::CompressorCache.clear_all
  end

  describe "cache key generation" do
    it "generates consistent keys for identical configurations" do
      config1 = { terser_args: { compress: true, mangle: false } }
      config2 = { terser_args: { compress: true, mangle: false } }
      
      key1 = cache.generate_cache_key(config1)
      key2 = cache.generate_cache_key(config2)
      
      expect(key1).to eq(key2)
      expect(key1).to be_a(String)
      expect(key1.length).to eq(17) # SHA256 truncated to 16 chars + null terminator handling
    end

    it "generates different keys for different configurations" do
      config1 = { terser_args: { compress: true, mangle: false } }
      config2 = { terser_args: { compress: false, mangle: true } }
      
      key1 = cache.generate_cache_key(config1)
      key2 = cache.generate_cache_key(config2)
      
      expect(key1).not_to eq(key2)
    end

    it "handles nil and empty configurations" do
      expect(cache.generate_cache_key(nil)).to eq('default')
      expect(cache.generate_cache_key({})).to eq('default')
    end
  end

  describe "caching functionality" do
    it "caches and retrieves compressor objects" do
      call_count = 0
      
      # First call should create new object
      obj1 = cache.get_or_create(:js, "test_key") do
        call_count += 1
        "mock_compressor_#{call_count}"
      end
      
      # Second call should retrieve cached object
      obj2 = cache.get_or_create(:js, "test_key") do
        call_count += 1
        "mock_compressor_#{call_count}"
      end
      
      expect(obj1).to eq(obj2)
      expect(call_count).to eq(1) # Factory block called only once
      expect(obj1).to eq("mock_compressor_1")
    end

    it "maintains separate caches for different types" do
      css_obj = cache.get_or_create(:css, "key1") { "css_compressor" }
      js_obj = cache.get_or_create(:js, "key1") { "js_compressor" }
      html_obj = cache.get_or_create(:html, "key1") { "html_compressor" }
      
      expect(css_obj).to eq("css_compressor")
      expect(js_obj).to eq("js_compressor")
      expect(html_obj).to eq("html_compressor")
      
      # Each should be independent
      expect(css_obj).not_to eq(js_obj)
      expect(js_obj).not_to eq(html_obj)
    end

    it "implements LRU eviction when cache is full" do
      # Fill cache to capacity
      (1..Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE).each do |i|
        cache.get_or_create(:js, "key_#{i}") { "compressor_#{i}" }
      end
      
      expect(cache.cache_sizes[:js]).to eq(Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE)
      
      # Add one more - should evict oldest
      cache.get_or_create(:js, "new_key") { "new_compressor" }
      
      expect(cache.cache_sizes[:js]).to eq(Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE)
      expect(cache.stats[:evictions]).to eq(1)
      
      # First key should be evicted
      call_count = 0
      cache.get_or_create(:js, "key_1") do
        call_count += 1
        "recreated_compressor"
      end
      
      expect(call_count).to eq(1) # Had to recreate
    end
  end

  describe "statistics tracking" do
    it "tracks cache hits and misses" do
      initial_stats = cache.stats
      expect(initial_stats[:hits]).to eq(0)
      expect(initial_stats[:misses]).to eq(0)
      
      # First access - should be miss
      cache.get_or_create(:css, "test") { "compressor" }
      stats_after_miss = cache.stats
      expect(stats_after_miss[:misses]).to eq(1)
      expect(stats_after_miss[:hits]).to eq(0)
      
      # Second access - should be hit
      cache.get_or_create(:css, "test") { "compressor" }
      stats_after_hit = cache.stats
      expect(stats_after_hit[:misses]).to eq(1)
      expect(stats_after_hit[:hits]).to eq(1)
    end

    it "calculates hit ratio correctly" do
      expect(cache.hit_ratio).to eq(0.0) # No operations yet
      
      # One miss
      cache.get_or_create(:css, "test1") { "comp1" }
      expect(cache.hit_ratio).to eq(0.0)
      
      # One hit
      cache.get_or_create(:css, "test1") { "comp1" }
      expect(cache.hit_ratio).to eq(0.5)
      
      # Another hit
      cache.get_or_create(:css, "test1") { "comp1" }
      expect(cache.hit_ratio).to be_within(0.01).of(0.67)
    end
  end

  describe "thread safety" do
    it "handles concurrent access safely" do
      threads = []
      results = {}
      
      # Create multiple threads accessing cache concurrently
      10.times do |i|
        threads << Thread.new do
          key = "concurrent_key_#{i % 3}" # Use some duplicate keys
          result = cache.get_or_create(:js, key) { "compressor_#{key}" }
          Thread.current[:result] = result
        end
      end
      
      # Wait for all threads to complete
      threads.each(&:join)
      
      # Collect results
      threads.each_with_index do |thread, i|
        results[i] = thread[:result]
      end
      
      # Verify no race conditions occurred
      expect(results.values.uniq.length).to eq(3) # Should have 3 unique compressors
      expect(cache.cache_sizes[:js]).to eq(3)
    end
  end

  describe "memory management" do
    it "limits cache size appropriately" do
      # Add more than max cache size
      (1..(Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE + 5)).each do |i|
        cache.get_or_create(:css, "key_#{i}") { "compressor_#{i}" }
      end
      
      sizes = cache.cache_sizes
      expect(sizes[:css]).to eq(Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE)
      expect(sizes[:js]).to eq(0)
      expect(sizes[:html]).to eq(0)
      expect(sizes[:total]).to eq(Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE)
    end

    it "clears all caches completely" do
      # Add some data to each cache
      cache.get_or_create(:css, "css_key") { "css_comp" }
      cache.get_or_create(:js, "js_key") { "js_comp" }
      cache.get_or_create(:html, "html_key") { "html_comp" }
      
      expect(cache.cache_sizes[:total]).to eq(3)
      
      cache.clear_all
      
      expect(cache.cache_sizes[:total]).to eq(0)
      expect(cache.stats[:hits]).to eq(0)
      expect(cache.stats[:misses]).to eq(0)
      expect(cache.stats[:evictions]).to eq(0)
    end
  end
end

describe "Jekyll::Minifier::CompressorFactory with Caching" do
  let(:config) { Jekyll::Minifier::CompressionConfig.new({}) }
  let(:factory) { Jekyll::Minifier::CompressorFactory }
  let(:cache) { Jekyll::Minifier::CompressorCache }

  before(:each) do
    cache.clear_all
  end

  after(:all) do
    Jekyll::Minifier::CompressorCache.clear_all
  end

  describe "CSS compressor caching" do
    it "caches CSS compressors based on configuration" do
      initial_stats = cache.stats
      
      # First call should create new compressor
      comp1 = factory.create_css_compressor(config)
      stats_after_first = cache.stats
      expect(stats_after_first[:misses]).to eq(initial_stats[:misses] + 1)
      
      # Second call with same config should return cached compressor
      comp2 = factory.create_css_compressor(config)
      stats_after_second = cache.stats
      expect(stats_after_second[:hits]).to eq(initial_stats[:hits] + 1)
      
      # Should be the same object
      expect(comp1).to be(comp2)
    end

    it "creates different compressors for different configurations" do
      config1 = Jekyll::Minifier::CompressionConfig.new({
        'jekyll-minifier' => { 'css_enhanced_mode' => false }
      })
      config2 = Jekyll::Minifier::CompressionConfig.new({
        'jekyll-minifier' => { 
          'css_enhanced_mode' => true,
          'css_merge_duplicate_selectors' => true
        }
      })
      
      comp1 = factory.create_css_compressor(config1)
      comp2 = factory.create_css_compressor(config2)
      
      # Should be different objects for different configurations
      expect(comp1).not_to be(comp2)
    end
  end

  describe "JavaScript compressor caching" do
    it "caches JS compressors based on Terser configuration" do
      initial_stats = cache.stats
      
      comp1 = factory.create_js_compressor(config)
      stats_after_first = cache.stats
      expect(stats_after_first[:misses]).to be > initial_stats[:misses]
      
      comp2 = factory.create_js_compressor(config)
      stats_after_second = cache.stats
      expect(stats_after_second[:hits]).to be > initial_stats[:hits]
      
      expect(comp1).to be(comp2)
    end

    it "creates different compressors for different Terser configurations" do
      config1 = Jekyll::Minifier::CompressionConfig.new({})
      config2 = Jekyll::Minifier::CompressionConfig.new({
        'jekyll-minifier' => { 
          'terser_args' => { 'compress' => false, 'mangle' => false }
        }
      })
      
      comp1 = factory.create_js_compressor(config1)
      comp2 = factory.create_js_compressor(config2)
      
      expect(comp1).not_to be(comp2)
    end
  end

  describe "HTML compressor caching" do
    it "caches HTML compressors based on full configuration" do
      initial_stats = cache.stats
      
      comp1 = factory.create_html_compressor(config)
      comp2 = factory.create_html_compressor(config)
      
      final_stats = cache.stats
      expect(final_stats[:hits]).to be > initial_stats[:hits]
      expect(comp1).to be(comp2)
    end
  end

  describe "integration with compression methods" do
    it "benefits from caching in CSS compression" do
      css_content = "body { color: red; background-color: blue; }"
      
      cache.clear_all
      initial_stats = cache.stats
      
      # First compression
      result1 = factory.compress_css(css_content, config, "test1.css")
      
      # Second compression
      result2 = factory.compress_css(css_content, config, "test2.css")
      
      final_stats = cache.stats
      expect(final_stats[:hits]).to be > initial_stats[:hits]
      expect(result1).to eq(result2) # Same compression result
    end

    it "benefits from caching in JS compression" do
      js_content = "function test() { return 'hello world'; }"
      
      cache.clear_all
      initial_stats = cache.stats
      
      result1 = factory.compress_js(js_content, config, "test1.js")
      result2 = factory.compress_js(js_content, config, "test2.js")
      
      final_stats = cache.stats
      expect(final_stats[:hits]).to be > initial_stats[:hits]
      expect(result1).to eq(result2)
    end
  end
end