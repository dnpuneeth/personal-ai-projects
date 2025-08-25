# RedlineAI Deployment Guide

This guide provides detailed instructions for deploying RedlineAI to various cloud platforms. Choose the platform that best fits your needs and budget.

## 📋 Prerequisites

Before deploying, ensure you have:

- **Git repository access** to the RedlineAI codebase
- **AI API keys** (OpenAI required, Anthropic optional)
- **Cloud accounts** for your chosen hosting platform
- **Database service** (PostgreSQL 16+ with pgvector)
- **S3-compatible storage** for file uploads

> **Note**: RedlineAI uses Solid Queue for background job processing, which stores job data directly in PostgreSQL. No separate Redis service is required.

## 🔑 Environment Variables

All deployment methods require these environment variables. **Never commit these to version control:**

```bash
# AI APIs
OPENAI_API_KEY=your_openai_api_key_here
EMBEDDING_MODEL=text-embedding-3-small
LLM_MODEL=gpt-4o-mini

# Database (PostgreSQL with pgvector)
DATABASE_URL=postgresql://username:password@host:port/database_name

# S3-Compatible Storage
S3_BUCKET=your-bucket-name
S3_REGION=your-region
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_ENDPOINT=your_s3_endpoint_url

# Rails
RAILS_MASTER_KEY=your_rails_master_key
ACTIVE_STORAGE_SERVICE=amazon
RAILS_ENV=production
```

## 🚀 Koyeb (Recommended for Free Tier)

Koyeb offers a generous free tier and easy deployment process.

### 1. Setup External Services

#### Database: Supabase (Free Tier)

