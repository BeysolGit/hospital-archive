#!/bin/bash

# 🏥 Hospital Archive - Otomatik Bağımlılık Kurulumu
# Tüm gerekli yazılımları otomatik kur

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🔧 BAĞIMLILIKLARI KURULTURUYOR                          ║"
echo "║                                                            ║"
echo "║   Docker, Git, Python3 otomatik kurulacak                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Sistem türünü belirle
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    echo "🍎 macOS tespit edildi"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    echo "🐧 Linux tespit edildi"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
    echo "🪟 Windows tespit edildi"
else
    echo "❌ Bilinmeyen işletim sistemi: $OSTYPE"
    exit 1
fi

echo ""

# ============================================================================
# macOS - Homebrew ile kur
# ============================================================================

if [ "$OS" = "macos" ]; then
    echo "📋 macOS Kurulumu"
    echo "─────────────────"
    echo ""

    # Homebrew kontrol
    if ! command -v brew &> /dev/null; then
        echo "📥 Homebrew kurulması gerekiyor..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "✅ Homebrew zaten yüklü"
    fi

    echo ""

    # Docker
    if ! command -v docker &> /dev/null; then
        echo "📦 Docker kurulması gerekiyor..."
        brew install docker
        echo "✅ Docker kuruldu"
    else
        echo "✅ Docker zaten yüklü"
    fi

    # Git
    if ! command -v git &> /dev/null; then
        echo "📦 Git kurulması gerekiyor..."
        brew install git
        echo "✅ Git kuruldu"
    else
        echo "✅ Git zaten yüklü"
    fi

    # Python3
    if ! command -v python3 &> /dev/null; then
        echo "📦 Python3 kurulması gerekiyor..."
        brew install python3
        echo "✅ Python3 kuruldu"
    else
        echo "✅ Python3 zaten yüklü"
    fi

    echo ""
    echo "⚠️  ÖNEMLI: Docker Desktop'ı aç!"
    echo "   Applications → Docker"
    echo "   Başlaması 30 saniye kadar sürebilir"
    echo ""
    read -p "   Docker Desktop'ı açtın mı? (Enter devam etmek için)"

fi

# ============================================================================
# Linux - apt ile kur
# ============================================================================

if [ "$OS" = "linux" ]; then
    echo "📋 Linux Kurulumu (Ubuntu/Debian)"
    echo "─────────────────────────────────"
    echo ""

    echo "📥 Paket listesi güncelleniyor..."
    sudo apt-get update

    # Docker
    if ! command -v docker &> /dev/null; then
        echo "📦 Docker kurulması gerekiyor..."
        sudo apt-get install -y docker.io
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        newgrp docker
        echo "✅ Docker kuruldu"
    else
        echo "✅ Docker zaten yüklü"
    fi

    # Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "📦 Docker Compose kurulması gerekiyor..."
        sudo apt-get install -y docker-compose
        echo "✅ Docker Compose kuruldu"
    else
        echo "✅ Docker Compose zaten yüklü"
    fi

    # Git
    if ! command -v git &> /dev/null; then
        echo "📦 Git kurulması gerekiyor..."
        sudo apt-get install -y git
        echo "✅ Git kuruldu"
    else
        echo "✅ Git zaten yüklü"
    fi

    # Python3
    if ! command -v python3 &> /dev/null; then
        echo "📦 Python3 kurulması gerekiyor..."
        sudo apt-get install -y python3 python3-pip
        echo "✅ Python3 kuruldu"
    else
        echo "✅ Python3 zaten yüklü"
    fi

    echo ""
    echo "✅ Linux kurulumu tamamlandı"

fi

# ============================================================================
# Windows
# ============================================================================

if [ "$OS" = "windows" ]; then
    echo "📋 Windows Kurulumu"
    echo "──────────────────"
    echo ""

    echo "⚠️  Windows'ta manuel kurulum gerekli:"
    echo ""
    echo "1️⃣  Docker Desktop indir:"
    echo "   https://www.docker.com/products/docker-desktop"
    echo "   İndir → Kur → Restart bilgisayarı"
    echo ""
    echo "2️⃣  Git indir:"
    echo "   https://git-scm.com/download/win"
    echo "   İndir → Kur"
    echo ""
    echo "3️⃣  Python indir:"
    echo "   https://www.python.org/downloads/"
    echo "   İndir → Kur (✅ Add Python to PATH seçini!)"
    echo ""
    echo "4️⃣  Tamamlayınca devam et:"
    echo "   bash install.sh"
    echo ""
    read -p "   Kurulumları yaptın mı? (Enter devam etmek için)"

fi

# ============================================================================
# FINAL KONTROL
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   ✅ KONTROL - Tüm Gereklilikler Var mı?                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker: $(docker --version)"
else
    echo "❌ Docker: KURULUMUYOR"
    exit 1
fi

# Git
if command -v git &> /dev/null; then
    echo "✅ Git: $(git --version)"
else
    echo "❌ Git: KURULUMUYOR"
    exit 1
fi

# Python3
if command -v python3 &> /dev/null; then
    echo "✅ Python3: $(python3 --version)"
else
    echo "❌ Python3: KURULUMUYOR"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🎉 TÜMLÜ GEREKLILIKLER KURULDU!                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "🚀 Şimdi kuruluma başla:"
echo ""
echo "   git clone https://github.com/BeysolGit/hospital-archive.git"
echo "   cd hospital-archive"
echo "   bash install.sh"
echo ""
