# 🧪 Hızlı Test Başlangıcı (5 dakika)

## Adım 1: Test Script'ini Çalıştır

```bash
cd hospital-archive

# Otomatik sistem sağlık kontrolü
./test.sh
```

**Beklenen çıktı:**
```
✅ All tests passed!

Next steps:
1. Import n8n workflows (01, 02, 03)
2. Configure IMMICH_API_KEY in .env (if not done)
3. Restart n8n: docker compose restart n8n
4. Set up mobile device or test with sample images
```

---

## Adım 2: Test Verilerini Oluştur

```bash
# Hasta fotoğrafı ve barkod etiketi oluştur
./create_test_data.sh

# Dosyalar test-data/ klasöründe oluşacak
ls test-data/
```

---

## Adım 3: Manuel API Testleri (2 dakika)

### Test 3A: Barkod Decode

```bash
# Barcode label OCR decode
curl -F "file=@test-data/test_barcode_label.jpg" \
  http://localhost:5001/decode
```

**Beklenen yanıt:**
```json
{
  "decoded_text": "HEMŞİRELİK KLİNİĞİ...",
  "decode_method": "ocr",
  "confidence": 0.75
}
```

### Test 3B: Barkod Parse (LLM)

```bash
# OpenRouter ile parse
curl -F "file=@test-data/test_barcode_label.jpg" \
  http://localhost:5001/parse
```

**Beklenen yanıt:**
```json
{
  "patient_name": "Ahmet Yilmaz",
  "doctor_name": "Dr. Fatma Kaya",
  "date": "2026-04-10",
  "time": "14:30:00",
  "department": "Radyoloji",
  "hospital": "Merkez Hastanesi",
  "confidence": 0.8
}
```

### Test 3C: Fotoğraf Index

```bash
# Hasta fotoğrafını SQL'e kaydet
curl -X POST http://localhost:5001/photo/index \
  -H "Content-Type: application/json" \
  -d '{
    "immich_id": "test-photo-001",
    "taken_at": "2026-04-10T14:30:00Z"
  }'
```

### Test 3D: Zaman Eşleştirmesi

```bash
# ±30 dakika penceresinde eşleştirme
curl -X POST http://localhost:5001/match \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2026-04-10T14:30:00Z",
    "patient_name": "Ahmet Yilmaz",
    "window_minutes": 30
  }'
```

### Test 3E: Arşiv

```bash
# Fotoğrafları arşive taşı
curl -X POST http://localhost:5001/archive \
  -H "Content-Type: application/json" \
  -d '{
    "barcode_immich_id": "test-barcode-001",
    "patient_photos": ["test-photo-001"],
    "patient_name": "Ahmet Yilmaz",
    "date": "2026-04-10"
  }'
```

**Kontrol et:**
```bash
ls -la /tmp/archive/2026-04-10/Ahmet_Yilmaz/
```

---

## Adım 4: n8n Workflow Testi (3 dakika)

1. **n8n aç:** `http://localhost:5678`

2. **Import Workflow:**
   - Workflows → Import From File
   - Seç: `n8n-workflows/01_poll_and_route.json`

3. **Manuel Tetikle:**
   - Workflow açıl
   - "Test" butonuna bas
   - Execution history'de logları izle

4. **Kontrol Et:**
   - Loglar temiz mi?
   - Barcode-service'e çağrı yapılıyor mu?
   - Hata var mı?

---

## Test Checklist

- [ ] `./test.sh` başarıyla tamamlandı
- [ ] `./create_test_data.sh` test dosyaları oluşturdu
- [ ] `/decode` endpoint çalışıyor (OCR metni döner)
- [ ] `/parse` endpoint çalışıyor (JSON döner)
- [ ] `/photo/index` endpoint çalışıyor
- [ ] `/match` endpoint çalışıyor
- [ ] `/archive` endpoint çalışıyor
- [ ] Arşiv klasör yapısı doğru
- [ ] n8n Workflow 01 manual tetiklemede çalışıyor
- [ ] Hiç hata yok

---

## Sorun Giderme

### "Host key verification failed" (GitHub push)
- SSH key'i GitHub'a ekle veya HTTPS token kullan

### barcode-service sağlıksız
```bash
docker logs barcode-service
# Sorunları kontrol et
```

### n8n workflow hatası
```bash
docker logs n8n
# API key doğru mu?
# Immich erişilebilir mi?
```

### Test script başarısız
```bash
# Servislerin başlaması 30 saniye bekle
sleep 30
./test.sh
```

### OpenRouter API hatası
- `.env` dosyasında `OPENROUTER_API_KEY` doğru mu?
- Token active mi?
- Rate limit aşılmış mı?

---

## 🎯 Sonraki Adımlar

Tüm testler başarılı olursa:

1. ✅ Workflow 02 (Barcode Processing) import et
2. ✅ Workflow 03 (Cleanup) import et
3. ✅ Mobil cihaz kur (iOS/Android Immich App)
4. ✅ Gerçek barkod fotoğrafı çek
5. ✅ Jusqu'à uçtan uca test

---

## 📞 Test Sonuçlarını Raporla

Test sonuçlarını görürsen:
- Hangi testler başarılı / başarısız?
- Varsa error mesajları ne?
- Loglar temiz mi?

Bu bilgilerle daha derine ineceğiz! 🚀
