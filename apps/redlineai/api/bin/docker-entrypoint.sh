#!/bin/bash
set -e

echo "Starting RedlineAI application..."

# Wait for database to be ready
echo "Testing database connection..."
until bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; do
  echo "Database not ready, waiting..."
  sleep 2
done
echo "Database connection successful"

# DB migrations (safe for Supabase)
if [ "${DISABLE_MIGRATIONS:-false}" != "true" ]; then
  echo "Running database migrations..."
  bundle exec rails db:migrate || echo "Migrations failed or not needed; continuing"
fi

# Start both Rails and Sidekiq using a process manager
echo "Starting Rails server and Sidekiq workers..."

# Start Sidekiq in the background with error handling
echo "Starting Sidekiq workers..."
if bundle exec sidekiq -C config/sidekiq.yml; then
  echo "Sidekiq started successfully"
  SIDEKIQ_PID=$!
else
  echo "Sidekiq failed to start, continuing without background processing..."
  SIDEKIQ_PID=""
fi

# Start Puma (this is the main requirement)
echo "Starting Puma server..."
bundle exec puma -C config/puma.rb -p ${PORT:-8080} &
PUMA_PID=$!

# Wait a moment for Puma to start
sleep 3

# Check if Puma started successfully
if ! kill -0 $PUMA_PID 2>/dev/null; then
  echo "Puma failed to start, exiting..."
  exit 1
fi

echo "Puma started successfully (PID: $PUMA_PID)"

# Function to cleanup processes
cleanup() {
  echo "Shutting down processes..."
  if [ ! -z "$SIDEKIQ_PID" ]; then
    kill $SIDEKIQ_PID 2>/dev/null || true
  fi
  kill $PUMA_PID 2>/dev/null || true
  exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Wait for Puma to exit (main process)
wait $PUMA_PID

# If we get here, Puma has exited
echo "Puma has exited, shutting down..."

# Cleanup
cleanup

