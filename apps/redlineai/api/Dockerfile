# syntax=docker/dockerfile:1.4
ARG RUBY_VERSION=3.4.4
ARG NODE_VERSION=20.11.1
ARG YARN_VERSION=1.22.19
ARG BUNDLER_VERSION=2.5.10

# Base image for dependencies
FROM docker.io/library/ruby:$RUBY_VERSION-slim-bookworm AS base

# Install build dependencies and runtime packages
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libpq-dev \
    libvips-dev \
    libyaml-dev \
    git \
    curl \
    gnupg2 \
    ca-certificates \
    nodejs \
    yarn \
    postgresql-client \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set up Node.js and Yarn
RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn@$YARN_VERSION

# Set working directory
WORKDIR /app

# Install Ruby gems
FROM base AS gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle config set --local build.psych --with-libyaml-dir=/usr && \
    bundle install --jobs $(nproc) --retry 3

# Build assets
FROM base AS assets
COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY package.json yarn.lock ./
COPY app/assets app/assets
COPY app/javascript app/javascript
COPY config/tailwind.config.js config/tailwind.config.js
COPY config/initializers/assets.rb config/initializers/assets.rb
RUN yarn install --check-files && \
    bundle exec rails tailwindcss:build && \
    bundle exec rails assets:precompile

# Final stage for the application
FROM base AS final
COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY --from=assets /app/public /app/public
COPY --from=assets /app/tmp /app/tmp
COPY . .

# Ensure the entrypoint script is executable
RUN chmod +x bin/docker-entrypoint.sh

# Expose port 8080
EXPOSE 8080

# Entrypoint script to run migrations and start the server
ENTRYPOINT ["./bin/docker-entrypoint.sh"]

