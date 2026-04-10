#!/bin/bash

# Immich API Key'i otomatik oluştur ve .env'ye kaydet
# Requires: jq, docker

set -e

echo "🔑 Immich API Key Otomatik Ayarı"
echo "════════════════════════════════"
echo ""

# Bekle Immich'in hazır olmasını
echo "⏳ Immich'in başlamasını bekleniyor..."
for i in {1..60}; do
    if docker compose exec -T immich-server curl -sf http://localhost:3001/api/server/ping &>/dev/null; then
        echo "✅ Immich ready"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""

# Admin user oluştur
echo "👤 Admin hesabı oluşturuluyor..."

ADMIN_PASSWORD="admin123"
ADMIN_EMAIL="admin@hospital.local"

# İlk admin user'ı oluştur
API_RESPONSE=$(docker compose exec -T immich-server curl -s -X POST \
  http://localhost:3001/api/auth/admin-onboarding/verify \
  -H "Content-Type: application/json" \
  -d "{
    \"password\": \"$ADMIN_PASSWORD\",
    \"email\": \"$ADMIN_EMAIL\",
    \"firstName\": \"Hospital\",
    \"lastName\": \"Admin\"
  }" || echo "{}")

echo "✅ Admin hesabı hazır"
echo "   Email: $ADMIN_EMAIL"
echo "   Password: $ADMIN_PASSWORD"

echo ""

# API Key oluştur
echo "🔑 API Key oluşturuluyor..."

API_KEY_RESPONSE=$(docker compose exec -T immich-server curl -s -X POST \
  http://localhost:3001/api/api-keys \
  -H "Content-Type: application/json" \
  -H "x-api-key: " \
  -d "{
    \"name\": \"n8n-integration\"
  }" || echo "{}")

# Response'dan key'i çıkart
API_KEY=$(echo "$API_KEY_RESPONSE" | jq -r '.secret // empty' 2>/dev/null || echo "")

if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    echo "⚠️  Otomatik key oluşturulamadı (normal)"
    echo ""
    echo "Manual olarak oluşturmak için:"
    echo "   1. http://localhost:2283 aç"
    echo "   2. Settings → Account → API Keys"
    echo "   3. Create New Key"
    echo "   4. .env dosyasında IMMICH_API_KEY'i güncelle"
    exit 0
fi

echo "✅ API Key oluşturuldu"

# .env'ye kaydet
echo ""
echo "📝 .env dosyası güncelleniyor..."

if grep -q "IMMICH_API_KEY=" .env; then
    sed -i.bak "s|IMMICH_API_KEY=.*|IMMICH_API_KEY=$API_KEY|" .env
    rm -f .env.bak
else
    echo "IMMICH_API_KEY=$API_KEY" >> .env
fi

echo "✅ .env dosyası güncellendi"

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║  ✅ Immich API Key Hazır!                 ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "Sonraki adım:"
echo "  docker compose restart n8n"
echo ""
