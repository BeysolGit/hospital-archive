#!/bin/bash

# Foto Arsiv - Komple Kaldirma
# Tek komut: bash uninstall.sh

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Foto Arsiv - KALDIRMA                                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Bu islem sunlari silecek:"
echo "  - Tum Docker containerlari (immich, n8n, barcode-service)"
echo "  - Tum Docker volumeleri (veritabani, yuklemeler)"
echo "  - Tum Docker imajlari (indirilen dosyalar)"
echo "  - fotograf-arsivleme network"
echo ""

# Onay iste
read -p "Devam etmek istiyor musun? (e/h): " CONFIRM
if [[ "$CONFIRM" != "e" && "$CONFIRM" != "E" && "$CONFIRM" != "evet" ]]; then
    echo "Iptal edildi."
    exit 0
fi

echo ""

WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Containerlari durdur ve sil
echo "1/4 - Containerlar durduruluyor..."
cd "$WORK_DIR"
docker compose down --volumes --remove-orphans 2>/dev/null || true
echo "  Containerlar ve volumeler silindi"

# 2. Build edilen imajlari sil
echo "2/4 - Docker imajlari siliniyor..."
docker rmi fotograf-arsivleme-barcode-service 2>/dev/null || true
docker rmi ghcr.io/immich-app/immich-server:release 2>/dev/null || true
docker rmi tensorchord/pgvecto-rs:pg16-v0.2.1 2>/dev/null || true
docker rmi redis:7-alpine 2>/dev/null || true
docker rmi n8nio/n8n:latest 2>/dev/null || true
echo "  Imajlar silindi"

# 3. Olusturulan klasorleri sil
echo "3/4 - Veri klasorleri siliniyor..."
rm -rf "$WORK_DIR/photos" 2>/dev/null || true
rm -rf "$WORK_DIR/logs" 2>/dev/null || true
rm -f "$WORK_DIR/.env" 2>/dev/null || true
echo "  Klasorler silindi"

# 4. Setup server'i durdur
echo "4/4 - Setup servisleri durduruluyor..."
pkill -f "setup-server.py" 2>/dev/null || true
echo "  Servisler durduruldu"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Foto Arsiv tamamen kaldirildi!                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Proje klasorunu de silmek istersen:"
echo "  cd .. && rm -rf $(basename "$WORK_DIR")"
echo ""
