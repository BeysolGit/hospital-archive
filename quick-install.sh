#!/bin/bash

# 🏥 Hospital Photo Archive - Super Kolay Kurulum
# Tek komut: bash quick-install.sh
# Sistem 5 dakikada hazır!

set -e

clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🏥 Hospital Photo Archive - SUPER KOLAY KURULUM          ║"
echo "║                                                            ║"
echo "║   Sistemin kurulumu başlıyor... (5-10 dakika)            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# ADIM 1: ÖN KONTROLLER
# ============================================================================

echo "📋 ADIM 1: Ön Kontroller"
echo "─────────────────────────"

# Docker kontrol
if ! command -v docker &> /dev/null; then
    echo "❌ Docker yüklü değil!"
    echo "   macOS: brew install docker"
    echo "   Veya Docker Desktop indir: https://www.docker.com/products/docker-desktop"
    exit 1
fi
echo "✅ Docker var"

# Docker daemon kontrol
if ! docker ps &> /dev/null; then
    echo "❌ Docker daemon çalışmıyor!"
    echo "   Docker Desktop'ı aç ve tekrar dene"
    exit 1
fi
echo "✅ Docker daemon çalışıyor"

# jq kontrol (JSON parsing için)
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq yüklü değil (opsiyonel, test için gerekli)"
    echo "   macOS: brew install jq"
fi

echo ""

# ============================================================================
# ADIM 2: KLASÖRLERI OLUŞTUR
# ============================================================================

echo "📁 ADIM 2: Klasörleri Oluştur"
echo "─────────────────────────────"

mkdir -p photos/{immich,archive,unmatched,external}
mkdir -p logs
echo "✅ Klasörler oluşturuldu: photos/ ve logs/"

echo ""

# ============================================================================
# ADIM 3: .ENV DOSYASINI KONFIGÜRE ET
# ============================================================================

echo "⚙️  ADIM 3: Konfigürasyon"
echo "──────────────────────────"

# OpenRouter API Key sor
if grep -q "your-openrouter-api-key-here" .env 2>/dev/null; then
    echo ""
    echo "🔑 OpenRouter API Key gerekli!"
    echo "   https://openrouter.ai/keys → Create key"
    echo ""
    read -p "   OpenRouter API Key'ini yapıştır: " OPENROUTER_KEY

    if [ -z "$OPENROUTER_KEY" ]; then
        echo "❌ API key boş! Kurulum iptal edildi."
        exit 1
    fi

    # .env güncelle
    sed -i.bak "s/your-openrouter-api-key-here/$OPENROUTER_KEY/" .env
    rm -f .env.bak
    echo "✅ OpenRouter API Key kaydedildi"
else
    echo "✅ OpenRouter API Key zaten yapılandırılmış"
fi

echo ""

# ============================================================================
# ADIM 4: DOCKER SERVISLERINI BAŞLAT
# ============================================================================

echo "🐳 ADIM 4: Docker Servislerini Başlat"
echo "────────────────────────────────────"

echo "   Pulling images... (ilk defa biraz uzun sürebilir)"
docker compose pull --quiet || true

echo "   Başlatılıyor..."
docker compose up -d

echo "✅ Servisler başlatıldı"

echo ""

# ============================================================================
# ADIM 5: SERVİSLERİN HAZIR OLMASINI BEKLE
# ============================================================================

echo "⏳ ADIM 5: Servisler Başlamasını Bekle"
echo "──────────────────────────────────────"

# Immich
echo -n "   📸 Immich..."
for i in {1..60}; do
    if docker compose exec -T immich-server curl -sf http://localhost:3001/api/server/ping &>/dev/null; then
        echo " ✅"
        break
    fi
    echo -n "."
    sleep 1
done

# barcode-service
echo -n "   🔍 Barcode Service..."
for i in {1..60}; do
    if docker compose exec -T barcode-service curl -sf http://localhost:5000/health &>/dev/null; then
        echo " ✅"
        break
    fi
    echo -n "."
    sleep 1
