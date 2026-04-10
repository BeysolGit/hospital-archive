# ✅ GEREKLER - Kurulumdan Önce Kontrol Et

## 1️⃣ Docker Desktop

### macOS
**Yükle:**
```bash
brew install docker
```

Veya direkt indir:
https://www.docker.com/products/docker-desktop

**Kontrol et:**
```bash
docker --version
docker ps
```

### Windows
https://www.docker.com/products/docker-desktop

### Linux
```bash
sudo apt-get install docker.io
sudo apt-get install docker-compose
```

---

## 2️⃣ Git

### macOS
```bash
brew install git
```

### Windows/Linux
https://git-scm.com/download

**Kontrol et:**
```bash
git --version
```

---

## 3️⃣ Python 3 (macOS/Linux için)

### macOS
```bash
brew install python3
```

### Linux
```bash
sudo apt-get install python3
```

**Kontrol et:**
```bash
python3 --version
```

---

## 4️⃣ Tarayıcı

Herhangi bir modern tarayıcı (Chrome, Safari, Firefox, Edge)

---

## 📋 Kontrol Listesi

```bash
# Hepsini kontrol et
docker --version    # Docker yüklü mü?
git --version       # Git yüklü mü?
python3 --version   # Python yüklü mü?
```

Hepsi çalışıyorsa **hazırsın!**

---

## 🚀 Sonra Kuruluma Başla

```bash
git clone https://github.com/BeysolGit/hospital-archive.git
cd hospital-archive
bash install.sh
```

**Not:** Docker Desktop macOS'ta başlatıldığından emin ol (Applications → Docker)
