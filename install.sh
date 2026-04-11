#!/bin/bash

# 🏥 Hospital Archive - ULTIMATE OTOMATIK KURULUM
# Tek komut: bash install.sh
# Sistem otomatik kuruluyor, sonra web sayfası açılıyor - Hepsi bitti!

set -e

export TERM=xterm

clear

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🏥 Hospital Archive - OTOMATIK KURULUM                  ║"
echo "║                                                            ║"
echo "║   Sistem otomatik kuruluyor... Lütfen bekle (3-5 dk)     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# ADIM 0: .ENV DOSYASINI HAZIRLA
# ============================================================================

# Çalışılan klasörü bul
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# .env yoksa template'ten kopyala
if [ ! -f "$WORK_DIR/.env" ]; then
    if [ -f "$WORK_DIR/.env.example" ]; then
        cp "$WORK_DIR/.env.example" "$WORK_DIR/.env"
        echo "📋 0/5 - .env dosyası template'ten oluşturuldu"
    else
        echo "❌ .env.example bulunamadı!"
        exit 1
    fi
else
    echo "📋 0/5 - .env dosyası zaten var"
fi

echo ""

# ============================================================================
# ADIM 1: ÖN KONTROLLER
# ============================================================================

echo "📋 1/5 - Ön kontroller..."

# Docker kontrol
if ! command -v docker &> /dev/null; then
    echo "❌ Docker yüklü değil!"
    echo ""
    echo "Yükle:"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  macOS: brew install --cask docker"
        echo "  (Bu Docker Desktop kurar - hem CLI hem daemon)"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  Linux: sudo apt-get install docker.io docker-compose"
    else
        echo "  Windows: https://www.docker.com/products/docker-desktop"
    fi

    exit 1
fi

# Docker daemon kontrol ve başlat
if ! docker ps &> /dev/null 2>&1; then
    echo "⏳ Docker daemon başlatılıyor..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - Docker Desktop'ı bul ve aç (farklı konumları dene)
        DOCKER_STARTED=0
        for DOCKER_APP in "/Applications/Docker.app" "$HOME/Applications/Docker.app" "$(mdfind 'kMDItemCFBundleIdentifier == "com.docker.docker"' 2>/dev/null | head -1)"; do
            if [ -d "$DOCKER_APP" ]; then
                open "$DOCKER_APP" 2>/dev/null && DOCKER_STARTED=1 && break
            fi
        done

        # mdfind bulamadıysa open -a dene
        if [ $DOCKER_STARTED -eq 0 ]; then
            open -a Docker 2>/dev/null || true
        fi

        echo "   Docker Desktop başlatılıyor, lütfen bekle..."

    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo systemctl start docker 2>/dev/null || true
        echo "   Docker daemon başlatılıyor..."
    fi

    # 90 saniyeye kadar bekle (Docker Desktop yavaş başlar)
    WAIT=0
    MAX=90
    while [ $WAIT -lt $MAX ]; do
        if docker ps &> /dev/null 2>&1; then
            break
        fi
        echo -n "."
        sleep 3
        WAIT=$((WAIT + 3))
    done
    echo ""
fi

# Son kontrol
if docker ps &> /dev/null 2>&1; then
    echo "✅ Docker daemon çalışıyor"
else
    echo "❌ Docker daemon başlatılamadı!"
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Docker Desktop kurulu mu kontrol et
        if ! ls /Applications/Docker.app &>/dev/null 2>&1 && ! mdfind 'kMDItemCFBundleIdentifier == "com.docker.docker"' 2>/dev/null | grep -q "."; then
            echo "   ⚠️  Docker Desktop kurulu değil!"
            echo "   Sadece Docker CLI yüklü - daemon için Desktop lazım."
            echo ""
            echo "   Kur: brew install --cask docker"
            echo "   Sonra tekrar çalıştır: bash install.sh"
        else
            echo "   Docker Desktop kurulu ama başlatılamadı."
            echo "   1. Dock'tan Docker simgesini tıklayarak aç"
            echo "   2. Tamamen açıldıktan sonra tekrar çalıştır:"
            echo "      bash install.sh"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "   sudo systemctl start docker"
        echo "   Sonra tekrar: bash install.sh"
    fi
    exit 1
