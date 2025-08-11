require 'spec_helper'

describe "JekyllMinifier" do
  let(:overrides) { Hash.new }
  let(:config) do
    Jekyll.configuration(Jekyll::Utils.deep_merge_hashes({
      "full_rebuild" => true,
      "source"      => source_dir,
      "destination" => dest_dir,
      "show_drafts" => true,
      "url"         => "http://example.org",
      "name"       => "My awesome site",
      "author"      => {
        "name"        => "Dr. Jekyll"
      },
      "collections" => {
        "my_collection" => { "output" => true },
        "other_things"  => { "output" => false }
      }
    }, overrides))
  end
  let(:site)     { Jekyll::Site.new(config) }
  let(:context)  { make_context(site: site) }
  before(:each) do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('JEKYLL_ENV').and_return('production')
    site.process
  end

  context "test_atom" do
    it "creates a atom.xml file" do
      expect(Pathname.new(dest_dir("atom.xml"))).to exist
    end

    let(:atom) { File.read(dest_dir("atom.xml")) }

    it "puts all the posts in the atom.xml file" do
      expect(atom).to match "http://example.org/random/random.html"
      expect(atom).to match "http://example.org/reviews/test-review-1.html"
      expect(atom).to match "http://example.org/reviews/test-review-2.html"
    end

    let(:feed) { RSS::Parser.parse(atom) }

    it "outputs an RSS feed" do
      expect(feed.feed_type).to eql("atom")
      expect(feed.feed_version).to eql("1.0")
      expect(feed.encoding).to eql("UTF-8")
    end

    it "outputs the link" do
      expect(feed.link.href).to eql("http://example.org/atom.xml")
    end
  end

  context "test_css" do
    it "creates a assets/css/style.css file" do
      expect(Pathname.new(dest_dir("assets/css/style.css"))).to exist
    end

    let(:file) { File.read(dest_dir("assets/css/style.css")) }

    it "ensures assets/css/style.css file has length" do
      expect(file.length).to be > 0
    end

    it "ensures CSS is minified without line breaks for performance (PR #61 integration)" do
      # This test validates PR #61: CSS minification without line breaks for better performance
      # The linebreakpos: 0 parameter should eliminate all line breaks in CSS output
      expect(file).not_to include("\n"), "CSS should be minified to a single line for performance optimization"
      expect(file).not_to include("\r"), "CSS should not contain carriage returns"
      expect(file.split("\n").length).to eq(1), "CSS should be compressed to exactly one line"
    end
  end

  context "test_404" do
    it "creates a 404.html file" do
      expect(Pathname.new(dest_dir("404.html"))).to exist
    end

    let(:file) { File.read(dest_dir("404.html")) }

    it "ensures 404.html file has length" do
      expect(file.length).to be > 0
    end
  end

  context "test_index" do
    it "creates a index.html file" do
      expect(Pathname.new(dest_dir("index.html"))).to exist
    end

    let(:file) { File.read(dest_dir("index.html")) }

    it "ensures index.html file has length" do
      expect(file.length).to be > 0
    end
  end

  context "test_random_index" do
    it "creates a random/index.html file" do
      expect(Pathname.new(dest_dir("random/index.html"))).to exist
    end

    let(:file) { File.read(dest_dir("random/index.html")) }

    it "ensures random/index.html file has length" do
      expect(file.length).to be > 0
    end
  end

  context "test_random_random" do
    it "creates a random/random.html file" do
      expect(Pathname.new(dest_dir("random/random.html"))).to exist
    end

    let(:file) { File.read(dest_dir("random/random.html")) }

    it "ensures random/random.html file has length" do
      expect(file.length).to be > 0
    end
  end

  context "test_reviews_index" do
    it "creates a reviews/index.html file" do
      expect(Pathname.new(dest_dir("reviews/index.html"))).to exist
    end

    let(:file) { File.read(dest_dir("reviews/index.html")) }

    it "ensures reviews/index.html file has length" do
      expect(file.length).to be > 0
    end
  end

  context "test_reviews_test-review-1" do
    it "creates a reviews/test-review-1.html file" do
      expect(Pathname.new(dest_dir("reviews/test-review-1.html"))).to exist
    end

    let(:file) { File.read(dest_dir("reviews/test-review-1.html")) }

    it "ensures reviews/test-review-1.html file has length" do
      expect(file.length).to be > 0
    end
  end

  context "test_reviews_test-review-2" do
    it "creates a reviews/test-review-2.html file" do
      expect(Pathname.new(dest_dir("reviews/test-review-2.html"))).to exist
    end

    let(:file) { File.read(dest_dir("reviews/test-review-2.html")) }

    it "ensures reviews/test-review-2.html file has length" do
      expect(file.length).to be > 0
    end
  end

  context "test_es6_javascript" do
    it "creates a assets/js/script.js file with ES6+ content" do
      expect(Pathname.new(dest_dir("assets/js/script.js"))).to exist
    end

    let(:es6_js) { File.read(dest_dir("assets/js/script.js")) }

    it "ensures script.js file has been minified and has length" do
      expect(es6_js.length).to be > 0
      # Verify it's actually minified by checking it doesn't contain original comments and formatting
      expect(es6_js).not_to include("// Legacy JavaScript")
      expect(es6_js).not_to include("// Modern ES6+ JavaScript to test harmony mode")
      expect(es6_js).not_to include("\n  ")
    end

    it "handles ES6+ syntax (const, arrow functions, classes) without errors" do
      # If the file exists and has content, it means ES6+ was processed successfully
      # The original script.js now contains const, arrow functions, and classes
      expect(es6_js.length).to be > 0
      # Verify legacy function is still there (should be minified)
      expect(es6_js).to include("sampleFunction")
      # The fact that the build succeeded means ES6+ syntax was processed without errors
    end

    it "maintains backward compatibility with legacy JavaScript" do
      # Verify legacy JS is still processed correctly alongside ES6+ code
      expect(es6_js.length).to be > 0
      expect(es6_js).to include("sampleFunction")
    end
  end

  context "test_backward_compatibility" do
    let(:overrides) { 
      {
        "jekyll-minifier" => {
          "uglifier_args" => { "harmony" => true }
        }
      }
    }
    
    let(:js_content) { File.read(dest_dir("assets/js/script.js")) }
    
    it "supports uglifier_args for backward compatibility" do
      # If the build succeeds with uglifier_args in config, backward compatibility works
      expect(Pathname.new(dest_dir("assets/js/script.js"))).to exist
      
      # Verify the JS file was processed and has content
      expect(js_content.length).to be > 0
      # Verify it's minified (no comments or excessive whitespace)
      expect(js_content).not_to include("// Legacy JavaScript")
    end
  end

end
