# Running Pages CMS with Docker

This guide explains how to run Pages CMS locally using Docker containers, with support for both development and production setups.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- [GitHub App](#github-app-setup) configured for Pages CMS
- [Resend account](https://resend.com) for email functionality

## Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/pages-cms/pages-cms.git
cd pages-cms
cp .env.local.example .env.local
```

### 2. Configure Environment Variables

Edit `.env.local` with your GitHub App and Resend credentials:

```bash
# Required GitHub App configuration
CRYPTO_KEY="your-32-character-encryption-key"
GITHUB_APP_ID="123456"
GITHUB_APP_NAME="your-app-name"
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----..."
GITHUB_APP_WEBHOOK_SECRET="your-webhook-secret"
GITHUB_APP_CLIENT_ID="Iv1.your-client-id"
GITHUB_APP_CLIENT_SECRET="your-client-secret"

# Required email configuration
RESEND_API_KEY="re_your-api-key"
RESEND_FROM_EMAIL="Pages CMS <noreply@yourdomain.com>"

# Security
CRON_SECRET="your-cron-secret"
```

### 3. Run with Docker Compose

**Option A: Development (SQLite database)**
```bash
docker-compose -f docker-compose.dev.yml up -d
```

**Option B: Production-like (PostgreSQL database)**
```bash
docker-compose up -d
```

### 4. Access the Application

Open your browser to [http://localhost:3000](http://localhost:3000)

## Container Options

### Development Setup (`docker-compose.dev.yml`)

- Uses SQLite database (file-based, no separate database container)
- Data persists in `./local.db` file
- Lighter resource usage
- Perfect for local development and testing

```bash
# Start development containers
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop containers
docker-compose -f docker-compose.dev.yml down
```

### Production Setup (`docker-compose.yml`)

- Uses PostgreSQL database in separate container
- Production-grade database with persistent volumes
- Includes database health checks
- Better for production-like testing

```bash
# Start production containers
docker-compose up -d

# View logs
docker-compose logs -f

# Stop containers and remove volumes
docker-compose down -v
```

## GitHub App Setup

Pages CMS requires a GitHub App for authentication and repository access. Here's how to set it up for container usage:

### 1. Create GitHub App

Go to GitHub Settings → Developer settings → GitHub Apps → New GitHub App

**Required Settings:**
- **GitHub App name**: `Pages CMS Local` (or similar)
- **Homepage URL**: `https://pagescms.org`
- **Callback URL**: `http://localhost:3000/api/auth/github`
- **Webhook URL**: `https://your-ngrok-url.ngrok.io/api/webhook/github` (see [Webhook Setup](#webhook-setup))
- **Webhook Secret**: Generate a random string

**Permissions:**
- Repository permissions:
  - Administration: Read & Write
  - Contents: Read & Write
  - Metadata: Read only

**Subscribe to events:**
- Installation target
- Repository
- Push
- Delete

### 2. Webhook Setup for Local Development

Since containers run locally, you'll need to expose the webhook endpoint to GitHub:

**Using ngrok (recommended):**
```bash
# Install ngrok: https://ngrok.com/
# Start your containers first
docker-compose -f docker-compose.dev.yml up -d

# In another terminal, expose port 3000
ngrok http 3000

# Use the ngrok URL in your GitHub App webhook settings
# Example: https://abc123.ngrok.io/api/webhook/github
```

### 3. Get App Credentials

After creating the GitHub App:
1. Note the **App ID** and **Client ID**
2. Generate and download the **Private Key** (PEM file)
3. Generate a **Client Secret**
4. Copy these values to your `.env.local` file

## Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `CRYPTO_KEY` | ✅ | Encryption key for GitHub tokens | Generate with `openssl rand -base64 32` |
| `GITHUB_APP_ID` | ✅ | GitHub App ID | `123456` |
| `GITHUB_APP_NAME` | ✅ | GitHub App machine name | `pages-cms-local` |
| `GITHUB_APP_PRIVATE_KEY` | ✅ | GitHub App private key (PEM format) | `-----BEGIN RSA PRIVATE KEY-----...` |
| `GITHUB_APP_WEBHOOK_SECRET` | ✅ | Webhook secret | Generate random string |
| `GITHUB_APP_CLIENT_ID` | ✅ | GitHub App Client ID | `Iv1.abc123...` |
| `GITHUB_APP_CLIENT_SECRET` | ✅ | GitHub App Client Secret | `abc123...` |
| `RESEND_API_KEY` | ✅ | Resend API key for emails | `re_abc123...` |
| `RESEND_FROM_EMAIL` | ✅ | From email address | `Pages CMS <noreply@yourdomain.com>` |
| `CRON_SECRET` | ✅ | Secret for cron endpoint | Generate random string |
| `DATABASE_URL` | ✅ | Database connection string | Set automatically in compose files |
| `BASE_URL` | ❌ | Base URL for the app | `http://localhost:3000` (default) |
| `FILE_CACHE_TTL` | ❌ | File cache TTL in minutes | `1440` (default) |
| `PERMISSION_CACHE_TTL` | ❌ | Permission cache TTL in minutes | `60` (default) |

## Useful Commands

```bash
# View container logs
docker-compose logs -f app

# Execute commands in the app container
docker-compose exec app npm run db:migrate

# Restart just the app container
docker-compose restart app

# Remove all containers and data
docker-compose down -v

# Rebuild containers after code changes
docker-compose build --no-cache
docker-compose up -d
```

## Troubleshooting

### Container Won't Start
- Check that port 3000 isn't already in use
- Verify all required environment variables are set
- Check container logs: `docker-compose logs app`

### Database Connection Issues
- Ensure PostgreSQL container is healthy: `docker-compose ps`
- Check database logs: `docker-compose logs postgres`
- Verify DATABASE_URL is correctly set

### GitHub Authentication Issues
- Verify GitHub App callback URL matches container URL
- Check that all GitHub App credentials are correct
- Ensure webhook URL is accessible (use ngrok for local dev)

### Permission Issues
- Ensure the GitHub App has proper repository permissions
- Check that the app is installed on the target repositories

## Production Deployment

For production deployment with containers:

1. Use a proper domain name instead of localhost
2. Set up SSL/TLS termination (reverse proxy like nginx)
3. Use a managed PostgreSQL service instead of container database
4. Set proper webhook URL in GitHub App settings
5. Use container orchestration (Kubernetes, Docker Swarm) for reliability

Example production environment variables:
```bash
BASE_URL="https://cms.yourdomain.com"
DATABASE_URL="postgresql://user:pass@prod-db.example.com:5432/pagescms"
```

## Apple Silicon / ARM64 Support

The containers are built with multi-platform support and work on:
- Apple Silicon Macs (M1/M2)
- Intel/AMD64 systems
- ARM64 Linux systems

If you encounter platform-specific issues, you can force the platform:
```bash
docker-compose build --platform linux/amd64
```