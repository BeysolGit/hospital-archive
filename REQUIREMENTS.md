# ✅ GEREKLER - Kurulumdan Önce Kontrol Et

## 1️⃣ Docker & Docker Compose

### macOS
```bash
# Homebrew ile
brew install docker docker-compose

# Veya Docker Desktop (recommanded)
# https://www.docker.com/products/docker-desktop
```

**Docker Desktop'ı aç:**
```bash
open -a Docker
```

### Windows
1. **Docker Desktop indir:** https://www.docker.com/products/docker-desktop
2. **Kur ve aç**
3. **Restart et (önemli!)**

### Linux (Ubuntu/Debian)
```bash
# Docker
sudo apt-get update
sudo apt-get install docker.io

# Docker Compose
sudo apt-get install docker-compose

# Kullanıcıyı docker grubuna ekle (sudo şifre gerekli olmayacak)
sudo usermod -aG docker $USER
newgrp docker
```

### Kontrol Et
```bash
docker --version
docker ps
```

---

## 2️⃣ Git

### macOS
```bash
brew install git
```

### Windows
https://git-scm.com/download

### Linux
```bash
sudo apt-get install git
```

### Kontrol Et
```bash
git --version
```

---

## 3️⃣ Python 3

### macOS
```bash
brew install python3
```

### Windows
https://www.python.org/downloads/

### Linux
```bash
sudo apt-get install python3 python3-pip
```

### Kontrol Et
```bash
python3 --version
```

---

## 4️⃣ Tarayıcı

Herhangi bir modern tarayıcı:
- Chrome / Chromium
- Firefox
- Safari (macOS)
- Edge (Windows)

---

## 📋 Hızlı Kontrol Listesi

```bash
docker --version      # ✅ Docker yüklü mü?
docker ps             # ✅ Docker daemon çalışıyor mu?
git --version         # ✅ Git yüklü mü?
python3 --version     # ✅ Python yüklü mü?
```

Hepsinin çıktısı görülüyorsa **hazırsın!**

---

## 🚀 Kuruluma Başla

```bash
git clone https://github.com/BeysolGit/hospital-archive.git
cd hospital-archive
bash install.sh
```

---

## ⚠️ Yaygın Sorunlar

### macOS: Docker daemon çalışmıyor
```bash
open -a Docker  # Docker Desktop'ı aç
sleep 30        # Başlaması bekleniyor
bash install.sh # Tekrar dene
```

### Linux: "Permission denied" hatası
```bash
sudo usermod -aG docker $USER
newgrp docker
docker ps  # Kontrol et
```

### Windows: "Docker daemon is not running"
1. Docker Desktop'ı aç (sistem tepsisinden)
2. Kuruluma devam et

### Tüm Sistemler: "git not found"
- GitHub Desktop indir: https://desktop.github.com/
- Veya Git kur: https://git-scm.com/

---

## 💡 İpuçları

- **macOS:** Docker Desktop kullanmanız tavsiye edilir (brew'dan daha kolay)
- **Linux:** `sudo` olmadan Docker kullanmak için user grubunu güncelle
- **Windows:** Kurulumdan sonra bilgisayarı restart et
- **Tüm:** Port çakışmaları varsa `.env`'de değiştir
