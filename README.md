# Hospital Photo Archiving System

Hastane ortamında çekilen hasta fotoğraflarını otomatik olarak arşivlemek için yerel, açık kaynaklı bir sistem.

- **Immich**: Fotoğraf sunucusu + mobil sync
- **n8n**: Orkestrasyon ve iş akışı
- **barcode-service**: Barkod decode + OCR + LLM parsing
- **OpenRouter LLM**: Yapılandırılmış veri çıkarma

## Sistem Mimarisi

```
[Hospital Phones]
    ↓ WiFi auto-sync via Immich App
[Immich Server] ←── [PC: external library drop folder]
    ↓
[n8n: Poll every 2 minutes]
    ↓
    ├─→ Barcode detected
    │   ├─→ zxing-cpp decode
    │   ├─→ EasyOCR fallback
    │   ├─→ OpenRouter LLM parse
    │   ├─→ Time-window matching
    │   └─→ Archive to /Archive/YYYY-MM-DD/Patient_Name/
    │
    └─→ Patient photo
        └─→ Index timestamp in SQLite
```

## ⚡ KURULUM - TEK KOMUT (3 DAKIKA)

### ⚠️ Önce Kontrol Et
**Gerekler:** [REQUIREMENTS.md](REQUIREMENTS.md)
- Docker Desktop
- Git
- Python 3
- Modern tarayıcı

### 🚀 Otomatik Kurulum
```bash
git clone https://github.com/BeysolGit/hospital-archive.git
cd hospital-archive
bash install.sh
```

