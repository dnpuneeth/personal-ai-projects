# RedlineAI Local Testing Guide

## 🚀 Quick Start

Your RedlineAI API is now running locally! Here's how to test it:

### Current Status ✅

- ✅ Rails server running on `http://localhost:3000`
- ✅ PostgreSQL database connected
- ✅ Redis connected
- ✅ Health endpoint working
- ✅ API validation working

## 📋 Testing Steps

### 1. Basic API Tests

Run the automated test script:

```bash
cd apps/redlineai/api
./test_api.sh
```

### 2. Test with a Real PDF

1. **Get a PDF file** (any PDF document)
2. **Upload it**:
   ```bash
   curl -s http://localhost:3000/documents -X POST -F "file=@your_document.pdf" | jq .
   ```
3. **Note the document_id** from the response

### 3. Test AI Endpoints

Once you have a document_id, test the AI features:

#### Summarize and Identify Risks

```bash
curl -s http://localhost:3000/documents/{document_id}/summarize | jq .
```

#### Answer Questions

```bash
curl -s http://localhost:3000/documents/{document_id}/answer \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"question": "What are the main risks mentioned in this document?"}' | jq .
```

#### Propose Redlines

```bash
curl -s http://localhost:3000/documents/{document_id}/redlines | jq .
```

## 🔧 Environment Setup

### Required Environment Variables

For full functionality, you need to set these in your `.env` file:

```bash
# AI APIs (required for AI features)
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Database (already configured)
DATABASE_URL=postgresql://localhost/redlineai_development
REDIS_URL=redis://localhost:6379/0

# Storage (optional for local testing)
S3_BUCKET=redlineai-storage
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=your_s3_access_key
S3_SECRET_ACCESS_KEY=your_s3_secret_key

# Observability (optional for local testing)
SENTRY_DSN=your_sentry_dsn
OTEL_EXPORTER_OTLP_ENDPOINT=your_otel_endpoint
```

### Without AI Keys

If you don't have AI API keys yet, the app will still work for:

- ✅ Document upload and storage
- ✅ Text extraction and chunking
- ✅ Database operations
- ✅ Health checks

But AI features will fail gracefully.

## 🛠️ Development Commands

### Start/Stop Services

```bash
# Start PostgreSQL and Redis
docker compose -f ../../infra/docker-compose.dev.yml up -d

# Stop services
docker compose -f ../../infra/docker-compose.dev.yml down

# View logs
docker compose -f ../../infra/docker-compose.dev.yml logs -f
```

### Rails Commands

```bash
# Start Rails server
export RAILS_MASTER_KEY=$(cat config/master.key) && bundle exec rails server -p 3000

# Start background jobs (in another terminal)
bundle exec sidekiq

# Rails console
bundle exec rails console

# Database operations
bundle exec rails db:migrate
bundle exec rails db:reset
```

### API Testing

```bash
# Health check
curl http://localhost:3000/healthz

# List all routes
bundle exec rails routes

# Test specific endpoint
curl -X POST http://localhost:3000/documents -F "file=@test.pdf"
```

## 📊 Monitoring

### Health Endpoint

```bash
curl http://localhost:3000/healthz | jq .
```

### Database Status

```bash
bundle exec rails db:version
```

### Background Jobs

```bash
# Check Sidekiq web interface (if available)
# Usually at http://localhost:3000/sidekiq
```

## 🐛 Troubleshooting

### Common Issues

1. **"key must be 16 bytes" error**

   ```bash
   # Regenerate master key
   rm config/master.key
   openssl rand -base64 24 | tr -d '\n' > config/master.key
   export RAILS_MASTER_KEY=$(cat config/master.key)
   ```

2. **Database connection issues**

   ```bash
   # Check if PostgreSQL is running
   docker compose -f ../../infra/docker-compose.dev.yml ps

   # Restart services
   docker compose -f ../../infra/docker-compose.dev.yml restart
   ```

3. **Redis connection issues**

   ```bash
   # Check Redis
   docker exec infra-redis-1 redis-cli ping
   ```

4. **Port already in use**
   ```bash
   # Kill existing Rails server
   pkill -f "rails server"
   rm tmp/pids/server.pid
   ```

### Logs

```bash
# Rails logs
tail -f log/development.log

# Docker logs
docker compose -f ../../infra/docker-compose.dev.yml logs -f postgres
docker compose -f ../../infra/docker-compose.dev.yml logs -f redis
```

## 🎯 Next Steps

1. **Get AI API keys** from OpenAI and/or Anthropic
2. **Test with real PDF documents**
3. **Explore the AI features** (summarize, Q&A, redlines)
4. **Monitor costs** via the `ai_events` table
5. **Deploy to production** using the Render configuration

## 📚 API Documentation

Full API documentation is available in the main README.md file.

Happy testing! 🎉
