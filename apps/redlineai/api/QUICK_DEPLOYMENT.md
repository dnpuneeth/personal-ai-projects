# 🚀 Quick Deployment Guide - Get RedlineAI Live in 30 Minutes

## 🎯 **Goal**: Deploy RedlineAI to production and start getting users TODAY

---

## ⚡ **Step 1: Deploy to Koyeb (Free Tier)**

### **1.1 Create Koyeb Account**
1. Go to [koyeb.com](https://koyeb.com)
2. Sign up with GitHub (recommended)
3. Verify your email

### **1.2 Deploy Your App**
1. Click "Create App" → "GitHub"
2. Select your repository: `personal-ai-projects`
3. Set source directory: `apps/redlineai/api`
4. Build command: `bundle install && bundle exec rails assets:precompile`
5. Run command: `bundle exec rails server -p $PORT -e production`
6. Set port: `8080`

### **1.3 Environment Variables**
Add these in Koyeb dashboard:

```bash
# AI APIs (Required)
OPENAI_API_KEY=your_openai_api_key_here
EMBEDDING_MODEL=text-embedding-3-small
LLM_MODEL=gpt-4o-mini

# Database (Use Supabase - Free)
DATABASE_URL=postgresql://postgres:[password]@[host]:5432/postgres

# Storage (Use Cloudflare R2 - Free)
S3_BUCKET=redlineai-storage
S3_REGION=auto
S3_ACCESS_KEY_ID=your_r2_access_key
S3_SECRET_ACCESS_KEY=your_r2_secret_key
S3_ENDPOINT=https://[account_id].r2.cloudflarestorage.com

# Rails
RAILS_MASTER_KEY=your_rails_master_key
ACTIVE_STORAGE_SERVICE=amazon
RAILS_ENV=production
```

---

## 🗄️ **Step 2: Setup Database (Supabase - Free)**

### **2.1 Create Supabase Project**
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Wait for setup (2-3 minutes)

### **2.2 Enable pgvector Extension**
1. Go to SQL Editor
2. Run: `CREATE EXTENSION IF NOT EXISTS vector;`
3. Copy connection string from Settings → Database

### **2.3 Run Migrations**
1. In Koyeb, go to your app's terminal
2. Run: `bundle exec rails db:migrate`
3. Run: `bundle exec rails db:seed` (if you have seeds)

---

## 💾 **Step 3: Setup Storage (Cloudflare R2 - Free)**

### **3.1 Create Cloudflare Account**
1. Go to [cloudflare.com](https://cloudflare.com)
2. Sign up and verify email

### **3.2 Create R2 Bucket**
1. Go to R2 Object Storage
2. Create bucket: `redlineai-storage`
3. Create API token with R2 permissions
4. Note endpoint URL

---

## 🔑 **Step 4: Get Your Rails Master Key**

### **4.1 Generate Key**
```bash
# In your local project directory
cd apps/redlineai/api
bundle exec rails credentials:edit
```

### **4.2 Copy Key**
Copy the generated key from `config/master.key` and add it to Koyeb environment variables.

---

## 🌐 **Step 5: Custom Domain (Optional)**

### **5.1 Buy Domain**
- **Recommended**: Namecheap or Google Domains
- **Cost**: ~$10-15/year
- **Domain**: `redlineai.com` or similar

### **5.2 Configure DNS**
1. In Koyeb, go to your app → Settings → Domains
2. Add your custom domain
3. Update DNS records as instructed

---

## ✅ **Step 6: Test Your Deployment**

### **6.1 Health Check**
Visit: `https://your-app.koyeb.app/healthz`

### **6.2 Test Features**
1. Upload a PDF document
2. Test AI analysis
3. Check subscription page
4. Verify cost tracking

---

## 🚀 **Step 7: Start Marketing (Immediate)**

### **7.1 Social Media**
- **LinkedIn**: Share your launch story
- **Twitter**: Tweet about AI document analysis
- **Reddit**: Post in r/startups, r/artificial

### **7.2 Product Hunt**
1. Go to [producthunt.com](https://producthunt.com)
2. Submit RedlineAI
3. Schedule for tomorrow (Tuesday/Wednesday best)

### **7.3 Hacker News**
- Post: "Show HN: I built an AI document analyzer in Rails"
- Include your URL and key features

---

## 📊 **Step 8: Track Progress**

### **8.1 Analytics Setup**
1. Add Google Analytics to your app
2. Track user signups and conversions
3. Monitor document processing success

### **8.2 Key Metrics**
- **Week 1 Goal**: 10 users
- **Week 2 Goal**: 50 users
- **Week 4 Goal**: First paying customer

---

## 🆘 **Troubleshooting**

### **Common Issues**
1. **Database Connection Error**
   - Check DATABASE_URL format
   - Verify Supabase is running

2. **Storage Error**
   - Verify S3 credentials
   - Check bucket permissions

3. **AI API Error**
   - Verify OpenAI API key
   - Check API quota

### **Get Help**
- **Koyeb Docs**: [docs.koyeb.com](https://docs.koyeb.com)
- **Supabase Docs**: [supabase.com/docs](https://supabase.com/docs)
- **Rails Deployment**: [guides.rubyonrails.org](https://guides.rubyonrails.org)

---

## 🎯 **Success Checklist**

- [ ] App deployed to Koyeb
- [ ] Database connected and migrated
- [ ] Storage working
- [ ] AI analysis functional
- [ ] Subscription system working
- [ ] Custom domain configured
- [ ] Analytics tracking
- [ ] First marketing post published
- [ ] Product Hunt submission ready

---

## 💰 **Next Steps After Deployment**

1. **Day 1**: Share on social media
2. **Day 2**: Submit to Product Hunt
3. **Day 3**: Post on Hacker News
4. **Week 1**: Write first blog post
5. **Week 2**: Start Google Ads ($50/day)
6. **Week 3**: Create case studies
7. **Week 4**: Optimize conversion funnel

---

**Remember**: Perfect is the enemy of good. Deploy first, optimize later. Your first 10 users will give you invaluable feedback for improvements.

**Good luck! 🚀**
