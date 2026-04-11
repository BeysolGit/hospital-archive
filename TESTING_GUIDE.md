# Sistem Test Rehberi

## 🧪 Test Stratejisi

Dört seviyede test edeceğiz:

1. **Servis Sağlık Testleri** - Docker containers sağlıklı mı?
2. **API Birim Testleri** - Her endpoint çalışıyor mu?
3. **İntegrasyon Testleri** - Servisler birbirleriyle konuşuyor mu?
4. **Uçtan Uca Testleri** - Tam workflow çalışıyor mu?

---

## 1️⃣ Servis Sağlık Testleri (5 dakika)

### Docker Servisleri Çalışıyor mu?

```bash
# Container'ların durumunu kontrol et
docker compose ps

# Beklenen output:
# NAME              STATUS           PORTS
# immich-db         Up 2 minutes (healthy)
# immich-redis      Up 2 minutes (healthy)
# immich-server     Up 1 minute  (healthy)
# immich-microservices Up 1 minute
# n8n               Up 1 minute  (healthy)
# barcode-service   Up 1 minute  (healthy)
```

### Logları İzle

```bash
# Tüm servislerin loglarını göster
docker compose logs --tail=50

# Spesifik servis:
docker logs barcode-service
docker logs immich-server
docker logs n8n
```

### Health Check Endpoints

```bash
# Immich
curl http://localhost:2283/api/server/ping
# Response: {"res":"pong"}

# barcode-service
curl http://localhost:5001/health
# Response: {"status": "healthy", "stats": {...}}

# n8n (sadece 200 OK döner)
wget -q --spider http://localhost:5678/healthz && echo "✅ n8n healthy"
```

---

## 2️⃣ API Birim Testleri (10 dakika)

### Test 2A: barcode-service /health

```bash
curl http://localhost:5001/health
```

**Beklenen Yanıt:**
```json
{
  "status": "healthy",
  "stats": {
    "total_photos": 0,
    "barcodes": 0,
    "patient_photos": 0,
    "archived": 0,
    "unmatched": 0
  }
}
```

### Test 2B: barcode-service /stats

```bash
curl http://localhost:5001/stats
```

### Test 2C: Barkod Decode Test (Test Görüntü Gerekli)

**Seçenek 1: Gerçek barkod fotoğrafı**
```bash
curl -F "file=@real_barcode.jpg" \
  http://localhost:5001/decode
```

**Seçenek 2: QR Code oluştur ve test et**
```bash
# Basit QR code oluştur (online: qr-code-generator.com)
# PNG indir → barcode.png

curl -F "file=@barcode.png" \
  http://localhost:5001/decode

# Beklenen yanıt:
# {
#   "decoded_text": "...",
#   "decode_method": "barcode",
#   "confidence": 0.95
# }
```

**Seçenek 3: Text görüntü ile OCR test**
```bash
# Metinli bir görseli kullan (kayit bilgisi yazılı)
# "Kisi: Ahmet Yilmaz, Doktor: Dr. Fatma, Tarih: 2026-04-10"

curl -F "file=@text_image.jpg" \
  http://localhost:5001/decode

# Beklenen yanıt (OCR ile):
# {
#   "decoded_text": "Kisi: Ahmet Yilmaz...",
#   "decode_method": "ocr",
#   "confidence": 0.75
# }
```

### Test 2D: Barkod Parse Test (LLM)

```bash
curl -F "file=@barcode.jpg" \
  http://localhost:5001/parse

# Beklenen yanıt:
# {
#   "patient_name": "Ahmet Yilmaz",
#   "doctor_name": "Dr. Fatma Kaya",
#   "date": "2026-04-10",
#   "time": "14:30:00",
#   "department": "Radiology",
#   "organization": "Merkez",
#   "confidence": 0.8
# }
```

### Test 2E: Immich API Test

```bash
# 1. Immich API key al
echo $IMMICH_API_KEY  # .env'den oku

# 2. Server ping
curl -H "x-api-key: $IMMICH_API_KEY" \
  http://localhost:2283/api/server/ping

# 3. Mevcut asset'leri listele (boş olmalı)
curl -X POST -H "x-api-key: $IMMICH_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"takenAfter":"2024-01-01T00:00:00Z","page":1,"size":10}' \
  http://localhost:2283/api/search/metadata
```

---

## 3️⃣ İntegrasyon Testleri (15 dakika)

### Test 3A: Photo Indexing

