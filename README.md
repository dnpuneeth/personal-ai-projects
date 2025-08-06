# Personal AI Projects

A collection of AI-powered applications and tools for document analysis, intelligent automation, and machine learning experiments.

## 🚀 Projects

### [DocuMind](apps/documind/) - AI Document Analysis Platform

A powerful document analysis platform that uses AI to extract insights, identify risks, and provide intelligent summaries from PDF documents.

**Key Features:**

- **PDF Upload & Processing**: Upload PDF documents and automatically extract text
- **AI-Powered Analysis**: Get comprehensive summaries, risk assessments, and answers to questions
- **Vector Search**: Semantic search through document content using embeddings
- **Cost Tracking**: Monitor AI usage and costs in real-time with comprehensive dashboard
- **Caching System**: Rails caching with 3-hour expiry to optimize costs and performance
- **Production Ready**: Full-stack Rails application with modern UI

**Tech Stack:**

- **Backend**: Rails 8.0.2 with PostgreSQL 16 + pgvector
- **Frontend**: Tailwind CSS + Hotwire for responsive UI
- **Background Jobs**: Sidekiq with Redis 7
- **AI Models**: OpenAI GPT-4o-mini and text-embedding-3-small
- **Storage**: S3-compatible storage (AWS S3, Cloudflare R2)
- **Observability**: Sentry for error tracking, OpenTelemetry for tracing
- **Deployment**: Docker + Kamal deployment configuration

**Live Features:**

- 📊 **Cost Dashboard**: Track AI usage costs, token consumption, and cache efficiency
- 🔍 **Smart Search**: RAG-powered document search with citation tracking
- 📝 **Document Analysis**: Automated summarization, risk assessment, and Q&A
- ⚡ **Performance**: Intelligent caching reduces costs by up to 70%

## 🚀 Quick Start

### Prerequisites

- Ruby 3.4.4
- Docker and Docker Compose
- Node.js (for frontend assets)
- Git

### Local Development

1. **Clone the repository**:

   ```bash
   git clone https://github.com/dnpuneeth/personal-ai-projects.git
   cd personal-ai-projects
   ```

2. **Setup DocuMind**:

   ```bash
   # Start infrastructure (PostgreSQL + Redis)
   make dev-infra

   # Setup DocuMind API
   cd apps/documind/api
   cp env.example .env
   # Edit .env with your API keys (see Environment Variables below)

   bundle install
   bundle exec rails db:create db:migrate
   ```

3. **Start the application**:

   ```bash
   # Start Rails server (from apps/documind/api/)
   bundle exec rails server -p 3000

   # Start background workers (in another terminal)
   bundle exec sidekiq
   ```

4. **Access the application**:
   - **Web UI**: http://localhost:3000
   - **Cost Dashboard**: http://localhost:3000/costs
   - **Health Check**: http://localhost:3000/healthz

### Environment Variables

Required environment variables (see `apps/documind/api/env.example`):

```bash
# AI APIs
OPENAI_API_KEY=your_openai_api_key
ANTHROPIC_API_KEY=your_anthropic_api_key
EMBEDDING_MODEL=text-embedding-3-small
LLM_MODEL=gpt-4o-mini

# Database
DATABASE_URL=postgresql://localhost/documind_development
REDIS_URL=redis://localhost:6379/0

# Storage
S3_BUCKET=documind-storage
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=your_s3_access_key
S3_SECRET_ACCESS_KEY=your_s3_secret_key

# Observability
SENTRY_DSN=your_sentry_dsn
OTEL_EXPORTER_OTLP_ENDPOINT=your_otel_endpoint

# Rails
RAILS_MASTER_KEY=your_rails_master_key
```

## API Documentation

### Endpoints

#### Upload Document

```http
POST /documents
Content-Type: multipart/form-data

file: <PDF file>
```

Response:

```json
{
  "document_id": 123,
  "status": "pending",
  "title": "document.pdf"
}
```

#### Get Document Status

```http
GET /documents/:id
```

Response:

```json
{
  "id": 123,
  "title": "document.pdf",
  "status": "completed",
  "page_count": 10,
  "chunk_count": 25,
  "created_at": "2024-08-04T18:12:29Z",
  "updated_at": "2024-08-04T18:15:30Z"
}
```

