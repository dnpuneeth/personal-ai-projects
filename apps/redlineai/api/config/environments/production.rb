# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # --- Boot & Code Loading ---
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  # --- Static/Assets ---
  # Cache assets aggressively; they're digest-stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  # If you serve assets from a CDN, set:
  # config.asset_host = ENV["ASSET_HOST"]

  # --- Storage ---
  config.active_storage.service = (ENV["ACTIVE_STORAGE_SERVICE"] || "local").to_sym

  # --- SSL / Security ---
  # Running behind Koyeb's proxy; assume SSL and enforce it.
  config.assume_ssl = true
  config.force_ssl  = true
  # Don't force HTTPS on health endpoints (Koyeb probes over HTTP)
  config.ssl_options = {
    redirect: { exclude: ->(r) { ["/up", "/healthz"].include?(r.path) } }
  }

  # Host Authorization: allow all (safe behind Koyeb's edge/router).
  # This avoids 403s when the health checker uses an internal IP Host header.
  config.hosts.clear
  # If you prefer a strict allow-list instead, use:
  # config.hosts = [ /\A.*\.koyeb\.app\z/, "koyeb.app", /\A(?:\d{1,3}\.){3}\d{1,3}\z/ ]

  # --- Logging ---
  config.log_tags = [:request_id]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  # Quiet health pings in logs (Rails 7.1+/8):
  config.silence_healthcheck_path = "/up"

  # --- Deprecations ---
  config.active_support.report_deprecations = false

  # --- Caching & Jobs ---
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :sidekiq
  # Sidekiq configuration is handled in config/initializers/sidekiq.rb

  # --- Mailer (customize for your domain/app host) ---
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "example.com"),
    protocol: "https"
  }
  # For SMTP, configure config.action_mailer.smtp_settings with credentials.

  # --- I18n / DB / Misc ---
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # Optional: if you want to pre-authorize specific hosts instead of clear:
  # config.host_authorization = {
  #   exclude: ->(r) { ["/up", "/healthz"].include?(r.path) }
  # }
end
