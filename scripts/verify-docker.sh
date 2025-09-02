#!/bin/bash

# Container Verification Script for Pages CMS
# This script helps verify that the Docker setup is working correctly

set -e

echo "🐳 Pages CMS Container Verification Script"
echo "=========================================="

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed or not in PATH"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are available"

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo "⚠️  .env.local not found. Creating from example..."
    cp .env.local.example .env.local
    echo "📝 Please edit .env.local with your GitHub App credentials before running containers"
fi

# Validate Docker Compose configurations
echo "🔍 Validating Docker Compose configurations..."

if docker-compose config --quiet; then
    echo "✅ docker-compose.yml is valid"
else
    echo "❌ docker-compose.yml has syntax errors"
    exit 1
fi

if docker-compose -f docker-compose.dev.yml config --quiet; then
    echo "✅ docker-compose.dev.yml is valid"
else
    echo "❌ docker-compose.dev.yml has syntax errors"
    exit 1
fi

# Check environment variables
echo "🔍 Checking required environment variables..."

source .env.local

required_vars=("CRYPTO_KEY" "GITHUB_APP_ID" "GITHUB_APP_NAME" "GITHUB_APP_PRIVATE_KEY" "GITHUB_APP_WEBHOOK_SECRET" "GITHUB_APP_CLIENT_ID" "GITHUB_APP_CLIENT_SECRET" "RESEND_API_KEY" "RESEND_FROM_EMAIL" "CRON_SECRET")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ] || [ "${!var}" = "your-*" ] || [ "${!var}" = "*-string-of-characters" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "⚠️  The following environment variables need to be configured:"
    for var in "${missing_vars[@]}"; do
        echo "   - $var"
    done
    echo "📖 See DOCKER.md for setup instructions"
else
    echo "✅ All required environment variables are configured"
fi

echo ""
echo "🚀 Ready to start containers!"
echo ""
echo "Development (SQLite):"
echo "  docker-compose -f docker-compose.dev.yml up -d"
echo ""
echo "Production-like (PostgreSQL):"
echo "  docker-compose up -d"
echo ""
echo "📖 For detailed instructions, see DOCKER.md"