done

# n8n
echo -n "   ⚙️  n8n..."
for i in {1..60}; do
    if docker compose exec -T n8n curl -sf http://localhost:5678/healthz &>/dev/null; then
        echo " ✅"
        break
    fi
    echo -n "."
    sleep 1
done

echo ""

# ============================================================================
# ADIM 6: IMMICH API KEY'İ AL VE KAYDET
# ============================================================================

echo "🔑 ADIM 6: Immich API Key'i Al"
echo "──────────────────────────────"

echo ""
echo "   Immich web UI açılıyor: http://localhost:2283"
echo ""
echo "   🖥️  Tarayıcıda:"
echo "   1. Admin hesap oluştur (herhangi email/şifre)"
echo "   2. Settings → Account → API Keys → Create New Key"
echo "   3. Kopyala ve aşağıya yapıştır"
echo ""

read -p "   Immich API Key'ini yapıştır: " IMMICH_KEY

if [ -z "$IMMICH_KEY" ]; then
    echo "❌ API key boş! Daha sonra .env dosyasından ayarla:"
    echo "   IMMICH_API_KEY=<your-key>"
else
    sed -i.bak "s/IMMICH_API_KEY=.*/IMMICH_API_KEY=$IMMICH_KEY/" .env
    rm -f .env.bak
    echo "✅ Immich API Key kaydedildi"

    # n8n'i restart et (API key değişti)
    echo ""
    echo "   n8n yeniden başlatılıyor..."
    docker compose restart n8n &>/dev/null
    sleep 10
    echo "✅ n8n restart'ı tamamlandı"
fi

echo ""

# ============================================================================
# ADIM 7: TEST VER
# ============================================================================

echo "🧪 ADIM 7: Hızlı Test"
echo "────────────────────"

echo ""
echo "   Barcode Service health check..."

if docker compose exec -T barcode-service curl -sf http://localhost:5000/health &>/dev/null; then
    echo "   ✅ Barcode Service: OK"
else
    echo "   ⚠️  Barcode Service: Kontrol et"
fi

echo ""
echo "   Docker container'ları:"
docker compose ps --format "table {{.Names}}\t{{.Status}}" | sed 's/^/   /'

echo ""

# ============================================================================
# ADIM 8: NEXTTT STEPS
# ============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  ✅ KURULUM TAMAMLANDI!                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "🌐 Web UI'lar (Hemen aç!):"
echo "   📸 Immich:  http://localhost:2283"
echo "   ⚙️  n8n:     http://localhost:5678"
echo "   📚 API Docs: http://localhost:5001/docs"
echo ""

echo "📋 ÖNEMLİ ADIMLAR:"
echo "   1️⃣  Immich'i aç → Ayarları kontrol et"
echo "   2️⃣  Test et:"
echo "       bash test.sh"
echo ""
echo "   3️⃣  Test verisi oluştur:"
echo "       bash create_test_data.sh"
echo ""
echo "   4️⃣  n8n workflow'larını import et:"
echo "       Workflows → Import From File"
echo "       Seç: n8n-workflows/01_poll_and_route.json"
echo ""

echo "📚 Dokumentasyon:"
echo "   Tüm bilgi: README.md"
echo "   Hızlı test: TESTING_QUICK_START.md"
echo "   Detaylı: SYSTEM_OVERVIEW.md"
echo ""

echo "🔗 Mobil (iPhone/Android):"
echo "   Immich App indir"
echo "   Server: http://<bilgisayar-ip>:2283"
echo "   WiFi-only backup aktif et"
echo ""

echo "💡 İlk Test (5 dakika):"
echo "   bash create_test_data.sh"
echo "   bash test.sh"
echo ""

echo "❌ Sorun varsa:"
echo "   docker compose logs barcode-service"
echo "   docker compose logs n8n"
echo "   docker compose logs immich-server"
echo ""

echo "🚀 Hepsi bitti! Şimdi git README.md'yi oku veya test et!"
