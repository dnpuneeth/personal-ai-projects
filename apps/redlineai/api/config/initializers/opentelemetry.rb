# OpenTelemetry configuration for distributed tracing
# DISABLED - Re-enable when needed by uncommenting below
# if ENV['OTEL_EXPORTER_OTLP_ENDPOINT'].present?
#   begin
#     require 'opentelemetry/exporter/otlp'
# 
#     OpenTelemetry::SDK.configure do |c|
#       c.service_name = 'redlineai-api'
#       c.service_version = '1.0.0'
# 
#       # Enable all instrumentation
#       c.use_all
# 
#       # Configure OTLP exporter
#       c.add_span_processor(
#         OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
#           OpenTelemetry::Exporter::OTLP::Exporter.new(
#             endpoint: ENV['OTEL_EXPORTER_OTLP_ENDPOINT']
#           )
#         )
#       )
#     end
#   rescue LoadError => e
#     Rails.logger.warn "OpenTelemetry OTLP exporter not available: #{e.message}"
#   end
# end