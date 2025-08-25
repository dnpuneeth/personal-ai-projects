# RedlineAI - AI Document Analysis Platform

A powerful document analysis platform that uses AI to extract insights, identify risks, and provide intelligent summaries from PDF documents. Built with Rails 8.0.2 and modern AI technologies.

## 📚 Table of Contents

- [🚀 Key Features](#-key-features)
- [🏗️ Tech Stack](#️-tech-stack)
- [🚀 Quick Start](#-quick-start)
- [📊 Live Features](#-live-features)
- [🔌 API Documentation](#-api-documentation)
- [🗄️ Database Schema](#️-database-schema)
- [🔄 Background Jobs](#-background-jobs)
- [🚀 Deployment](#-deployment)
- [🧪 Testing](#-testing)
- [📈 Monitoring & Observability](#-monitoring--observability)
- [💰 Cost Optimization](#-cost-optimization)
- [🔧 Development Commands](#-development-commands)
- [🏗️ Architecture Patterns](#️-architecture-patterns)
- [🔮 Future Enhancements](#-future-enhancements)
- [🆘 Troubleshooting](#-troubleshooting)
- [📚 Additional Resources](#-additional-resources)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)

## 🚀 Key Features

- **PDF Upload & Processing**: Upload PDF documents and automatically extract text
- **AI-Powered Analysis**: Get comprehensive summaries, risk assessments, and answers to questions
- **Vector Search**: Semantic search through document content using embeddings
- **Cost Tracking**: Monitor AI usage and costs in real-time with comprehensive dashboard
- **Subscription Management**: Free, Pro ($29/month), and Enterprise plans with usage limits
- **Referral Program**: Earn bonus documents by referring friends and colleagues
- **Business Analytics**: Track user growth, revenue, and key metrics (admin only)
- **Caching System**: Rails caching with 3-hour expiry to optimize costs and performance
- **Dark Theme Support**: Full dark/light theme toggle with system preference detection
- **Production Ready**: Full-stack Rails application with modern UI

## 🏗️ Tech Stack

- **Backend**: Rails 8.0.2 with PostgreSQL 16 + pgvector
- **Frontend**: Tailwind CSS + Hotwire for responsive UI
- **Background Jobs**: Sidekiq with Redis 7
- **AI Models**: OpenAI GPT-4o-mini and text-embedding-3-small
- **Storage**: S3-compatible storage (AWS S3, Cloudflare R2)
- **Observability**: Sentry for error tracking, OpenTelemetry for tracing
- **Deployment**: Multi-platform support (Koyeb, Render, Fly.io, Railway, Docker)

## 🚀 Quick Start

### Prerequisites

- Ruby 3.4.4
- Docker and Docker Compose
- Git

### Local Development

1. **Start infrastructure** (from project root):

   ```bash
   make dev-infra
   ```

2. **Setup environment**:

   ```bash
   cp env.example .env
   # Edit .env with your API keys (see Environment Variables below)
   ```

3. **Install dependencies**:

   ```bash
   bundle install
   ```

4. **Setup database**:

   ```bash
   bundle exec rails db:create db:migrate
   ```

5. **Start the application**:

   ```bash
   # Start Rails server
   bundle exec rails server -p 3000

   # Start background workers (in another terminal)
   bundle exec sidekiq
   ```

6. **Access the application**:
   - **Web UI**: http://localhost:3000
   - **Cost Dashboard**: http://localhost:3000/costs
   - **Health Check**: http://localhost:3000/healthz

### Environment Variables

Required environment variables (see `env.example`):

```bash
# AI APIs
OPENAI_API_KEY=your_openai_api_key
ANTHROPIC_API_KEY=your_anthropic_api_key
EMBEDDING_MODEL=text-embedding-3-small
LLM_MODEL=gpt-4o-mini

# Database
DATABASE_URL=postgresql://localhost/redlineai_development
REDIS_URL=redis://localhost:6379/0

# Storage
S3_BUCKET=redlineai-storage
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=your_s3_access_key
S3_SECRET_ACCESS_KEY=your_s3_secret_key

# Rails
RAILS_MASTER_KEY=your_rails_master_key
```

## 📊 Live Features

- 📊 **Cost Dashboard**: Track AI usage costs, token consumption, and cache efficiency
- 🔍 **Smart Search**: RAG-powered document search with citation tracking
- 📝 **Document Analysis**: Automated summarization, risk assessment, and Q&A
- 💰 **Subscription Plans**: Free (5 docs/month), Pro ($29/month, 100 docs), Enterprise (custom)
- 🎉 **Referral System**: Earn bonus documents by referring friends and colleagues
- 📈 **Business Analytics**: Monitor user growth, revenue, and key business metrics
- 🌙 **Dark Theme**: Seamless light/dark theme switching with profile preferences
- ⚡ **Performance**: Intelligent caching reduces costs by up to 70%

## 🔌 API Documentation

### Core Endpoints

#### Upload Document

```http
POST /documents
Content-Type: multipart/form-data

file: <PDF file>
```

#### Get Document Status

```http
GET /documents/:id
```

#### AI Analysis Endpoints

**Summarize and Identify Risks**:

```http
POST /documents/:id/summarize
```

**Answer Questions**:

```http
POST /documents/:id/answer
Content-Type: application/json

{
  "question": "What are the main risks mentioned in this document?"
}
```

**Propose Redlines**:

```http
POST /documents/:id/redlines
```

#### Health Check

```http
GET /healthz
```

### Response Format

All AI endpoints return structured JSON with citations:

```json
{
  "summary": "Document summary...",
  "top_risks": [
    {
      "risk": "Legal liability",
      "severity": "high",
      "description": "Risk description..."
    }
  ],
  "citations": [
    {
      "chunk_id": 5,
      "start": 100,
      "end": 200,
      "quote": "Exact quote from document..."
    }
  ]
}
```

## 🗄️ Database Schema

### Core Models

- **Document**: Main document entity with metadata
- **DocChunk**: Text chunks with vector embeddings for semantic search
- **AIEvent**: Tracks all AI API calls for cost monitoring
- **User**: Authentication and user preferences
- **DeletedDocument**: Soft deletion tracking for compliance

### Vector Search

Uses PostgreSQL with pgvector extension for:

- Semantic similarity search
- Document chunk embeddings
- Fast retrieval of relevant content

## 🔄 Background Jobs

### Job Types

- **ExtractTextJob**: Processes PDFs and extracts text content
- **EmbedChunksJob**: Generates vector embeddings for text chunks

### Job Queue

- **Sidekiq**: Background job processing with Redis
- **Monitoring**: Built-in job monitoring and metrics

## 🚀 Deployment

RedlineAI is designed to be deployed to various cloud platforms. We provide detailed deployment guides for popular hosting services.

### Quick Deployment Options

- **Koyeb** (Recommended for free tier) - [Detailed Guide](./DEPLOYMENT.md#koyeb)
- **Render** - [Detailed Guide](./DEPLOYMENT.md#render)
- **Fly.io** - [Detailed Guide](./DEPLOYMENT.md#flyio)
- **Railway** - [Detailed Guide](./DEPLOYMENT.md#railway)

### Pre-deployment Checklist

Before deploying, ensure you have:

1. **AI API Keys**: OpenAI API key (required), Anthropic API key (optional)
2. **Database**: PostgreSQL 16+ with pgvector extension
3. **Redis**: Redis 7+ for background jobs
4. **Storage**: S3-compatible storage (AWS S3, Cloudflare R2, etc.)
5. **Rails Master Key**: Generated from `config/master.key`

### Environment Variables

All deployment methods require these environment variables:

```bash
# AI APIs (Required)
OPENAI_API_KEY=your_openai_api_key
EMBEDDING_MODEL=text-embedding-3-small
LLM_MODEL=gpt-4o-mini

# Database (Required)
DATABASE_URL=postgresql://user:password@host:port/database

# Redis (Required)
REDIS_URL=redis://user:password@host:port/database

# Storage (Required)
S3_BUCKET=your-bucket-name
S3_REGION=your-region
S3_ACCESS_KEY_ID=your_access_key
S3_SECRET_ACCESS_KEY=your_secret_key
S3_ENDPOINT=your_s3_endpoint

# Rails (Required)
RAILS_MASTER_KEY=your_rails_master_key
ACTIVE_STORAGE_SERVICE=amazon
```

### Health Checks

After deployment, verify your application is running:

```bash
# Application health
curl https://your-app.herokuapp.com/healthz

# Database connectivity
curl https://your-app.herokuapp.com/healthz/db

# Redis connectivity
curl https://your-app.herokuapp.com/healthz/redis
```

For detailed deployment instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md).

## 🧪 Testing

### Running Tests

```bash
# All tests
bundle exec rspec

# Specific test files
bundle exec rspec spec/models/document_spec.rb
bundle exec rspec spec/controllers/ai_controller_spec.rb

# Test coverage
COVERAGE=true bundle exec rspec
```

### Test Structure

- **Models**: Unit tests for business logic
- **Controllers**: Request/response testing
- **Integration**: End-to-end workflow testing
- **Factories**: Test data generation

## 📈 Monitoring & Observability

### Health Checks

- Application health: `GET /healthz`
- Database connectivity
- Redis connectivity

### Observability Stack

- **Sentry**: Error tracking and performance monitoring
- **OpenTelemetry**: Distributed tracing
- **Sidekiq**: Job monitoring and metrics

### Cost Tracking

All AI API calls are tracked in the `ai_events` table with:

- Token usage
- Latency
- Cost estimates
- Model used

## 💰 Cost Optimization

### Caching Strategy

- **3-hour cache expiry**: Reduces API calls by up to 70%
- **Smart cache invalidation**: Updates when documents change
- **Cost dashboard**: Real-time monitoring of AI spending

### Performance Metrics

- Token consumption patterns
- Cache hit rates
- Response latency tracking
- Model efficiency comparison

## 🔧 Development Commands

### Database Operations

```bash
# Reset database
bundle exec rails db:reset

# Run migrations
bundle exec rails db:migrate

# Seed data
bundle exec rails db:seed

# Console access
bundle exec rails console
```

### Background Jobs

```bash
# Start Sidekiq
bundle exec sidekiq

# Monitor jobs
bundle exec sidekiqmon

# Job console
bundle exec rails console
```

### Code Quality

```bash
# Linting
bundle exec rubocop

# Security scanning
bundle exec brakeman

# Test runner
bundle exec test_runner.rb
```

## 🏗️ Architecture Patterns

### Service Layer

- **EmbeddingsService**: Vector embedding generation
- **LLMClientService**: AI model interactions
- **RAGSearchService**: Retrieval-augmented generation
- **DocumentDeletionService**: Soft deletion handling

### Background Processing

- **Job-based architecture**: Async processing for heavy operations
- **Queue management**: Redis-backed job queuing
- **Error handling**: Retry mechanisms and dead job handling

### Caching Strategy

- **Multi-level caching**: Application and fragment caching
- **Smart invalidation**: Context-aware cache updates
- **Performance monitoring**: Cache hit rate tracking

## 🔮 Future Enhancements

### Planned Features

- **Multi-language support**: Internationalization for global users
- **Advanced analytics**: Document insights and trend analysis
- **API rate limiting**: Usage-based access control
- **Enhanced security**: Document encryption and access controls
- **Stripe integration**: Automated billing and subscription management
- **Advanced referral tracking**: Analytics and conversion optimization
- **Team collaboration**: Shared workspaces and document sharing
- **API marketplace**: White-label solutions for developers

### Technical Improvements

- **GraphQL API**: More flexible query interface
- **Real-time updates**: WebSocket integration for live updates
- **Advanced search**: Faceted search and filtering
- **Performance optimization**: Database query optimization

## 🆘 Troubleshooting

### Common Issues

1. **PDF processing fails**: Check file size and format
2. **AI responses slow**: Verify API key validity and rate limits
3. **Database errors**: Ensure PostgreSQL and pgvector are properly configured
4. **Background jobs stuck**: Check Redis connectivity and Sidekiq status

### Debug Commands

```bash
# Check application status
curl http://localhost:3000/healthz

# Monitor background jobs
bundle exec sidekiqmon

# Check logs
tail -f log/development.log

# Database connection test
bundle exec rails runner "puts ActiveRecord::Base.connection.active?"
```

## 📚 Additional Resources

- **Main Repository**: [Personal AI Projects](../..)
- **Local Testing Guide**: [LOCAL_TESTING_GUIDE.md](../../../LOCAL_TESTING_GUIDE.md)
- **Deployment Guide**: [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Quick Deployment**: [QUICK_DEPLOYMENT.md](./QUICK_DEPLOYMENT.md)
- **Marketing Strategy**: [MARKETING_STRATEGY.md](./MARKETING_STRATEGY.md)
- **Project Specification**: [PROMPT.txt](../PROMPT.txt)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📜 License

This project is for personal use and learning purposes.