#### AI Analysis

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

### Response Formats

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

## Deployment

### Fly.io Deployment

1. **Install Fly CLI**:

   ```bash
   curl -L https://fly.io/install.sh | sh
   fly auth login
   ```

2. **Create app**:

   ```bash
   cd apps/documind/api
   fly launch --config ../../infra/fly.documind.toml --name documind-yourhandle --region sin
   ```

3. **Set secrets**:

   ```bash
   fly secrets set OPENAI_API_KEY=your_key
   fly secrets set ANTHROPIC_API_KEY=your_key
   fly secrets set RAILS_MASTER_KEY=your_key
   fly secrets set S3_BUCKET=your_bucket
   fly secrets set S3_REGION=your_region
   fly secrets set S3_ACCESS_KEY_ID=your_key
   fly secrets set S3_SECRET_ACCESS_KEY=your_secret
   fly secrets set SENTRY_DSN=your_dsn
   fly secrets set OTEL_EXPORTER_OTLP_ENDPOINT=your_endpoint
   fly secrets set REDIS_URL=your_redis_url
   ```

4. **Deploy**:

   ```bash
   make deploy
   ```

5. **Run migrations**:
   ```bash
   make migrate
   ```

### Database Setup

The app automatically enables the pgvector extension in production and creates the necessary vector fields and indexes.

## Development

### Running Tests

```bash
make test
```

### Database Commands

```bash
# Reset database
bundle exec rails db:reset

# Run migrations
bundle exec rails db:migrate

# Seed data
bundle exec rails db:seed
```

### Background Jobs

```bash
# Start Sidekiq
bundle exec sidekiq

# Monitor jobs
bundle exec sidekiqmon
```

## Monitoring

### Health Checks

- Application health: `GET /healthz`
- Database connectivity
- Redis connectivity

### Observability

- **Sentry**: Error tracking and performance monitoring
- **OpenTelemetry**: Distributed tracing
- **Sidekiq**: Job monitoring and metrics

### Cost Tracking

All AI API calls are tracked in the `ai_events` table with:

- Token usage
- Latency
- Cost estimates
- Model used

## Evaluation

The system includes evaluation capabilities:

- Automated testing of AI responses
- Cost tracking and optimization
- Performance monitoring
- Quality metrics

## 📁 Repository Structure

```
personal-ai-projects/
├── apps/
│   └── documind/           # AI Document Analysis Platform
│       ├── api/           # Rails backend API
│       └── PROMPT.txt     # Project specification
├── infra/                 # Infrastructure configuration
│   ├── docker-compose.dev.yml
│   └── fly.documind.toml
├── LOCAL_TESTING_GUIDE.md # Development setup guide
├── Makefile              # Build and deployment commands
└── README.md             # This file
```

## 🔮 Future Projects

This repository is designed to host multiple AI-powered projects:

- **DocuMind** ✅ - AI Document Analysis Platform (Complete)
- **ChatBot Framework** 🚧 - Customizable AI chatbot with memory
- **Data Pipeline** 📋 - ETL workflows with AI-powered data cleaning
- **ML Experiments** 🧪 - Various machine learning experiments and models

## 🛠️ Development

### Adding New Projects

1. Create a new directory under `apps/`
2. Follow the established patterns from DocuMind
3. Update this README with project details
4. Add appropriate infrastructure configuration

### Running Tests

```bash
# DocuMind tests
cd apps/documind/api
bundle exec rspec
```

## 📊 Cost Optimization

The DocuMind project includes comprehensive cost tracking and optimization:

- **Real-time Cost Dashboard**: Monitor AI usage and spending
- **Intelligent Caching**: 3-hour cache reduces API calls by up to 70%
- **Token Usage Analytics**: Track consumption patterns
- **Model Performance Metrics**: Compare efficiency across AI models

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

## 🆘 Support

For DocuMind issues:

1. Check the health endpoint: `http://localhost:3000/healthz`
2. Review the cost dashboard: `http://localhost:3000/costs`
3. Check application logs
4. Verify environment variables in `.env`

For general repository questions, please open an issue on GitHub.
