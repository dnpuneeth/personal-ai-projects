ARG RUBY_VERSION=3.4.4
FROM ruby:${RUBY_VERSION}-slim AS base

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH=/usr/local/bundle \
    APP_HOME=/app \
    LANG=C.UTF-8

WORKDIR ${APP_HOME}

# Install OS packages (runtime)
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
     build-essential \
     libvips \
     libpq5 \
     ca-certificates \
     curl \
     git \
     tzdata \
  && rm -rf /var/lib/apt/lists/*

# Copy gem manifests and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# Copy the app
COPY . .

# Precompile assets (tailwindcss-rails binary is bundled)
# Provide a temporary SECRET_KEY_BASE for assets:precompile
ENV SECRET_KEY_BASE=dummy
RUN bundle exec rails assets:precompile

# Entrypoint to run migrations then boot
COPY bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

EXPOSE 8080
ENV PORT=8080 \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=1

CMD ["/usr/local/bin/docker-entrypoint"]

