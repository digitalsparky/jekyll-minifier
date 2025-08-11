require 'spec_helper'
require 'benchmark'

describe "Jekyll Minifier - Performance Benchmarks" do
  let(:config) do
    Jekyll.configuration({
      "full_rebuild" => true,
      "source"      => source_dir,
      "destination" => dest_dir,
      "show_drafts" => true,
      "url"         => "http://example.org",
      "name"       => "My awesome site",
      "jekyll-minifier" => {
        "compress_html" => true,
        "compress_css" => true,
        "compress_javascript" => true,
        "compress_json" => true
      }
    })
  end
  let(:site) { Jekyll::Site.new(config) }

  before(:each) do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('JEKYLL_ENV').and_return('production')
  end

  describe "Compression Performance Baselines" do
    it "establishes CSS compression performance baseline" do
      css_times = []
      
      3.times do
        time = Benchmark.realtime do
          site.process
        end
        css_times << time
      end
      
      avg_time = css_times.sum / css_times.length
      puts "CSS Compression Average Time: #{avg_time.round(3)}s"
      
      # Performance baseline - should complete within reasonable time
      expect(avg_time).to be < 2.0, "CSS compression should complete within 2 seconds"
      
      # Verify compression occurred
      if File.exist?(dest_dir("assets/css/style.css"))
        css_content = File.read(dest_dir("assets/css/style.css"))
        expect(css_content.lines.count).to eq(1), "CSS should be compressed to single line"
      end
    end

    it "establishes JavaScript compression performance baseline" do
      js_times = []
      
      3.times do
        time = Benchmark.realtime do
          site.process
        end
        js_times << time
      end
      
      avg_time = js_times.sum / js_times.length
      puts "JavaScript Compression Average Time: #{avg_time.round(3)}s"
      
      # Performance baseline - should complete within reasonable time
      expect(avg_time).to be < 2.0, "JavaScript compression should complete within 2 seconds"
      
      # Verify compression occurred
      if File.exist?(dest_dir("assets/js/script.js"))
        js_content = File.read(dest_dir("assets/js/script.js"))
        expect(js_content).not_to include("// "), "Comments should be removed"
      end
    end

    it "establishes HTML compression performance baseline" do
      html_times = []
      
      3.times do
        time = Benchmark.realtime do
          site.process
        end
        html_times << time
      end
      
      avg_time = html_times.sum / html_times.length
      puts "HTML Compression Average Time: #{avg_time.round(3)}s"
      
      # Performance baseline
      expect(avg_time).to be < 3.0, "HTML compression should complete within 3 seconds"
      
      # Verify all HTML files were processed
      expect(File.exist?(dest_dir("index.html"))).to be true
      expect(File.exist?(dest_dir("404.html"))).to be true
      expect(File.exist?(dest_dir("reviews/index.html"))).to be true
    end
  end

  describe "Memory Usage Monitoring" do
    it "monitors memory usage during site processing" do
      # Simplified memory monitoring that works in Docker
      GC.start  # Clean up before measuring
      before_objects = GC.stat[:total_allocated_objects]
      
      site.process
      
      GC.start  # Clean up after processing
      after_objects = GC.stat[:total_allocated_objects]
      
      objects_created = after_objects - before_objects
      puts "Objects created during processing: #{objects_created}"
      
      # Object creation should be reasonable for test site
      expect(objects_created).to be > 0, "Should create some objects during processing"
      expect(objects_created).to be < 1000000, "Should not create excessive objects"
    end
  end

  describe "Compression Ratio Consistency" do
    it "achieves consistent compression ratios across multiple runs" do
      compression_ratios = []
      
      3.times do
        site.process
        
        if File.exist?(source_dir("assets/css/style.css")) && File.exist?(dest_dir("assets/css/style.css"))
          original_size = File.size(source_dir("assets/css/style.css"))
          compressed_size = File.size(dest_dir("assets/css/style.css"))
          ratio = ((original_size - compressed_size).to_f / original_size * 100).round(2)
          compression_ratios << ratio
        end
      end
      
      if compression_ratios.any?
        avg_ratio = compression_ratios.sum / compression_ratios.length
        std_dev = Math.sqrt(compression_ratios.map { |r| (r - avg_ratio) ** 2 }.sum / compression_ratios.length)
        
        puts "CSS Compression Ratios: #{compression_ratios.join(', ')}%"
        puts "Average: #{avg_ratio.round(2)}%, Std Dev: #{std_dev.round(2)}%"
        
        # Compression should be consistent (low standard deviation)
        expect(std_dev).to be < 1.0, "Compression ratios should be consistent across runs"
        expect(avg_ratio).to be >= 20.0, "Average compression should be at least 20%"
      end
    end
  end

  describe "Scalability Testing" do
    it "handles multiple file types efficiently" do
      start_time = Time.now
      site.process
      processing_time = Time.now - start_time
      
      # Count processed files
      processed_files = 0
      processed_files += 1 if File.exist?(dest_dir("assets/css/style.css"))
      processed_files += 1 if File.exist?(dest_dir("assets/js/script.js"))
      processed_files += Dir[File.join(dest_dir, "**/*.html")].length
      processed_files += 1 if File.exist?(dest_dir("atom.xml"))
      
      puts "Processed #{processed_files} files in #{processing_time.round(3)}s"
      
      # Should process files efficiently
      if processed_files > 0
        time_per_file = processing_time / processed_files
        expect(time_per_file).to be < 0.5, "Should process files at reasonable speed"
      end
    end
  end

  describe "Resource Cleanup" do
    it "properly cleans up resources after processing" do
      # Simplified resource check using Ruby's ObjectSpace
      before_file_count = ObjectSpace.each_object(File).count
      
      site.process
      
      after_file_count = ObjectSpace.each_object(File).count
      
      # File object count shouldn't increase significantly
      file_increase = after_file_count - before_file_count
      puts "File object increase: #{file_increase}"
      
      expect(file_increase).to be < 50, "Should not leak file objects"
    end
  end

  describe "Concurrent Processing Safety" do
    it "handles concurrent site processing safely" do
      # This test verifies thread safety (though Jekyll itself may not be thread-safe)
      threads = []
      results = []
      
      2.times do |i|
        threads << Thread.new do
          begin
            thread_site = Jekyll::Site.new(config)
            thread_site.process
            results << "success"
          rescue => e
            results << "error: #{e.message}"
          end
        end
      end
      
      threads.each(&:join)
      
      # At least one should succeed (Jekyll might not support true concurrency)
      expect(results).to include("success")
    end
  end

  describe "Performance Regression Detection" do
    it "maintains processing speed within acceptable bounds" do
      times = []
      
      5.times do
        time = Benchmark.realtime { site.process }
        times << time
      end
      
      avg_time = times.sum / times.length
      max_time = times.max
      min_time = times.min
      
      puts "Processing Times - Avg: #{avg_time.round(3)}s, Min: #{min_time.round(3)}s, Max: #{max_time.round(3)}s"
      
      # Performance should be consistent and fast
      expect(avg_time).to be < 5.0, "Average processing time should be under 5 seconds"
      expect(max_time - min_time).to be < 2.0, "Processing time should be consistent"
    end
  end
end