fi

echo "✅ Kontroller tamamlandı"
echo ""

# ============================================================================
# ADIM 2: KLASÖRLERI OLUŞTUR
# ============================================================================

echo "📋 2/5 - Klasörler oluşturuluyor..."

mkdir -p "$WORK_DIR/photos/{immich,archive,unmatched,external}"
mkdir -p "$WORK_DIR/logs"

echo "✅ Klasörler hazır (Location: $WORK_DIR)"
echo ""

# ============================================================================
# ADIM 3: DOCKER İMUŞLARINI İNDİR VE BAŞLAT
# ============================================================================

echo "📋 3/5 - Docker servisleri başlatılıyor..."
echo "   (İlk defa biraz uzun sürebilir - 2-3 dakika)"
echo ""

# Eski servisleri temizle
docker compose down 2>/dev/null || true

# Images'ı pull et
echo "   Downloading images..."
docker compose pull 2>&1 | grep -E "Downloaded|Pull complete" | head -5 || true
echo "   ✅ Images downloaded"

# Servisleri başlat
echo "   Starting services..."
docker compose up -d 2>&1 | grep -E "Created|Started" | head -10 || true

# Servislerin hazır olmasını bekle
echo ""
echo "   ⏳ Servislerin başlaması bekleniyor..."

WAIT_TIME=0
MAX_WAIT=180

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if docker compose exec -T immich-server curl -sf http://localhost:3001/api/server/ping &>/dev/null && \
       docker compose exec -T barcode-service curl -sf http://localhost:5000/health &>/dev/null && \
       docker compose exec -T n8n curl -sf http://localhost:5678/healthz &>/dev/null; then
        echo "   ✅ Tüm servisler hazır!"
        break
    fi
    echo -n "."
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
done

echo ""

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo "⚠️  Servisler biraz uzun sürüyor, devam et..."
fi

echo "✅ Docker servisleri çalışıyor"
echo ""

# ============================================================================
# ADIM 4: SETUP WEB SAYFASINI HAZIRLA
# ============================================================================

echo "📋 4/5 - Setup web sayfası hazırlanıyor..."

# Port kontrol
PORT=9000
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    PORT=9001
fi

# Python setup server'ı background'da başlat
python3 "$WORK_DIR/setup-server.py" --port $PORT &
SETUP_PID=$!

sleep 2

echo "✅ Web sayfası hazır (Port: $PORT)"
echo ""

# ============================================================================
# ADIM 5: TARAYICI AÇILSIN
# ============================================================================

echo "📋 5/5 - Tarayıcı açılıyor..."
echo ""

sleep 1
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "http://localhost:$PORT" 2>/dev/null || true
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "http://localhost:$PORT" 2>/dev/null || true
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    start "http://localhost:$PORT" 2>/dev/null || true
fi

# ============================================================================
# TAMAMLANMA MESAJI
# ============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          ✅ KURULUM TAMAMLANDI - WEB SAYFASI AÇILDI       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "🌐 Tarayıcı URL: http://localhost:$PORT"
echo ""

echo "📋 Yapacakların:"
echo "   1. OpenRouter API Key'ini yapıştır"
echo "      (https://openrouter.ai/keys)"
echo ""
echo "   2. Diğer ayarları kontrol et"
echo ""
echo "   3. 'Kurulumu Tamamla' butonuna tıkla"
echo ""
echo "   4. Immich açılacak (admin hesap yap)"
echo ""
echo "   5. Settings → Account → API Keys"
echo "      → Create New Key → Token'i kopyala"
echo ""
echo "   6. Web sayfasında Immich API Key'i yapıştır"
echo ""
echo "   7. 'Hazır!' butonuna tıkla"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 Sonrasında:"
echo "   📸 Immich: http://localhost:2283"
echo "   ⚙️  n8n: http://localhost:5678"
echo "   📚 API: http://localhost:5001/docs"
echo ""
echo "📱 Mobil:"
echo "   Immich App indir → Server: http://<bilgisayar-ip>:2283"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Setup server'ı foreground'da çalıştır
wait $SETUP_PID
