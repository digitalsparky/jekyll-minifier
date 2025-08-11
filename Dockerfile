# Use official Ruby image with a specific version for consistency
FROM ruby:3.3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    nodejs \
    npm \
    default-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy gemspec and Gemfile first (for better Docker layer caching)
COPY jekyll-minifier.gemspec Gemfile ./
COPY lib/jekyll-minifier/version.rb lib/jekyll-minifier/

# Install Ruby dependencies
RUN bundle install

# Copy the rest of the application
COPY . .

# Set environment variables
ENV JEKYLL_ENV=production

# Default command
CMD ["bundle", "exec", "rspec"]