#!/bin/bash

# 🏥 Hospital Archive - Otomatik Bağımlılık Kurulumu
# Tüm gerekli yazılımları otomatik kur

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🔧 BAGIMLILIKLAR KURULUYOR                               ║"
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

    # Docker Desktop (daemon + CLI birlikte)
    if ! docker ps &> /dev/null 2>&1; then
        if ! ls /Applications/Docker.app &>/dev/null 2>&1; then
            echo "📦 Docker Desktop kurulması gerekiyor..."
            brew install --cask docker
            echo "✅ Docker Desktop kuruldu"
        else
            echo "✅ Docker Desktop zaten kurulu"
        fi
    else
        echo "✅ Docker zaten çalışıyor"
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
    echo "🚀 Docker Desktop otomatik açılıyor..."
    if [ -d "/Applications/Docker.app" ]; then
        open /Applications/Docker.app 2>/dev/null || true
    else
        open -a Docker 2>/dev/null || true
    fi

    echo "   ⏳ Docker daemon başlaması bekleniyor (60 saniyeye kadar)..."
    WAIT=0
    while [ $WAIT -lt 60 ]; do
        if docker ps &> /dev/null 2>&1; then
            echo "   ✅ Docker daemon hazır!"
            break
        fi
        echo -n "."
        sleep 3
        WAIT=$((WAIT + 3))
    done
    echo ""

fi

# ============================================================================
# Linux - apt ile kur
# ============================================================================

if [ "$OS" = "linux" ]; then
    echo "📋 Linux Kurulumu (Ubuntu/Debian)"
    echo "─────────────────────────────────"
    echo ""

    echo "📥 Paket listesi güncelleniyor..."
    sudo apt-get update -qq

    # Docker Engine + Docker Compose Plugin (v2)
    if ! command -v docker &> /dev/null; then
        echo "📦 Docker kurulması gerekiyor..."
        # Docker'ın resmi GPG anahtarı ve repository'si
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update -qq
        fi
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        echo "✅ Docker + Compose Plugin kuruldu"
    else
        echo "✅ Docker zaten yüklü"
        # Compose plugin yoksa kur
        if ! docker compose version &> /dev/null; then
            echo "📦 Docker Compose Plugin kurulması gerekiyor..."
            sudo apt-get install -y docker-compose-plugin 2>/dev/null || true
        fi
    fi

    # Docker daemon başlat ve kullanıcıyı gruba ekle
    sudo systemctl start docker 2>/dev/null || true
    sudo systemctl enable docker 2>/dev/null || true
    if ! groups | grep -q docker; then
        sudo usermod -aG docker $USER
        echo "⚠️  Docker grubuna eklendi. Değişikliğin geçerli olması için:"
        echo "   Terminali kapat ve yeniden aç, sonra tekrar çalıştır."
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

    # winget varsa otomatik kur
    if command -v winget &> /dev/null; then
        echo "📥 winget ile otomatik kurulum..."

        if ! command -v docker &> /dev/null; then
            echo "📦 Docker Desktop kuruluyor..."
            winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements 2>/dev/null || true
        else
            echo "✅ Docker zaten yüklü"
        fi

        if ! command -v git &> /dev/null; then
            echo "📦 Git kuruluyor..."
            winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements 2>/dev/null || true
        else
            echo "✅ Git zaten yüklü"
        fi

        if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
            echo "📦 Python kuruluyor..."
            winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements 2>/dev/null || true
        else
            echo "✅ Python zaten yüklü"
        fi

        echo ""
        echo "⚠️  Kurulum sonrası terminali kapat ve yeniden aç!"
    else
        echo "⚠️  winget bulunamadı. Manuel kurulum gerekli:"
        echo ""
        echo "1. Docker Desktop: https://www.docker.com/products/docker-desktop"
        echo "2. Git: https://git-scm.com/download/win"
        echo "3. Python: https://www.python.org/downloads/"
        echo "   (Add Python to PATH secenegini tikla!)"
        echo ""
        echo "Kurduktan sonra tekrar calistir: bash install.sh"
    fi

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
    echo "❌ Docker: KURULMADI"
    exit 1
fi

# Git
if command -v git &> /dev/null; then
    echo "✅ Git: $(git --version)"
else
    echo "❌ Git: KURULMADI"
    exit 1
fi

# Python3
if command -v python3 &> /dev/null; then
    echo "✅ Python3: $(python3 --version)"
else
    echo "❌ Python3: KURULMADI"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🎉 TUM GEREKLILIKLER KURULDU!                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "🚀 Şimdi kuruluma başla:"
echo ""
echo "   git clone https://github.com/BeysolGit/hospital-archive.git"
echo "   cd hospital-archive"
echo "   bash install.sh"
echo ""
