.PHONY: help setup dev test clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Set up the development environment
	@echo "Setting up RedlineAI development environment..."
	cd apps/redlineai/api && bundle install
	@echo "Start PostgreSQL and Redis locally (e.g., via Homebrew) and set DATABASE_URL/REDIS_URL."
	@echo "Then run: bundle exec rails db:create db:migrate"

dev: ## Start the development server
	@echo "Starting RedlineAI development server..."
	cd apps/redlineai/api && bundle exec rails server -p 3000

test: ## Run tests
	@echo "Running tests..."
	cd apps/redlineai/api && bundle exec rspec

clean: ## Clean up development environment
	@echo "No infra services managed by Makefile anymore."