#!/usr/bin/env bash
set -euo pipefail

# Ensure we are in app dir
cd /app

# DB migrations (safe for Neon)
if [ "${DISABLE_MIGRATIONS:-false}" != "true" ]; then
  echo "Testing database connection..."
  
  # Test database connection first
  if bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; then
    echo "Database connection successful, running migrations..."
    bundle exec rails db:migrate || echo "Migrations failed or not needed; continuing"
  else
    echo "Database connection failed, skipping migrations"
  fi
fi

# Start both Rails and Sidekiq using a process manager
echo "Starting Rails server and Sidekiq workers..."

# Start Sidekiq in the background
bundle exec sidekiq -C config/sidekiq.yml &
SIDEKIQ_PID=$!

# Start Puma
bundle exec puma -C config/puma.rb -p ${PORT:-8080} &
PUMA_PID=$!

# Wait for either process to exit
wait -n

# If we get here, one of the processes has exited
echo "One of the processes has exited, shutting down..."

# Kill both processes
kill $SIDEKIQ_PID 2>/dev/null || true
kill $PUMA_PID 2>/dev/null || true

exit 1

