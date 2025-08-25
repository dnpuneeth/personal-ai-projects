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

# Start Rails server and Solid Queue worker
echo "Starting Rails server with Solid Queue worker..."

# Start Solid Queue worker in the background with reduced memory footprint
echo "Starting Solid Queue worker with low memory config..."
SOLID_QUEUE_THREAD_POOL_SIZE=1 bundle exec rails solid_queue:start &
SOLID_QUEUE_PID=$!

# Wait a moment for Solid Queue to start
sleep 3

# Check if Solid Queue started successfully
if ! kill -0 $SOLID_QUEUE_PID 2>/dev/null; then
  echo "Solid Queue failed to start, continuing without background processing..."
  SOLID_QUEUE_PID=""
else
  echo "Solid Queue worker started successfully (PID: $SOLID_QUEUE_PID)"
fi

# Start Puma server
echo "Starting Puma server..."
bundle exec puma -C config/puma.rb -p ${PORT:-8080} &
PUMA_PID=$!

# Wait a moment for Puma to start
sleep 3

# Check if Puma started successfully
if ! kill -0 $PUMA_PID 2>/dev/null; then
  echo "Puma failed to start, exiting..."
  if [ ! -z "$SOLID_QUEUE_PID" ]; then
    kill $SOLID_QUEUE_PID 2>/dev/null || true
  fi
  exit 1
fi

echo "Puma started successfully (PID: $PUMA_PID)"

# Function to cleanup processes
cleanup() {
  echo "Shutting down processes..."
  if [ ! -z "$SOLID_QUEUE_PID" ]; then
    kill $SOLID_QUEUE_PID 2>/dev/null || true
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

