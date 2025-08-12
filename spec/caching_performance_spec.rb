require 'spec_helper'
require 'benchmark'

describe "Jekyll::Minifier Caching Performance" do
  let(:config) { Jekyll::Minifier::CompressionConfig.new({}) }
  let(:factory) { Jekyll::Minifier::CompressorFactory }
  let(:cache) { Jekyll::Minifier::CompressorCache }

  before(:each) do
    cache.clear_all
  end

  after(:all) do
    Jekyll::Minifier::CompressorCache.clear_all
  end

  describe "compressor creation performance" do
    it "demonstrates significant performance improvement with caching" do
      iterations = 50
      
      # Benchmark without caching (clear cache each time)
      time_without_caching = Benchmark.realtime do
        iterations.times do
          cache.clear_all
          factory.create_css_compressor(config)
          factory.create_js_compressor(config)
          factory.create_html_compressor(config)
        end
      end
      
      # Benchmark with caching
      cache.clear_all
      time_with_caching = Benchmark.realtime do
        iterations.times do
          factory.create_css_compressor(config)
          factory.create_js_compressor(config)
          factory.create_html_compressor(config)
        end
      end
      
      puts "\nCaching Performance Results:"
      puts "Without caching: #{(time_without_caching * 1000).round(2)}ms (#{(time_without_caching * 1000 / iterations).round(2)}ms per iteration)"
      puts "With caching: #{(time_with_caching * 1000).round(2)}ms (#{(time_with_caching * 1000 / iterations).round(2)}ms per iteration)"
      
      improvement_ratio = time_without_caching / time_with_caching
      puts "Performance improvement: #{improvement_ratio.round(2)}x faster"
      
      # Cache should show high hit ratio
      stats = cache.stats
      puts "Cache hit ratio: #{(cache.hit_ratio * 100).round(1)}%"
      puts "Cache statistics: #{stats}"
      
      # Verify significant performance improvement
      expect(improvement_ratio).to be > 2.0, "Caching should provide at least 2x performance improvement"
      expect(cache.hit_ratio).to be > 0.8, "Cache hit ratio should be above 80%"
    end

    it "shows memory efficiency with reasonable cache size" do
      # Create many different configurations
      20.times do |i|
        test_config = Jekyll::Minifier::CompressionConfig.new({
          'jekyll-minifier' => { 
            'terser_args' => { 'compress' => (i % 2 == 0), 'mangle' => (i % 3 == 0) }
          }
        })
        
        factory.create_css_compressor(test_config)
        factory.create_js_compressor(test_config)
        factory.create_html_compressor(test_config)
      end
      
      sizes = cache.cache_sizes
      puts "\nMemory Efficiency Results:"
      puts "Cache sizes: #{sizes}"
      
      # Verify cache size limits are respected
      expect(sizes[:css]).to be <= Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE
      expect(sizes[:js]).to be <= Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE
      expect(sizes[:html]).to be <= Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE
      expect(sizes[:total]).to be <= Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE * 3
    end

    it "demonstrates compression performance with cached compressors" do
      css_content = "body { color: red; background-color: blue; margin: 10px; padding: 5px; }"
      js_content = "function test() { var message = 'hello world'; console.log(message); return message; }"
      html_content = "<html><head><title>Test</title></head><body><h1>Test</h1><p>Content</p></body></html>"
      
      iterations = 30
      
      # Benchmark compression performance with fresh compressors
      cache.clear_all
      time_without_cache = Benchmark.realtime do
        iterations.times do
          cache.clear_all
          factory.compress_css(css_content, config, "test.css")
          factory.compress_js(js_content, config, "test.js")
        end
      end
      
      # Benchmark compression performance with cached compressors
      cache.clear_all
      time_with_cache = Benchmark.realtime do
        iterations.times do
          factory.compress_css(css_content, config, "test.css")
          factory.compress_js(js_content, config, "test.js")
        end
      end
      
      puts "\nCompression Performance Results:"
      puts "Without cache: #{(time_without_cache * 1000).round(2)}ms"
      puts "With cache: #{(time_with_cache * 1000).round(2)}ms"
      
      improvement_ratio = time_without_cache / time_with_cache
      puts "Compression improvement: #{improvement_ratio.round(2)}x faster"
      
      # Verify compression performance improvement
      expect(improvement_ratio).to be > 1.5, "Caching should improve compression performance by at least 50%"
    end

    it "maintains thread safety under concurrent load" do
      threads = []
      errors = []
      iterations_per_thread = 10
      thread_count = 5
      
      cache.clear_all
      
      # Create multiple threads performing compression
      thread_count.times do |t|
        threads << Thread.new do
          begin
            iterations_per_thread.times do |i|
              config_data = {
                'jekyll-minifier' => { 
                  'terser_args' => { 'compress' => ((t + i) % 2 == 0) }
                }
              }
              test_config = Jekyll::Minifier::CompressionConfig.new(config_data)
              
              compressor = factory.create_js_compressor(test_config)
              result = compressor.compile("function test() { return true; }")
              
              Thread.current[:results] = (Thread.current[:results] || []) << result
            end
          rescue => e
            errors << e
          end
        end
      end
      
      # Wait for completion
      threads.each(&:join)
      
      # Verify no errors occurred
      expect(errors).to be_empty, "No thread safety errors should occur: #{errors.inspect}"
      
      # Verify all threads got results
      total_results = threads.sum { |t| (t[:results] || []).length }
      expect(total_results).to eq(thread_count * iterations_per_thread)
      
      puts "\nThread Safety Results:"
      puts "Threads: #{thread_count}, Iterations per thread: #{iterations_per_thread}"
      puts "Total operations: #{total_results}"
      puts "Errors: #{errors.length}"
      puts "Final cache stats: #{cache.stats}"
    end
  end

  describe "cache behavior validation" do
    it "properly limits cache size and demonstrates eviction capability" do
      max_size = Jekyll::Minifier::CompressorCache::MAX_CACHE_SIZE
      
      # Test cache size limiting by creating configurations we know will be different
      # Use direct cache interface to verify behavior
      test_objects = []
      (1..(max_size + 3)).each do |i|
        cache_key = "test_key_#{i}"
        obj = cache.get_or_create(:css, cache_key) { "test_object_#{i}" }
        test_objects << obj
      end
      
      puts "\nDirect Cache Test Results:"
      puts "Created #{test_objects.length} objects"
      puts "Cache sizes: #{cache.cache_sizes}"
      puts "Cache stats: #{cache.stats}"
      
      # Verify cache respects size limits
      expect(cache.cache_sizes[:css]).to eq(max_size)
      expect(cache.stats[:evictions]).to be > 0
      expect(test_objects.length).to eq(max_size + 3)
      
      # Test that early entries were evicted
      first_key_result = cache.get_or_create(:css, "test_key_1") { "recreated_object_1" }
      expect(first_key_result).to eq("recreated_object_1") # Should be recreated, not cached
      
      puts "LRU Eviction confirmed: first entry was evicted and recreated"
    end

    it "correctly identifies cache hits vs misses" do
      config1 = Jekyll::Minifier::CompressionConfig.new({
        'jekyll-minifier' => { 'terser_args' => { 'compress' => true } }
      })
      config2 = Jekyll::Minifier::CompressionConfig.new({
        'jekyll-minifier' => { 'terser_args' => { 'compress' => false } }
      })
      
      cache.clear_all
      
      # First access - should be miss
      factory.create_js_compressor(config1)
      stats1 = cache.stats
      
      # Second access same config - should be hit
      factory.create_js_compressor(config1)
      stats2 = cache.stats
      
      # Third access different config - should be miss
      factory.create_js_compressor(config2)
      stats3 = cache.stats
      
      # Fourth access first config - should be hit
      factory.create_js_compressor(config1)
      stats4 = cache.stats
      
      puts "\nCache Hit/Miss Tracking:"
      puts "After 1st call (config1): hits=#{stats1[:hits]}, misses=#{stats1[:misses]}"
      puts "After 2nd call (config1): hits=#{stats2[:hits]}, misses=#{stats2[:misses]}"
      puts "After 3rd call (config2): hits=#{stats3[:hits]}, misses=#{stats3[:misses]}"
      puts "After 4th call (config1): hits=#{stats4[:hits]}, misses=#{stats4[:misses]}"
      
      expect(stats1[:misses]).to eq(1)
      expect(stats1[:hits]).to eq(0)
      expect(stats2[:hits]).to eq(1)
      expect(stats3[:misses]).to eq(2)
      expect(stats4[:hits]).to eq(2)
    end
  end
end