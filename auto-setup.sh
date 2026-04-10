#!/bin/bash

# 🏥 Hospital Archive - ULTRA OTOMATIK KURULUM
# Hiçbir input gerekli değil - sadece çalıştır!
# bash auto-setup.sh

set -e

clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     🏥 Hospital Photo Archive - ULTRA OTOMATIK KURULUM     ║"
echo "║                                                            ║"
echo "║     ADIM 1: OpenRouter API Key (zorunlu)                 ║"
echo "║     ADIM 2: Sistem otomatik kurulacak                    ║"
echo "║     ADIM 3: Immich API Key web UI'dan alacaksın          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# ADIM 1: OPENROUTER API KEY
# ============================================================================

echo "🔑 ADIM 1: OpenRouter API Key"
echo "─────────────────────────────"
echo ""
echo "OpenRouter'dan API Key almak için:"
echo "  1. https://openrouter.ai/keys açılıyor..."
echo "  2. 'Create Key' butonuna tıkla"
echo "  3. Token'i kopyala"
echo ""

read -p "▸ OpenRouter API Key'ini yapıştır: " OPENROUTER_KEY

if [ -z "$OPENROUTER_KEY" ]; then
    echo "❌ API key boş!"
    exit 1
fi

# .env güncelle
cp .env .env.backup 2>/dev/null || true
sed -i.bak "s|your-openrouter-api-key-here|$OPENROUTER_KEY|" .env
rm -f .env.bak
echo "✅ OpenRouter API Key kaydedildi"

echo ""

# ============================================================================
# ADIM 2: DOCKER SETUP
# ============================================================================

echo "🚀 ADIM 2: Sistem Kuruluyor"
echo "──────────────────────────"

# Docker kontrol
if ! command -v docker &> /dev/null; then
    echo "❌ Docker yüklü değil!"
    exit 1
fi

# Klasörleri oluştur
mkdir -p photos/{immich,archive,unmatched,external}
mkdir -p logs
echo "   ✅ Klasörler oluşturuldu"

# Docker servisleri başlat
echo "   🐳 Docker servisleri başlatılıyor..."
docker compose up -d 2>/dev/null

# Servislerin hazır olmasını bekle
echo "   ⏳ Bekleniyor (1-2 dakika)..."
sleep 5

services=("immich-server" "barcode-service" "n8n")
for service in "${services[@]}"; do
    echo -n "      $service..."
    for i in {1..60}; do
        if docker compose ps "$service" 2>/dev/null | grep -q "Up"; then
            echo " ✅"
            break
        fi
        echo -n "."
        sleep 1
    done
done

echo "   ✅ Tüm servisler çalışıyor"

echo ""

# ============================================================================
# ADIM 3: IMMICH API KEY
# ============================================================================

echo "📸 ADIM 3: Immich API Key'i Al"
echo "──────────────────────────────"
echo ""
echo "⚠️  Tarayıcında açılacak → Admin hesap oluştur"
echo ""

sleep 2

# macOS'ta tarayıcıyı aç
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "http://localhost:2283" 2>/dev/null || true
fi

echo "Bekleniyor (Immich yükleniyor)..."
for i in {1..30}; do
    if docker compose exec -T immich-server curl -sf http://localhost:3001/api/server/ping &>/dev/null; then
        echo "✅ Immich ready"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""
echo "🖥️  Tarayıcıda:"
echo "  1. Admin hesap oluştur (email + şifre)"
echo "  2. Settings → Account → API Keys"
echo "  3. 'Create New Key' → Copy"
echo "  4. Aşağıya yapıştır"
echo ""

read -p "▸ Immich API Key'ini yapıştır (isteğe bağlı): " IMMICH_KEY

if [ -n "$IMMICH_KEY" ]; then
    sed -i.bak "s|IMMICH_API_KEY=.*|IMMICH_API_KEY=$IMMICH_KEY|" .env
    rm -f .env.bak
    echo "✅ Immich API Key kaydedildi"

    # n8n restart
    docker compose restart n8n 2>/dev/null
    sleep 5
    echo "✅ n8n yeniden başlatıldı"
else
    echo "⚠️  Daha sonra .env'den ayarlanabilir"
fi

echo ""

# ============================================================================
# TAMAMLANMA MESAJI
# ============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✅ KURULUM TAMAMLANDI - GİDİ!                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "🌐 Şu an çalışan sistemler:"
echo "   📸 Immich:       http://localhost:2283"
echo "   ⚙️  n8n:          http://localhost:5678"
echo "   🔍 Barcode API:   http://localhost:5001/docs"
echo ""

echo "▶️  İLK TEST (5 dakika):"
echo "   $ bash create_test_data.sh"
echo "   $ bash test.sh"
echo ""

echo "▶️  n8n Workflow'larını Import Et:"
echo "   1. http://localhost:5678 aç"
echo "   2. Workflows → Import From File"
echo "   3. Seç: n8n-workflows/01_poll_and_route.json"
echo ""

echo "📚 Daha Fazla:"
echo "   $ cat README.md          (Tüm bilgi)"
echo "   $ cat QUICKSTART.md       (Hızlı start)"
echo ""

echo "🎉 Sistem hazır! Başarısız olursa haber ver!"
echo ""