**Ne olacak:**
1. ✅ Docker servisleri otomatik başlayacak (Immich, n8n, barcode-service)
2. ✅ Web kurulum sayfası açılacak (http://localhost:9000)
3. ✅ OpenRouter API Key'i yapıştır
4. ✅ Kurulumu tamamla butonuna tıkla
5. ✅ Immich açılacak
6. ✅ Admin hesap yap → Settings → API Keys → Create New Key
7. ✅ Token'i kopyala ve web sayfasında yapıştır
8. ✅ ✅ **BİTTİ!** Sistem hazır!

**Sonra:**
- 📸 Immich: http://localhost:2283 (Fotoğraf yönetimi + mobil sync)
- ⚙️ n8n: http://localhost:5678 (Workflow'lar)
- 📚 API: http://localhost:5001/docs (Barcode API)

---

### Alternatifler

#### Seçenek 2: Adım Adım (Kontrollü)
```bash
bash quick-install.sh
```
Detaylı rehber: [KURULUM.md](KURULUM.md)

#### Seçenek 3: Manuel (İleri Kullanıcılar)

#### 1. Yapılandırma Hazırlığı

```bash
# Proje klasörüne gir
cd hospital-archive

# .env dosyasını düzenle
nano .env
```

Kritik değişkenler:

- `OPENROUTER_API_KEY`: OpenRouter API anahtarı (https://openrouter.ai/keys)
- `IMMICH_API_KEY`: Immich API Key (kurulum sonrası web UI'dan)
- `UPLOAD_LOCATION`: Immich yükleme klasörü (örn: `/tmp/immich-uploads`)
- `ARCHIVE_PATH`: Arşiv hedefi (örn: `/tmp/archive`)

#### 2. Klasörleri Oluştur ve Servisleri Başlat

```bash
# Klasör izinlerini ayarla
mkdir -p photos/{immich,archive,unmatched,external}
chmod 777 photos/*
```

### 2. Docker Compose Başlat

```bash
# Tüm servisleri başlat
docker compose up -d

# Servislerin durumunu kontrol et
docker compose ps

# Logları izle
docker compose logs -f
```

İlk başlangıçta Immich kurulması 1-2 dakika sürebilir.

### 3. Immich Web UI'ya Giriş

1. Tarayıcı: `http://localhost:2283`
2. İlk giriş sırasında admin hesabı oluştur
3. Account Settings → API Keys → Yeni API key oluştur
4. Oluşturulan key'i `.env` dosyasına yaz: `IMMICH_API_KEY=...`
5. n8n konteynerini restart et: `docker compose restart n8n`

### 4. Immich External Library Kur

1. Immich web UI → Administration → External Libraries
2. "New Library" → Path: `/external-library`
3. Scan düğmesine bas
4. (Opsiyonel) Ayarlar → scan sıklığı: her 5 dakikada bir

### 5. Mobil Telefon Kurulumu

**iOS / Android:**
1. App Store / Google Play'den "Immich" indir
2. Server URL: `http://<sunucu-ip-adı>:2283`
3. Giriş yap (Admin hesabı)
4. Settings → Backup → "WiFi only" aç
5. Hangi albümlerin sync edileceğini seç

### 6. n8n Web UI

1. `http://localhost:5678` açarak gir
2. Kullanıcı: `admin` (veya .env'de ayarlanmış değer)
3. Workflows → Import From File
4. `n8n-workflows/01_poll_and_route.json` import et
5. Workflow'u düzenle ve çalıştırabilir hale getir

## API Endpointleri (barcode-service)

### `POST /decode`
İmage'den barkod/OCR çıkar

```bash
curl -F "file=@barcode.jpg" http://localhost:5001/decode
```

Yanıt:
```json
{
  "decoded_text": "...",
  "decode_method": "barcode",
  "confidence": 0.95
}
```

### `POST /parse`
Barkod → Parse → Yapılandırılmış JSON

```bash
curl -F "file=@barcode.jpg" http://localhost:5001/parse
```

Yanıt:
```json
{
  "patient_name": "Ahmet Yilmaz",
  "doctor_name": "Dr. Fatma Kaya",
  "date": "2026-04-10",
  "time": "14:30:00",
  "department": "Radiology",
  "hospital": "Central Hospital"
}
```

### `POST /photo/index`
Hasta fotoğrafını SQLite'a kaydet

```bash
curl -X POST http://localhost:5001/photo/index \
  -H "Content-Type: application/json" \
  -d '{
    "immich_id": "uuid-here",
    "taken_at": "2026-04-10T14:30:00Z"
  }'
```

### `POST /match`
Zaman penceresinde eşleşen fotoğrafları bul

```bash
curl -X POST http://localhost:5001/match \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2026-04-10T14:30:00Z",
    "patient_name": "Ahmet Yilmaz",
    "window_minutes": 30
  }'
```

### `POST /archive`
Fotoğrafları arşiv klasörüne taşı

```bash
curl -X POST http://localhost:5001/archive \
  -H "Content-Type: application/json" \
  -d '{
    "barcode_immich_id": "uuid-1",
    "patient_photos": ["uuid-2", "uuid-3"],
    "patient_name": "Ahmet Yilmaz",
    "date": "2026-04-10"
  }'
```

### `GET /health`
Servis durumu ve istatistikler

```bash
curl http://localhost:5001/health
```

### `GET /stats`
Veritabanı istatistikleri

```bash
curl http://localhost:5001/stats
```

## Sorun Giderme

### Immich API key hatalı
```bash
# Immich konteynerine gir
docker exec -it immich-server bash
# API key'i web UI'dan yeniden al ve .env'ye yaz
```

### barcode-service sağlıksız
```bash
# Logları kontrol et
docker logs barcode-service

# EasyOCR indirme sorunu varsa
docker exec barcode-service python -c "import easyocr; easyocr.Reader(['tr', 'en'])"
```

### n8n workflow'u çalışmıyor
```bash
# n8n loglarını izle
docker compose logs -f n8n

# n8n veri klasörünü temizle (son çare)
docker volume rm hospital-archive_n8n_data
docker compose up -d n8n
```

### OpenRouter API hatası
- API key'i kontrol et: openrouter.ai
- Rate limit check yap
- Model adının doğru olduğundan emin ol: `meta-llama/llama-3.1-8b-instruct`

## İş Akışı Detayları

### Workflow 01 — Polling & Routing (Her 2 dakika)
1. Immich'e sorgu: son kontrol zamanından sonraki fotoğraflar
2. Her fotoğrafı indir ve barcode-service'e gönder
3. Eşer barkod → Workflow 02 tetikle
4. Eğer hasta fotoğrafı → SQLite'a index

### Workflow 02 — Barcode Processing (Webhook tetiklemesi)
1. Barkod metnini OpenRouter ile parse
2. Zaman penceresinde eşleşme ara
3. Eşleşme varsa:
   - Dosyaları `/archive/YYYY-MM-DD/Patient_Name/` taşı
   - Immich'te albüm oluştur
   - Fotoğrafları albüme ekle

### Workflow 03 — Cleanup (Her 15 dakika)
1. 1 saatten eski, eşleşmemiş barkodları bul
2. `/unmatched/` klasörüne taşı
3. (Opsiyonel) Email ile bildirim gönder

## Dosya Yapısı Finalı

```
hospital-archive/
├── docker-compose.yml           # Docker servisleri
├── .env                         # Konfigürasyon (gizli)
├── README.md                    # Bu dosya
│
├── barcode-service/
│   ├── main.py                  # FastAPI uygulaması
│   ├── decoder.py               # zxing + EasyOCR
│   ├── llm_parser.py            # OpenRouter entegrasyonu
│   ├── db.py                    # SQLite veri tabanı
│   ├── Dockerfile               # Python konteyner
│   └── requirements.txt          # Python bağımlılıkları
│
├── n8n-workflows/
│   ├── 01_poll_and_route.json
│   ├── 02_barcode_process.json
│   └── 03_cleanup.json
│
└── photos/                      # Veri klasörleri
    ├── immich/                  # Immich uploads
    ├── archive/                 # Arşivlenmiş fotoğraflar
    ├── unmatched/               # Eşleşmemiş fotoğraflar
    └── external/                # PC uploads (external library)
```

## Önemli Notlar

- **Gizlilik**: Fotoğraflar OpenRouter'a gönderilmez, sadece metin parsing yapılır
- **Türkçe Karakterler**: EasyOCR Türkçe dil desteği ile yapılandırılmıştır
- **Zaman Dilimleri**: Tüm zamanlar UTC olarak saklanır; Türkiye +03:00
- **RAM Gereksinimi**: Minimum 3-4 GB (Immich + n8n + barcode-service)
- **Barkod Türleri**: Code128, QR, PDF417, EAN vb. desteklenir

## Gelecek Geliştirmeler

- [ ] Webhook desteği (Immich'de native olana kadar)
- [ ] Fotoğraf quality kontrol (OCR confidence eşiği)
- [ ] Fuzzy matching iyileştirmesi (multiple matches durumunda)
- [ ] E-posta bildirim integrasyonu
- [ ] Dashboard/analytics (ne kadar fotoğraf arşivlendi, vs.)
- [ ] Batch import desteği (CSV ile hasta bilgisi yükleme)
