# 🏥 Hospital Archive - KURULUM REHBERI

## ⚡ TEK KOMUT KURULUM

### ADIM 1: Terminal'i Aç
```bash
# macOS: Command + Space → "Terminal" yazıp Enter
# Veya Spotlight'dan Terminal aç
```

### ADIM 2: Doğru Klasöre Git
```bash
cd /Users/beysol/Agents/hospital-archive
```

### ADIM 3: Kurulumu Başlat
```bash
bash install.sh
```

---

## 📋 Bütün Kurulum Adımları (Tek Kopyala-Yapıştır)

Terminal'e sırasıyla yapıştır:

### 1️⃣ Klasöre Git
```bash
cd /Users/beysol/Agents/hospital-archive
```

### 2️⃣ Kurulumu Başlat
```bash
bash install.sh
```

**Ne olacak:**
- Docker servisleri başlayacak (2-3 dakika)
- Web sayfası otomatik açılacak (http://localhost:9000)

### 3️⃣ Web Sayfasında (Tarayıcı)

1. **OpenRouter API Key'i Yapıştır**
   - Nereden: https://openrouter.ai/keys
   - Create Key butonuna tıkla
   - Token'i kopyala (sk-or-... şeklinde)
   - Web sayfasında yapıştır

2. **"Kurulumu Tamamla" Butonuna Tıkla**
   - Sistem konfigüre olacak
   - Immich otomatik açılacak

### 4️⃣ Immich'te (Tarayıcı - http://localhost:2283)

1. **Admin Hesap Oluştur**
   - Email ve şifre gir

2. **API Key Al**
   - Settings → Account → API Keys
   - "Create New Key" butonuna tıkla
   - Token'i kopyala

### 5️⃣ Web Sayfasında (Geri Dön)

1. **Immich API Key'i Yapıştır**
   - Token'i "Immich API Key" alanına yapıştır

2. **"Hazır!" Butonuna Tıkla**
   - Kurulum tamamlanır!

---

## ✅ Kontrol - Sistem Çalışıyor mu?

### Terminal'de Kontrol Et
```bash
docker compose ps
```

**Beklenen çıktı:**
```
NAME                  STATUS
immich-db            Up (healthy)
immich-redis         Up (healthy)
immich-server        Up (healthy)
immich-microservices Up (healthy)
barcode-service      Up (healthy)
n8n                  Up (healthy)
```

Hepsinin `Up (healthy)` olması gerekir.

### Web Sayfaları Aç

| Uygulama | URL | Ne İçin |
|---|---|---|
| Immich | http://localhost:2283 | Fotoğraf yönetimi + Mobil sync |
| n8n | http://localhost:5678 | Workflow'lar |
| API Docs | http://localhost:5001/docs | Barcode API |

---

## 🧪 Test Et (İsteğe Bağlı)

```bash
# Test verisi oluştur
bash create_test_data.sh

# Sistem sağlık kontrolü
bash test.sh
```

**Beklenen çıktı:**
```
✅ All tests passed!
```

---

## 📱 Mobil Kurulumu

1. **Immich App İndir**
   - iOS: App Store
   - Android: Google Play

2. **Server Ekle**
   - Server URL: `http://<bilgisayar-ip>:2283`
   - Email ve şifre gir

3. **Backup Ayarları**
   - WiFi-only backup aktif et
   - Fotoğrafları çek → Otomatik yüklenir

---

## ❌ Sorun Mu Var?

### "bash: install.sh: command not found"
```bash
# Doğru klasörde misin kontrol et
pwd

# Çıktı: /Users/beysol/Agents/hospital-archive olmalı

# Değilse:
cd /Users/beysol/Agents/hospital-archive
```

### "Docker not found"
```bash
# Docker yüklü değil
# Yükle: https://www.docker.com/products/docker-desktop
```

### "Docker daemon is not running"
```bash
# Docker Desktop'ı aç (Applications → Docker)
```

### "Port 9000 kullanımda"
```bash
# Script otomatik 9001 portuna geçer
# Veya başka kurulum var mı kontrol et:
lsof -i :9000
```

### "Services are not healthy"
```bash
# Logları kontrol et
docker logs immich-server
docker logs barcode-service
docker logs n8n

# Restart'la
docker compose restart
```

### "Web sayfası açılmadı"
```bash
# Manuel olarak aç
# http://localhost:9000
```

---

## 🎯 Sonraki Adımlar

### 1. n8n Workflow'larını Import Et (İsteğe bağlı)
```
1. http://localhost:5678 aç
2. Workflows → Import From File
3. Seç: n8n-workflows/01_poll_and_route.json
4. Done!
```

### 2. Teste Başla
```bash
bash test.sh
```

### 3. Üretimde Kullan
- Immich mobil app'ten fotoğraf çek
- Barkod etiketi fotoğrafla
- Sistem otomatik arşivler

---

## 💡 İpuçları

1. **Immich Mobil Sync**
   - Telefon WiFi'ye bağlanırsa otomatik sync
   - Settings → Enable WiFi-only backup

2. **Barkod Tanıması**
   - Barkod etiketi açık yerde fotoğrafla
   - Sistem otomatik parse eder
   - ±30 dakika içinde çekilen fotoğrafları eşleştirir

3. **Arşiv Klasörü**
   - Fotoğraflar: `/tmp/archive/YYYY-MM-DD/Hasta_Adi/`
   - İstatistikler SQLite'da tutulur

4. **API Key Ayarlarını Değiştir**
   - `.env` dosyasını düzenle
   - `docker compose restart n8n`

---

## 📞 Hata Ayıklama

**Sistem başlamıyor?**
```bash
# Logları gerçek zamanda görmek için
docker compose logs -f

# Veya spesifik servis:
docker compose logs -f barcode-service
```

**Servisleri sıfırla:**
```bash
docker compose down
docker compose up -d
```

**Her şeyi temizle ve baştan başla:**
```bash
docker compose down -v
docker compose up -d
```

---

## ✨ Bitmiş!

Artık sisteminiz hazır! 🎉

- 📸 Fotoğraf yönetimi: Immich
- ⚙️ Workflow'lar: n8n
- 🔍 Barkod: barcode-service
- 📱 Mobil sync: Immich App

Başlamak için:
1. Fotoğraf çek (Immich app'ten)
2. Barkod fotoğrafla
3. Sistem otomatik arşivler

**Sorun olursa:** Logları kontrol et → Ayarları düzenle → Yeniden dene

🚀 Başarısını kısa bir rapor halinde bana bildir!
