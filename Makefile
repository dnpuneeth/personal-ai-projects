.PHONY: help setup dev deploy migrate logs console test

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Set up the development environment
	@echo "Setting up DocuMind development environment..."
	cd apps/documind/api && bundle install
	@echo "Starting PostgreSQL and Redis..."
	docker-compose -f infra/docker-compose.dev.yml up -d
	@echo "Waiting for services to be ready..."
	sleep 10
	@echo "Running database setup..."
	cd apps/documind/api && bundle exec rails db:create db:migrate
	@echo "Setup complete! Run 'make dev' to start the development server."

dev: ## Start the development server
	@echo "Starting DocuMind development server..."
	cd apps/documind/api && bundle exec rails server -p 3000

deploy: ## Deploy to Fly.io
	@echo "Deploying to Fly.io..."
	cd apps/documind/api && flyctl deploy --config ../../infra/fly.documind.toml

migrate: ## Run database migrations on Fly.io
	@echo "Running database migrations..."
	cd apps/documind/api && flyctl ssh console -C "bundle exec rails db:migrate"

logs: ## View Fly.io logs
	@echo "Fetching logs..."
	cd apps/documind/api && flyctl logs

console: ## Open Rails console on Fly.io
	@echo "Opening Rails console..."
	cd apps/documind/api && flyctl ssh console -C "bundle exec rails console"

test: ## Run tests
	@echo "Running tests..."
	cd apps/documind/api && bundle exec rspec

clean: ## Clean up development environment
	@echo "Stopping services..."
	docker-compose -f infra/docker-compose.dev.yml down -v
	@echo "Cleanup complete." 