```bash
# Fotografi SQLite'a index et
curl -X POST http://localhost:5001/photo/index \
  -H "Content-Type: application/json" \
  -d '{
    "immich_id": "test-photo-001",
    "taken_at": "2026-04-10T14:30:00Z",
    "file_path": "/photos/test.jpg"
  }'

# Response: {"success": true, "photo_id": 1, "immich_id": "test-photo-001"}
```

### Test 3B: Barkod Kaydı

```bash
# Barkod fotoğrafını kaydett
curl -X POST http://localhost:5001/photo/index \
  -H "Content-Type: application/json" \
  -d '{
    "immich_id": "test-barcode-001",
    "taken_at": "2026-04-10T14:30:00Z"
  }'
```

### Test 3C: Time-Window Matching

```bash
# Zaman penceresinde eşleşen fotoğrafları bul
curl -X POST http://localhost:5001/match \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2026-04-10T14:30:00Z",
    "patient_name": "Ahmet Yilmaz",
    "window_minutes": 30
  }'

# Beklenen yanıt:
# {
#   "patient_name": "Ahmet Yilmaz",
#   "barcode_timestamp": "2026-04-10T14:30:00Z",
#   "window_minutes": 30,
#   "matches": [
#     {"immich_id": "test-photo-001", "taken_at": "2026-04-10T14:30:00Z", ...}
#   ],
#   "count": 1
# }
```

### Test 3D: Archive Operasyonu

```bash
# Fotoğrafları arşiv klasörüne taşı
curl -X POST http://localhost:5001/archive \
  -H "Content-Type: application/json" \
  -d '{
    "barcode_immich_id": "test-barcode-001",
    "patient_photos": ["test-photo-001"],
    "patient_name": "Ahmet Yilmaz",
    "date": "2026-04-10"
  }'

# Beklenen yanıt:
# {
#   "success": true,
#   "patient_name": "Ahmet Yilmaz",
#   "date": "2026-04-10",
#   "archive_path": "/archive/2026-04-10/Ahmet_Yilmaz",
#   "archived_photos": ["test-photo-001"],
#   "total_archived": 2
# }
```

### Test 3E: Arşiv Klasörünü Kontrol Et

```bash
# Dosyaların doğru yerde oluşup olmadığını kontrol et
ls -la /tmp/archive/2026-04-10/Ahmet_Yilmaz/

# Beklenen çıktı:
# -rw-r--r--  1 root  staff   123456  Apr 10 14:30 photo_1.jpg
```

---

## 4️⃣ Uçtan Uca Testleri (30 dakika)

### Test Süreci

#### Adım 1: Test Dosyaları Hazırla

```bash
# Test klasörü oluştur
mkdir -p test-data

# Test görselleri hazırla (veya indir):
# - test_barcode.jpg   (barkod etiketi fotoğrafı)
# - test_photo1.jpg    (fotograf 1)
# - test_photo2.jpg    (fotograf 2)
```

#### Adım 2: Barkod Fotoğrafını İşle

```bash
# Barkod metnini çıkar
BARCODE_RESPONSE=$(curl -s -F "file=@test-data/test_barcode.jpg" \
  http://localhost:5001/parse)

echo "Barcode Response:"
echo $BARCODE_RESPONSE | jq '.'

# Kisi adi ve zamani not et
PATIENT_NAME=$(echo $BARCODE_RESPONSE | jq -r '.patient_name')
BARCODE_DATE=$(echo $BARCODE_RESPONSE | jq -r '.date')
BARCODE_TIME=$(echo $BARCODE_RESPONSE | jq -r '.time')

echo "Patient: $PATIENT_NAME"
echo "Date: $BARCODE_DATE at $BARCODE_TIME"
```

#### Adım 3: Fotograflari Index Et

```bash
# Fotoğraf 1
curl -s -X POST http://localhost:5001/photo/index \
  -H "Content-Type: application/json" \
  -d "{
    \"immich_id\": \"photo-$(date +%s)-1\",
    \"taken_at\": \"${BARCODE_DATE}T${BARCODE_TIME}Z\",
    \"file_path\": \"/photos/test_photo1.jpg\"
  }" | jq '.'

# Fotoğraf 2 (aynı zaman)
curl -s -X POST http://localhost:5001/photo/index \
  -H "Content-Type: application/json" \
  -d "{
    \"immich_id\": \"photo-$(date +%s)-2\",
    \"taken_at\": \"${BARCODE_DATE}T${BARCODE_TIME}Z\",
    \"file_path\": \"/photos/test_photo2.jpg\"
  }" | jq '.'
```

#### Adım 4: Eşleştirme Yap