1. Create account at [supabase.com](https://supabase.com)
2. Create new project
3. Create database
4. Run in SQL editor: `CREATE EXTENSION IF NOT EXISTS vector;`
5. Copy connection string from Settings → Database

#### Storage: Cloudflare R2 (Free Tier)

1. Create account at [cloudflare.com](https://cloudflare.com)
2. Go to R2 Object Storage
3. Create bucket `redlineai-storage`
4. Create API token with R2 permissions
5. Note endpoint URL

### 2. Deploy to Koyeb

#### Option A: GitHub Integration (Recommended)

1. Go to [koyeb.com](https://koyeb.com) and create account
2. Click "Create App" → "GitHub"
3. Select your repository
4. Set source directory: `apps/redlineai/api`
5. Build command: `bundle install && bundle exec rails assets:precompile`
6. Run command: `bundle exec rails server -p $PORT -e production`
7. Set port: `8080`

#### Option B: Docker Image

1. Build and push Docker image to registry
2. In Koyeb, select "Docker" as source
3. Enter image name and tag
4. Set port: `8080`

### 3. Configure Environment Variables

In Koyeb dashboard → Your App → Environment Variables:

```bash
OPENAI_API_KEY=your_openai_key
DATABASE_URL=your_supabase_connection_string
S3_BUCKET=redlineai-storage
S3_REGION=auto
S3_ACCESS_KEY_ID=your_r2_access_key
S3_SECRET_ACCESS_KEY=your_r2_secret_key
S3_ENDPOINT=your_r2_endpoint
RAILS_MASTER_KEY=your_rails_master_key
ACTIVE_STORAGE_SERVICE=amazon
RAILS_ENV=production
```

### 4. Verify Deployment

```bash
# Check app health
curl https://your-app-name-org.koyeb.app/healthz

# Check database connectivity
curl https://your-app-name-org.koyeb.app/healthz/db
```

## 🌐 Render

Render offers reliable hosting with a free tier for static sites and paid tiers for web services.

### 1. Setup External Services

Same as Koyeb (Supabase, Cloudflare R2)

### 2. Deploy to Render

1. Go to [render.com](https://render.com) and create account
2. Click "New" → "Web Service"
3. Connect GitHub repository
4. Set build command: `bundle install && bundle exec rails assets:precompile`
5. Set start command: `bundle exec rails server -p $PORT -e production`
6. Select instance type (Free tier available for testing)

### 3. Configure Environment Variables

In Render dashboard → Your Service → Environment:

```bash
OPENAI_API_KEY=your_openai_key
DATABASE_URL=your_supabase_connection_string
S3_BUCKET=redlineai-storage
S3_REGION=auto
S3_ACCESS_KEY_ID=your_r2_access_key
S3_SECRET_ACCESS_KEY=your_r2_secret_key
S3_ENDPOINT=your_r2_endpoint
RAILS_MASTER_KEY=your_rails_master_key
ACTIVE_STORAGE_SERVICE=amazon
RAILS_ENV=production
```

### 4. Verify Deployment

```bash
curl https://your-app-name.onrender.com/healthz
```

## ✈️ Fly.io

Fly.io offers global deployment with generous free tier.

### 1. Install Fly CLI

```bash
# macOS
brew install flyctl

# Linux
curl -L https://fly.io/install.sh | sh

# Windows
iwr https://fly.io/install.ps1 -useb | iex
```

### 2. Setup External Services

Same as previous platforms (Supabase, Cloudflare R2)

### 3. Deploy to Fly.io

1. Login: `fly auth login`
2. Create app: `fly apps create redlineai`
3. Set secrets:

```bash
fly secrets set OPENAI_API_KEY="your_key"
fly secrets set DATABASE_URL="your_db_url"
fly secrets set S3_BUCKET="redlineai-storage"
fly secrets set S3_REGION="auto"
fly secrets set S3_ACCESS_KEY_ID="your_key"
fly secrets set S3_SECRET_ACCESS_KEY="your_secret"
fly secrets set S3_ENDPOINT="your_endpoint"
fly secrets set RAILS_MASTER_KEY="your_key"
fly secrets set ACTIVE_STORAGE_SERVICE="amazon"
fly secrets set RAILS_ENV="production"
```

4. Deploy: `fly deploy`

### 4. Verify Deployment

```bash
fly status
curl https://redlineai.fly.dev/healthz
```

## 🚂 Railway

Railway offers simple deployment with automatic scaling.

### 1. Setup External Services

Same as previous platforms (Supabase, Cloudflare R2)

### 2. Deploy to Railway

1. Go to [railway.app](https://railway.app) and create account
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your repository
4. Set source directory: `apps/redlineai/api`
5. Set build command: `bundle install && bundle exec rails assets:precompile`
6. Set start command: `bundle exec rails server -p $PORT -e production`

### 3. Configure Environment Variables

In Railway dashboard → Your Service → Variables:

```bash
OPENAI_API_KEY=your_openai_key
DATABASE_URL=your_supabase_connection_string
S3_BUCKET=redlineai-storage
S3_REGION=auto
S3_ACCESS_KEY_ID=your_r2_access_key
S3_SECRET_ACCESS_KEY=your_r2_secret_key
S3_ENDPOINT=your_r2_endpoint
RAILS_MASTER_KEY=your_rails_master_key
ACTIVE_STORAGE_SERVICE=amazon
RAILS_ENV=production
```

### 4. Verify Deployment

```bash
curl https://your-app-name.railway.app/healthz
```

## 🐳 Docker Deployment

For custom infrastructure or self-hosting.

### 1. Build Docker Image

```bash
cd apps/redlineai/api
docker build -t redlineai:latest .
```

### 2. Run with Docker Compose

Create `docker-compose.yml`:

```yaml
version: "3.8"
services:
  web:
    image: redlineai:latest
    ports:
      - "3000:3000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - DATABASE_URL=${DATABASE_URL}
      - S3_BUCKET=${S3_BUCKET}
      - S3_REGION=${S3_REGION}
      - S3_ACCESS_KEY_ID=${S3_ACCESS_KEY_ID}
      - S3_SECRET_ACCESS_KEY=${S3_SECRET_ACCESS_KEY}
      - S3_ENDPOINT=${S3_ENDPOINT}
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
      - ACTIVE_STORAGE_SERVICE=amazon
      - RAILS_ENV=production
    depends_on:
      - postgres

  postgres:
    image: postgres:16
    environment:
      - POSTGRES_DB=redlineai
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### 3. Deploy

```bash
docker-compose up -d
```

## 🔍 Post-Deployment Verification

### 1. Health Checks

```bash
# Application health
curl https://your-app-url/healthz

# Database connectivity
curl https://your-app-url/healthz/db
```

### 2. Test Core Functionality

1. **User Registration**: Create a test account
2. **Document Upload**: Upload a test PDF
3. **AI Analysis**: Test summarization and Q&A
4. **Cost Dashboard**: Verify cost tracking

### 3. Monitor Logs

Check application logs for any errors:

```bash
# Koyeb
# Dashboard → Your App → Logs

# Render
# Dashboard → Your Service → Logs

# Fly.io
fly logs

# Railway
# Dashboard → Your Service → Logs
```

## 🚨 Troubleshooting

### Common Issues

#### Database Connection Errors

- Verify `DATABASE_URL` format
- Ensure pgvector extension is installed
- Check database firewall settings

#### S3 Storage Errors

- Verify S3 credentials and permissions
- Check bucket name and region
- Ensure endpoint URL is correct

#### Rails Master Key Errors

- Generate new key: `rails credentials:edit`
- Copy from `config/master.key`
- Verify environment variable name

### Debug Commands

```bash
# Check environment variables
rails runner "puts ENV['DATABASE_URL']"

# Test database connection
rails runner "puts ActiveRecord::Base.connection.active?"



# Check S3 connectivity
rails runner "puts Aws::S3::Client.new.region"
```

## 📊 Cost Optimization

### Free Tier Limits

- **Koyeb**: 2 free apps, 512MB RAM each
- **Render**: Free tier for static sites, paid for web services
- **Fly.io**: 3 free apps, 3GB RAM total
- **Railway**: $5/month minimum

### Scaling Considerations

- **Database**: Supabase free tier (500MB), paid tiers available
- **Storage**: Cloudflare R2 free tier (10GB)

## 🔒 Security Best Practices

1. **Never commit secrets** to version control
2. **Use environment variables** for all sensitive data
3. **Enable HTTPS** on all production deployments
4. **Regular security updates** for dependencies
5. **Monitor access logs** for suspicious activity

## 📚 Additional Resources

- [Rails Deployment Guide](https://guides.rubyonrails.org/deployment.html)
- [PostgreSQL pgvector Documentation](https://github.com/pgvector/pgvector)
- [Redis Documentation](https://redis.io/documentation)
- [S3-Compatible Storage Guide](https://docs.aws.amazon.com/s3/)

## 🆘 Getting Help

If you encounter deployment issues:

1. Check the troubleshooting section above
2. Review platform-specific documentation
3. Check application logs for error details
4. Verify all environment variables are set correctly
5. Ensure external services are running and accessible

For code-specific issues, check the [main README](./README.md) or open an issue in the repository.
