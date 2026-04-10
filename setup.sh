#!/bin/bash

# Hospital Photo Archiving System - Quick Setup Script

set -e

echo "🏥 Hospital Photo Archive System - Setup"
echo "=========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

echo "✅ Docker found"

# Create necessary directories
echo ""
echo "📁 Creating directories..."
mkdir -p photos/{immich,archive,unmatched,external}
chmod 777 photos/*
echo "✅ Directories created"

# Check if .env exists
echo ""
if [ ! -f .env ]; then
    echo "⚠️  .env file not found"
    echo "Please copy .env.example to .env and fill in your values:"
    echo "  - UPLOAD_LOCATION"
    echo "  - ARCHIVE_PATH"
    echo "  - OPENROUTER_API_KEY"
    echo "  - IMMICH_API_KEY (get from Immich web UI after first startup)"
    exit 1
fi

echo "✅ .env file found"

# Parse .env
if grep -q "OPENROUTER_API_KEY=your-openrouter-api-key-here" .env; then
    echo "⚠️  Please update OPENROUTER_API_KEY in .env"
fi

echo ""
echo "🐳 Starting Docker containers..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to be healthy..."

# Wait for Immich
echo -n "  Waiting for Immich..."
for i in {1..30}; do
    if docker exec immich-server curl -f http://localhost:3001/api/server/ping &> /dev/null; then
        echo " ✅"
        break
    fi
    echo -n "."
    sleep 2
done

# Wait for barcode-service
echo -n "  Waiting for barcode-service..."
for i in {1..30}; do
    if docker exec barcode-service curl -f http://localhost:5000/health &> /dev/null; then
        echo " ✅"
        break
    fi
    echo -n "."
    sleep 2
done

# Wait for n8n
echo -n "  Waiting for n8n..."
for i in {1..30}; do
    if docker exec n8n wget -q --spider http://localhost:5678/healthz &> /dev/null; then
        echo " ✅"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""
echo "✅ All services are running!"
echo ""
echo "📋 Next Steps:"
echo "  1. Open Immich: http://localhost:2283"
echo "  2. Create admin account on first login"
echo "  3. Go to Account Settings → API Keys → Create new key"
echo "  4. Update IMMICH_API_KEY in .env"
echo "  5. Restart n8n: docker compose restart n8n"
echo "  6. Open n8n: http://localhost:5678"
echo "  7. Import workflows from n8n-workflows/ folder"
echo "  8. Enable and configure workflows"
echo ""
echo "📱 For mobile sync:"
echo "  1. Install Immich app on iPhone/Android"
echo "  2. Connect to: http://<your-ip>:2283"
echo "  3. Enable WiFi-only backup in settings"
echo ""
echo "🔗 API Documentation:"
echo "  Barcode Service: http://localhost:5001/docs"
echo ""
echo "📖 For detailed instructions, see README.md"