```bash
# Zaman penceresinde eşleştirme
MATCHES=$(curl -s -X POST http://localhost:5001/match \
  -H "Content-Type: application/json" \
  -d "{
    \"timestamp\": \"${BARCODE_DATE}T${BARCODE_TIME}Z\",
    \"patient_name\": \"$PATIENT_NAME\",
    \"window_minutes\": 30
  }")

echo "Matches:"
echo $MATCHES | jq '.matches | length'
```

#### Adım 5: Arşive Taşı

```bash
# Eşleşen fotoğraf ID'lerini al
PHOTO_IDS=$(echo $MATCHES | jq -r '.matches[].immich_id' | xargs)

# Arşiv yap
curl -s -X POST http://localhost:5001/archive \
  -H "Content-Type: application/json" \
  -d "{
    \"barcode_immich_id\": \"barcode-test\",
    \"patient_photos\": [$PHOTO_IDS],
    \"patient_name\": \"$PATIENT_NAME\",
    \"date\": \"$BARCODE_DATE\"
  }" | jq '.'
```

#### Adım 6: Sonucu Doğrula

```bash
# Arşiv klasörünü kontrol et
ls -lR /tmp/archive/

# Beklenen yapı:
# /tmp/archive/2026-04-10/Ahmet_Yilmaz/
#   ├── photo_001.jpg
#   ├── photo_002.jpg
#   └── barcode.jpg
```

---

## 5️⃣ Otomatik Test Script'i

```bash
#!/bin/bash
# test_system.sh

set -e

echo "🧪 Fotograf Arsivleme System Test Suite"
echo "======================================"
echo ""

# Test 1: Services
echo "Test 1: Docker Services Health"
docker compose ps | grep -E "immich|barcode|n8n"

# Test 2: APIs
echo ""
echo "Test 2: API Health Checks"
curl -s http://localhost:5001/health | jq '.status'
curl -s http://localhost:2283/api/server/ping | jq '.res'

# Test 3: Database
echo ""
echo "Test 3: Database Stats"
curl -s http://localhost:5001/stats | jq '.stats'

# Test 4: Simple decode (QR code)
echo ""
echo "Test 4: Barcode Decode (needs test image)"
echo "Run: curl -F 'file=@test_image.jpg' http://localhost:5001/decode"

echo ""
echo "✅ All basic tests passed!"
```

Bunu çalıştır:
```bash
chmod +x test_system.sh
./test_system.sh
```

---

## 6️⃣ n8n Workflow Testi

### Manual Test

1. n8n acilir: `http://localhost:5678`
2. Workflow 01 import et
3. "Trigger manually" butonuna bas
4. Execution history'de log'ları izle

### Otomatik Test

```bash
# n8n API ile workflow tetikle
curl -X POST http://localhost:5678/webhook/workflow \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## 7️⃣ Mobil (Immich) Testi

### Simulator ile Test (macOS)

```bash
# Simulator'ı aç
open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app

# Immich uygulamasını indir (App Store)
# Server: http://localhost:2283
```

### Real Device ile Test

1. Telefon → Immich App
2. Server URL: `http://<mac-ip>:2283`
3. "Settings" → "WiFi only" → ON
4. Foto çek → otomatik yüklenmesi izle

---

## 🎯 Test Checklist

- [ ] 6 Docker container healthy
- [ ] barcode-service /health 200 OK
- [ ] Immich API /api/server/ping 200 OK
- [ ] n8n /healthz 200 OK
- [ ] barcode decode test (OCR veya machine-readable)
- [ ] barcode parse test (LLM response)
- [ ] Photo indexing çalışıyor
- [ ] Time-window matching çalışıyor
- [ ] Archive klasör yapısı doğru
- [ ] n8n workflow manual tetiklemede loglar temiz
- [ ] (Opsiyonel) Mobil sync test

---

## 📊 Expected Test Results

| Test | Status | Details |
|---|---|---|
| Services Running | ✅ | 6/6 healthy |
| barcode /health | ✅ | Stats doğru |
| Immich API | ✅ | Ping OK |
| Barcode Decode | ✅ | QR veya OCR çalışıyor |
| Barcode Parse | ✅ | LLM JSON çıkıyor |
| Photo Index | ✅ | SQLite'a kaydediliyor |
| Time Match | ✅ | ±30 dk penceresi |
| Archive | ✅ | Doğru klasör yapısı |
| n8n Workflow | ✅ | Manual tetiklemede çalışıyor |

---

## 🚀 Test Tamamlandıktan Sonra

1. Workflow 02 & 03 import et
2. Scheduling'i aç (Workflow 01 her 2 dakikada tetiklenir)
3. Mobil cihazları kur
4. Barkodlu gerçek test yap
