# Personal AI Projects

A collection of AI-powered applications and tools for document analysis, intelligent automation, and machine learning experiments.

## 🚀 Projects

### [DocuMind](apps/documind/) - AI Document Analysis Platform

A powerful document analysis platform that uses AI to extract insights, identify risks, and provide intelligent summaries from PDF documents.

**Key Features:**

- PDF Upload & Processing with AI-powered analysis
- Vector Search using embeddings for semantic document search
- Cost Tracking and optimization dashboard
- Production-ready Rails application with modern UI

**Tech Stack:** Rails 8.0.2, PostgreSQL + pgvector, Sidekiq, Redis, OpenAI GPT-4o-mini

> 📖 **For detailed setup, API documentation, and development guides, see [DocuMind README](apps/documind/api/README.md)**

## 🚀 Quick Start

## Render Deploy

Use the included Render Blueprint and optional GitHub Actions workflow:

1. Render Blueprint

   - On Render, choose New → Blueprint and connect this GitHub repo.
   - Render will read `render.yaml` and create:
     - Web service `documind-web` (Dockerfile at `apps/documind/api/Dockerfile`)
     - Worker `documind-worker` (Sidekiq)
     - Postgres `documind-db` (free plan)
     - Redis `documind-redis` (free plan)
   - Set env vars on both services: `RAILS_MASTER_KEY`, OpenAI/Anthropic keys, and S3 creds. Optional: `SENTRY_DSN`, `OTEL_EXPORTER_OTLP_ENDPOINT`.
   - Deploy. Migrations run post-deploy.

2. GitHub Actions (optional)
   - Add repo secrets: `RENDER_API_KEY`, `RENDER_WEB_SERVICE_ID`, `RENDER_WORKER_SERVICE_ID`.
   - The workflow `.github/workflows/render-deploy.yml` triggers Render deploys on pushes to `main` or via manual dispatch.

Docs: [Render](https://render.com)

### Prerequisites

- Ruby 3.4.4
- Docker and Docker Compose
- Git

### Local Development

1. **Clone the repository**:

   ```bash
   git clone https://github.com/dnpuneeth/personal-ai-projects.git
   cd personal-ai-projects
   ```

2. **Start infrastructure** (PostgreSQL + Redis):

   ```bash
   make dev-infra
   ```

3. **Setup individual projects**:

   Each project in the `apps/` directory has its own setup instructions. Navigate to the project directory and follow the README for specific setup steps.

   ```bash
   # Example for DocuMind
   cd apps/documind/api
   cp env.example .env
   # Edit .env with your API keys
   bundle install
   bundle exec rails db:create db:migrate
   ```

## 📁 Repository Structure

```
personal-ai-projects/
├── apps/                    # Individual AI project applications
│   └── documind/           # AI Document Analysis Platform
│       ├── api/            # Rails backend API
│       │   └── README.md   # 📖 Detailed setup & API docs
│       └── PROMPT.txt      # Project specification
├── infra/                  # Infrastructure configuration
│   ├── docker-compose.dev.yml
│
├── render.yaml            # Render Blueprint (web, worker, Postgres, Redis)
├── .github/workflows/
│   └── render-deploy.yml  # Optional GitHub Actions workflow to trigger Render deploys
├── LOCAL_TESTING_GUIDE.md  # Development setup guide
├── Makefile               # Build and deployment commands
└── README.md              # This file
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
2. Follow the established patterns from existing projects
3. Create a comprehensive README.md with setup and documentation
4. Update this main README with project details
5. Add appropriate infrastructure configuration

### Project Standards

Each project should include:

- Clear README.md with setup instructions
- Environment configuration examples
- API documentation (if applicable)
- Testing instructions
- Deployment guides

### Running Tests

Each project has its own testing setup. Navigate to the project directory and follow the testing instructions in the project's README.

```bash
# Example for DocuMind
cd apps/documind/api
bundle exec rspec
```

## 📊 Project Features

### DocuMind

- **AI Document Analysis**: PDF processing with intelligent insights
- **Cost Optimization**: Real-time tracking and caching strategies
- **Vector Search**: Semantic document search using embeddings
- **Production Ready**: Full-stack application with monitoring

### Future Projects

- **ChatBot Framework**: Customizable AI conversations
- **Data Pipeline**: AI-powered ETL and data cleaning
- **ML Experiments**: Various machine learning models and experiments

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Update relevant README files
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 📜 License

This project is for personal use and learning purposes.

## 🆘 Support

### For Individual Projects

Each project has its own detailed README with:

- Setup instructions
- Troubleshooting guides
- API documentation
- Development workflows

Navigate to the specific project directory and read the README.md file.

### For Repository Issues

For general repository questions or issues:

1. Check the project-specific README in the `apps/` directory
2. Review the `LOCAL_TESTING_GUIDE.md` for development setup
3. Open an issue on GitHub

### Quick Navigation

- **DocuMind**: [apps/documind/api/README.md](apps/documind/api/README.md)
- **Development Guide**: [LOCAL_TESTING_GUIDE.md](LOCAL_TESTING_GUIDE.md)
- **Infrastructure**: [infra/](infra/)
