#!/usr/bin/env bash
set -euo pipefail

# Ensure we are in app dir
cd /app

# DB migrations (safe for Neon)
if [ "${DISABLE_MIGRATIONS:-false}" != "true" ]; then
  bundle exec rails db:migrate || echo "Migrations failed or not needed; continuing"
fi

# Start Puma on $PORT
exec bundle exec puma -C config/puma.rb -p ${PORT:-8080}

