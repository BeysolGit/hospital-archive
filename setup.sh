#!/bin/bash

# Fotograf Arsivleme - KOLAY KURULUM
# Web tabanı kurulum arayüzü ile tüm ayarları yap

set -e

export TERM=xterm

clear

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Fotograf Arsivleme - WEB KURULUM                       ║"
echo "║                                                            ║"
echo "║   Tarayıcıdan tüm ayarları yap - Basit ve güvenli        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Docker kontrol
echo "📋 Ön kontroller yapılıyor..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker yüklü değil!"
    echo "   macOS: brew install docker"
    echo "   https://www.docker.com/products/docker-desktop"
    exit 1
fi

echo "✅ Docker var"
echo ""

# Klasörleri oluştur
echo "📁 Klasörler oluşturuluyor..."
mkdir -p photos/{immich,archive,unmatched,external}
mkdir -p logs
echo "✅ Klasörler oluşturuldu"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🌐 WEB KURULUM ARAYÜZÜ AÇILIYOR                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Port kontrol
PORT=9000
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port $PORT kullanımda (başka kurulum var?)"
    read -p "   Farklı port ister misin? (Enter = $PORT): " NEW_PORT
    if [ -n "$NEW_PORT" ]; then
        PORT=$NEW_PORT
    fi
fi

# Setup server'ı başlat
echo "🚀 Setup server başlatılıyor..."
python3 setup-server.py --port $PORT &
SERVER_PID=$!

# Tarayıcıyı aç
sleep 2

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Kurulum web arayüzü başlatıldı!"
echo ""
echo "🌐 Tarayıcını aç:"
echo "   http://localhost:$PORT"
echo ""
echo "⏰ Otomatik açılmaya çalışılıyor..."
echo ""

# macOS'ta tarayıcı aç
if [[ "$OSTYPE" == "darwin"* ]]; then
    sleep 1
    open "http://localhost:$PORT" 2>/dev/null || true
fi

echo "📋 Yapacakların:"
echo "   1. OpenRouter API Key'i yapıştır (https://openrouter.ai/keys)"
echo "   2. Diğer ayarları kontrol et"
echo "   3. 'Kurulumu Başlat' butonuna tıkla"
echo "   4. Docker servisleri otomatik başlayacak (2-3 dakika)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⏹  Çıkmak için: Ctrl+C"
echo ""

# Server'ı çalıştır (foreground)
wait $SERVER_PID
