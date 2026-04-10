# Hızlı Başlangıç Rehberi

## 1️⃣ Temel Kurulum (5 dakika)

```bash
# Proje klasörüne gir
cd hospital-archive

# .env dosyasını kopyala ve düzenle
cp .env .env.local
nano .env.local

# Gerekli değişkenleri doldur:
# - ARCHIVE_PATH: /path/to/archive (mutlak path)
# - EXTERNAL_LIBRARY_PATH: /path/to/external
# - UPLOAD_LOCATION: /path/to/immich-uploads
```

## 2️⃣ Docker Başlat

```bash
# Setup script'i çalıştır (otomatik başlangıç + health check)
./setup.sh

# VEYA manuel başlangıç:
docker compose up -d
```

**Kontrol et:**
```bash
docker compose ps
# Tüm servislerin STATE sütunu "Up" olmalı
```

## 3️⃣ Immich Konfigürasyonu (1 dakika)

**Adım 1: Web UI Aç**
- Tarayıcı: `http://localhost:2283`
- Admin hesabı oluştur

**Adım 2: API Key Al**
1. Account Settings (sağ üst)
2. API Keys
3. "Create New Key" → Copy

**Adım 3: .env'ye Yaz**
```bash
nano .env.local
# IMMICH_API_KEY=<yapıştır>
```

**Adım 4: n8n Restart**
```bash
docker compose restart n8n
```

## 4️⃣ n8n Workflows Kur (2 dakika)

**Adım 1: n8n Aç**
- Tarayıcı: `http://localhost:5678`
- Giriş: admin / (şifre from .env)

**Adım 2: Workflow Import**
1. Workflows (sol menü)
2. → Import From File
3. → Seç: `n8n-workflows/01_poll_and_route.json`
4. → Import

**Adım 3: Yapılandır**
1. Workflow açıl
2. Credentials check:
   - "immich_api" credential'ı ayarlandı mı?
   - Hata varsa: Edit → API Key gir
3. Workflow başlatmak için "Active" toggle'ı aç

## 5️⃣ Test Et (Smartphone olmadan)

### Test 1: Barcode Decode

```bash
# Sample barkod image indir (test için)
# Veya kendi test barkodunu hazırla

curl -F "file=@test_barcode.jpg" \
  http://localhost:5001/decode

# Beklenen sonuç:
# {
#   "decoded_text": "...",
#   "decode_method": "barcode" or "ocr",
#   "confidence": 0.95
# }
```

### Test 2: API Sağlık Kontrolü

```bash
curl http://localhost:5001/health
curl http://localhost:5001/stats
```

### Test 3: Immich API

```bash
# Immich'e test asset yükle
curl -X POST http://localhost:2283/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"<admin-password>"}'
```

## 6️⃣ Üretim Hazırlığı

### Mobil Sync Kur (iPhone / Android)

1. **App indir:**
   - iOS: App Store → "Immich"
   - Android: Google Play / F-Droid → "Immich"

2. **Bağlan:**
   - Server URL: `http://<router-ip>:2283` (lokal ağda)
   - Veya `http://<public-ip>:2283` (uzak erişim için)

3. **Ayarlar:**
   - WiFi only backup: ON
   - Şunları sync et: Kamera, Screenshots, vb.

### PC'den Yükleme (External Library)

```bash
# Fotoğrafları buraya bırak:
/path/to/external/

# Immich otomatik tarar veya:
curl -X POST http://localhost:2283/api/libraries/<library-id>/scan \
  -H "x-api-key: $IMMICH_API_KEY"
```

## 7️⃣ Arşiv Yapısı

Kurulumdan sonra arşiv bu şekilde görünecek:

```
archive/
├── 2026-04-10/
│   ├── Ahmet_Yilmaz/
│   │   ├── photo_1.jpg
│   │   ├── photo_2.jpg
│   │   └── barcode.jpg
│   └── Fatma_Kaya/
│       ├── photo_1.jpg
│       └── barcode.jpg
```

## 8️⃣ Sonraki Adımlar

- [ ] Workflow 02 (Barcode Processing) ve Workflow 03 (Cleanup) import et
- [ ] Mobil cihazları connect et
- [ ] Test barkodu fotoğrafla (hasta resmini çek aynı zaman penceresinde)
- [ ] Arşiv klasöründe dosyaların doğru yerde oluşup olmadığını kontrol et
- [ ] Immich web UI'da albümleri gözle

## 🔧 Sık Yapılan Ayarlamalar

### Polling Aralığını Değiştir

n8n'de Workflow 01 → Schedule Trigger → Interval
- Varsayılan: 2 dakika
- Daha sık: 30 saniye (daha fazla CPU)
- Daha seyrek: 5 dakika (daha az kaynak)

### Zaman Penceresini Değiştir

`.env` dosyasında:
```
MATCH_WINDOW_MINUTES=30  # ±30 dakika
```

### Arşiv Klasörünü Değiştir

`.env` dosyasında:
```
ARCHIVE_PATH=/path/to/new/archive
```

Sonra:
```bash
docker compose down
docker compose up -d
```

## ❓ Sık Sorulan Sorular

**S: Fotoğraflar buluta gidiyor mu?**
A: HAYIR. Barcode parsing için sadece metin OpenRouter'a gönderiliyor, fotoğraflar yerel kalıyor.

**S: Offline çalışıyor mu?**
A: Kısmen. OpenRouter gerekeceğinden internet lazım. Fakat lokal LLM (Ollama) ile offline de yapılabilir.

**S: Kaç GB RAM gerek?**
A: Minimum 3 GB. Immich (2 GB) + n8n (512 MB) + barcode-service (512 MB).

**S: Barkod okuması çalışmıyor?**
A: Kontrol et:
1. Fotoğraf net ve iyi aydınlatılmış mı?
2. barcode-service logları: `docker logs barcode-service`
3. EasyOCR yüklü mü: `docker exec barcode-service python -c "import easyocr"`

**S: n8n workflow'u tetiklenmiyor?**
A: Kontrol et:
1. Workflow Active mi?
2. Schedule Trigger zamanı doğru mu?
3. Immich API key doğru mu?
4. n8n logları: `docker logs n8n`

## 📞 Destek

- Docker sorunları: `docker compose logs <service>`
- Barcode sorunları: `docker logs barcode-service`
- n8n sorunları: Web UI → Execution history
- OpenRouter sorunları: API key ve rate limit kontrol et
