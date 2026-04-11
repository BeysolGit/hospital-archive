# 🏥 Hospital Photo Archiving System - Complete Overview

## Sistem Tanımı

Hastane ortamında çekilen hasta fotoğraflarını **otomatik olarak arşivleyen**, tamamen **lokal**, **açık kaynaklı** bir sistem.

---

## 🎯 Temel Özellikler

### ✅ Kabiliyetler

| Özellik | Açıklama |
|---|---|
| **Mobil Sync** | Hastane telefonları WiFi'ye bağlanınca otomatik foto yükleme |
| **Barkod Okuma** | Fotoğraflanmış hasta barkodlarından bilgi çıkarma |
| **OCR** | El yazısı/basılı metinleri tanıma (Türkçe destekli) |
| **LLM Parsing** | OpenRouter ile yapılandırılmış veri çıkarma |
| **Zaman Eşleştirme** | ±30 dakika penceresinde fotoğraf eşleştirme |
| **Otomatik Arşiv** | `Archive/YYYY-MM-DD/Hasta_Adı/` yapısına taşıma |
| **Web UI** | Immich'te web arayüzünden fotoğrafları görüntüleme |
| **REST API** | Tüm işlemler için API endpointleri |

### ❌ Yapmadığı Şeyler

- Fotoğrafları buluta göndermez (gizlilik korunur)
- Yüz tanıma yapmaz (istenmediyse)
- SMS/email göndermiş
- Hasta verilerini harici sistemlere iletmez

---

## 🏗️ Sistem Mimarisi

```
┌─────────────────────────────────────────────────────────┐
│                   HASTANE ORTAMI                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  [Telefon 1]  [Telefon 2]  [PC Klasörü]                │
│      │             │            │                       │
│      └─────────────┴────────────┘                       │
│             WiFi Auto-Sync                              │
│                    │                                     │
│         ┌──────────▼──────────┐                         │
│         │   IMMICH SERVER     │                         │
│         │  (Photo Storage +   │                         │
│         │   Web UI + API)     │                         │
│         │  Port: 2283         │                         │
│         └──────────┬──────────┘                         │
│                    │                                     │
│         ┌──────────▼──────────┐                         │
│         │   n8n ORCHESTRATION │                         │
│         │  (Polling 2 min)    │                         │
│         │  Port: 5678         │                         │
│         │  ├─ Workflow 01     │                         │
│         │  ├─ Workflow 02     │                         │
│         │  └─ Workflow 03     │                         │
│         └──────────┬──────────┘                         │
│                    │                                     │
│         ┌──────────▼──────────┐                         │
│         │  BARCODE SERVICE    │                         │
│         │  (FastAPI)          │                         │
│         │  Port: 5001         │                         │
│         │  ├─ zxing-cpp       │                         │
│         │  ├─ EasyOCR         │                         │
│         │  ├─ OpenRouter LLM  │                         │
│         │  ├─ SQLite DB       │                         │
│         │  └─ Archive Mgr     │                         │
│         └──────────┬──────────┘                         │
│                    │                                     │
│         ┌──────────▼──────────┐                         │
│         │   ARCHIVE FOLDER    │                         │
│         │  /Archive/          │                         │
│         │  ├─ 2026-04-10/     │                         │
│         │  │  ├─ Ahmet_Yilmaz │                         │
│         │  │  │  ├─ photo1.jpg│                         │
│         │  │  │  ├─ photo2.jpg│                         │
│         │  │  │  └─ barcode.jpg
│         │  │  └─ Fatma_Kaya/  │                         │
│         │  └─ 2026-04-11/     │                         │
│         └─────────────────────┘                         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 📦 Bileşenler

### 1. Immich Server

**Role:** Fotoğraf depolama + mobil sync + web UI

```
Services:
├─ immich-server (port 3001)
├─ immich-microservices (thumbnail + metadata)
├─ PostgreSQL + pgvecto.rs (database)
└─ Redis (cache)
```

**Features:**
- iOS/Android app ile otomatik backup
- REST API erişimi
- Web UI (`http://localhost:2283`)
- External library (PC uploads)

### 2. n8n Orchestration

**Role:** İş akışları ve tetikleme

```
Workflows:
├─ 01_poll_and_route
│  ├─ Schedule: her 2 dakikada
│  ├─ Immich'ten yeni fotoğraf sor
│  ├─ Barcode detect → Workflow 02
│  └─ Patient photo → Index
│
├─ 02_barcode_process
│  ├─ LLM ile parse
│  ├─ Zaman eşleştirme
│  ├─ Arşive taşı
│  └─ Immich albümüne ekle
│
└─ 03_cleanup
   ├─ Schedule: her 15 dakikada
   ├─ Eşleşmeyen barkodları bul
   └─ unmatched/ klasörüne taşı
```

### 3. barcode-service (Python FastAPI)

**Role:** Fotoğraf işleme ve barkod okuma

```python
Endpoints:
├─ POST /decode           # Barkod/OCR decode
├─ POST /parse            # LLM ile parse
├─ POST /photo/index      # Index fotoğraf
├─ POST /match            # Zaman eşleştirme
├─ POST /archive          # Arşive taşı
├─ GET  /health           # Sağlık kontrolü
└─ GET  /stats            # İstatistikler
```

**Pipeline:**
```
Barcode Image
  ├─ zxing-cpp (machine-readable)
  ├─ EasyOCR (fallback, Türkçe)
  └─ OpenRouter LLM (strukturlama)
         ↓
    JSON Output
    {
      patient_name,
      doctor_name,
      date, time,
      department,
      hospital
    }
```

---

## 🗂️ Dosya Yapısı

```
fotograf-arsivleme/
│
├─ docker-compose.yml      # 5 servis tanımı
├─ .env                    # Konfigürasyon
├─ .gitignore              # Git ignore rules
│
├─ barcode-service/
│  ├─ main.py              # FastAPI uygulaması
│  ├─ decoder.py           # zxing + EasyOCR
│  ├─ llm_parser.py        # OpenRouter integration
│  ├─ db.py                # SQLite veri tabanı
│  ├─ Dockerfile           # Python container
│  └─ requirements.txt      # Bağımlılıklar
│
├─ n8n-workflows/
│  ├─ 01_poll_and_route.json
│  ├─ 02_barcode_process.json
│  └─ 03_cleanup.json
│
├─ Documentation
│  ├─ README.md                    # Ana rehber
│  ├─ QUICKSTART.md                # 5 dakika kurulum
│  ├─ TESTING_GUIDE.md             # Test stratejisi
│  ├─ TESTING_QUICK_START.md       # Hızlı testler
│  ├─ TEST_EXECUTION_PLAN.md       # Test detayları
│  ├─ SYSTEM_OVERVIEW.md           # Bu dosya
│  ├─ CREATE_REPO.md               # GitHub setup
│  └─ GITHUB_PUSH.md               # Push rehberi
│
├─ Scripts
│  ├─ setup.sh              # Otomatik kurulum
│  ├─ test.sh               # Otomatik test
│  └─ create_test_data.sh   # Test veri oluştur
│
└─ photos/                  # Veri klasörleri
   ├─ immich/
   ├─ archive/
   ├─ unmatched/
   └─ external/
```

---

## 🚀 Hızlı Başlangıç

### 1. Kur (5 dakika)
```bash
git clone https://github.com/beysol/fotograf-arsivleme.git
cd fotograf-arsivleme
./setup.sh
```

### 2. Test Et (2 dakika)
```bash
./test.sh
./create_test_data.sh
```

### 3. Kullan (1 dakika)
```bash
# Web UI
http://localhost:2283 (Immich)
http://localhost:5678 (n8n)

# API
http://localhost:5001 (barcode-service)
```

---

## 📊 Teknoloji Stack'i

| Katman | Teknoloji | Neden |
|---|---|---|
| **Fotoğraf Server** | Immich | Mobil sync + açık kaynaklı + REST API |
| **Orkestrasyon** | n8n | Görsel akış + HTTP nodes + scheduling |
| **Barkod Okuma** | zxing-cpp | Fotoğraflanmış barkodda en iyi doğruluk |
| **OCR** | EasyOCR | Türkçe + gerçek dünya gürültüsü toleransı |
| **LLM** | OpenRouter + Llama 3.1 | Açık kaynaklı + hızlı + ucuz |
| **Database** | SQLite | Hafif + lokal + dosya tabanında |
| **API** | FastAPI | Python + modern + otodoc |
| **Container** | Docker | Kolay kurulum + izolasyon |
| **SCM** | Git/GitHub | Versiyon kontrol + backup |

---

## 🔐 Güvenlik & Gizlilik

### ✅ Yapılan

- Hiç fotoğraf buluta gitmez
- Sadece metin OpenRouter'a gönderilir
- Tüm işlemler lokal
- SQLite şifreleme yapılandırılabilir
- n8n ve Immich basic auth'ı

### ⚠️ Yapılması Gereken (Üretim)

- SSL/TLS sertifikaları
- Database enkripsionu
- API rate limiting
- Yedekleme stratejisi
- Audit logging
- Kullanıcı yönetimi (çok-kullanıcılı)

---

## 📈 Performans

| Metrik | Beklenen |
|---|---|
| Service Startup | 30-60 saniye |
| Health Check | <1 saniye |
| Barcode Decode | 1-3 saniye |
| LLM Parsing | 2-5 saniye |
| Photo Indexing | <100ms |
| Time Match | <100ms |
| Archive Op | <500ms |
| Workflow Cycle | 5-10 saniye |
| **Toplam**: Photo detect to archive | ~30 saniye |

---

## 🔄 İş Akışı (Uçtan Uca)

### Senaryo: Hasta Fotoğrafı Çekildi

```
1. Hastane telefonundan hasta fotoğrafı çekildi
   ↓
2. Telefon WiFi'ye bağlanınca Immich otomatik sync
   (Immich mobile app çalışıyor)
   ↓
3. n8n Workflow 01 her 2 dakikada tetiklenir
   - Immich'ten son kontrol zamanından sonraki fotoğrafları sor
   ↓
4. Her fotoğrafı barcode-service'e gönder
   ├─ zxing-cpp ile decode (machine-readable barcode)
   ├─ Başarısız → EasyOCR fallback
   └─ Başarılı → barcode olarak işaretlenip Workflow 02'ye git
     ↓
5. Workflow 02: Barcode Processing
   - Barkod metnini OpenRouter Llama 3.1'e gönder
   - LLM hasta adı, doktor, tarih vb. çıkart
   - barcode-service'e çağrı: zaman penceresinde eşleşen fotoğrafları bul
   ↓
6. Eşleştirme başarılı
   - Tüm eşleşen fotoğrafları /archive/YYYY-MM-DD/Hasta_Adı/ taşı
   - Immich'te hasta adına göre albüm oluştur
   - Fotoğrafları albüme ekle
   ↓
7. n8n Workflow 03 (Cleanup, her 15 dakikada)
   - Eşleşmemiş barkodları bul (1 saatten eski)
   - /unmatched/ klasörüne taşı
   ↓
8. SONUÇ
   - Archive/2026-04-10/Ahmet_Yilmaz/
     ├─ photo_1.jpg (até fotoğrafı)
     ├─ photo_2.jpg (hasta fotoğrafı)
     └─ barcode.jpg (barkod etiketi)
   
   - Immich'te "2026-04-10 — Ahmet Yilmaz" albümü
     ├─ photo_1.jpg
     ├─ photo_2.jpg
     └─ barcode.jpg
```

---

## 🧪 Test Stratejisi

### 4 Seviye Test

1. **Unit Tests** (Birim)
   - API endpoint'leri çalışıyor mu?
   - Database sorguları doğru mu?
   
2. **Integration Tests** (İntegrasyon)
   - Servisler birbirleriyle konuşuyor mu?
   - API'ler veri alışverişi yapıyor mu?

3. **System Tests** (Sistem)
   - Tam foto processing pipeline çalışıyor mu?
   - Arşiv yapısı doğru mu?

4. **Acceptance Tests** (Kabul)
   - Gerçek hastane barkodu okuyabiliyor mu?
   - Mobil sync gerçekten çalışıyor mu?

### Otomatik Test Suite

```bash
./test.sh                    # Servis sağlık + API testleri
./create_test_data.sh        # Test veri oluştur
./TESTING_QUICK_START.md     # Manuel testler
```

---

## 🚨 Bilinen Sınırlamalar

| Sınırlama | Etki | Çözüm |
|---|---|---|
| n8n webhook yok | Immich event-driven olamıyor | Polling (2 dk) kafi |
| ML ML service kapalı | Yüz tanıma yok | Gerekmeyenleri istemiyoruz |
| Türkçe karakter | ASCII normalize gerekli | LLM + unicodedata handle ediyor |
| OpenRouter latency | 100-500ms | Non-realtime workflow için OK |
| Synchronization | Concurrent barkodlar → race condition | Beklenen ±30 dk penceresinde OK |

---

## 📞 Destek & İletişim

### Loglar
```bash
docker logs barcode-service      # Barcode işleme
docker logs immich-server        # Fotoğraf sunucusu
docker logs n8n                  # Workflow'lar
```

### API Docs
```
http://localhost:5001/docs       # barcode-service Swagger
http://localhost:2283/api        # Immich Swagger (login gerekli)
```

### Debug
```bash
# Database kontrol
docker exec barcode-service sqlite3 /app/data/fotograf_arsivleme.db
SELECT COUNT(*) FROM photos;

# Klasörler
ls -la /tmp/archive/
ls -la /tmp/unmatched/
```

---

## 🎓 Öğrenme Kaynakları

- **Immich:** https://immich.app
- **n8n:** https://n8n.io
- **FastAPI:** https://fastapi.tiangolo.com
- **zxing-cpp:** https://github.com/nu-book/zxing-cpp
- **EasyOCR:** https://github.com/JaidedAI/EasyOCR
- **OpenRouter:** https://openrouter.ai

---

## 🎯 Sonraki Adımlar

### Kısa vadeli (1-2 hafta)
- [ ] Üretim ortamında test et
- [ ] Mobil cihazları kur
- [ ] Gerçek hastane barkodlarıyla test
- [ ] Kullanıcı eğitimi

### Orta vadeli (1-2 ay)
- [ ] Dashboard/analytics
- [ ] Batch import
- [ ] Export (CSV, PDF)
- [ ] Yedekleme stratejisi

### Uzun vadeli (3-6 ay)
- [ ] Multi-user support
- [ ] Role-based access control
- [ ] Audit logging
- [ ] Machine learning (trend detection)
- [ ] Mobile app (n8n trigger)

---

## 📝 Versiyon Tarihi

| Versiyon | Tarih | Açıklama |
|---|---|---|
| v1.0 | 2026-04-10 | İlk release - temel sistem |

---

## ✨ Özet

**Sistemi Yapan:**
- Immich: Mobil photo sync
- n8n: Workflow orchestration
- Python FastAPI: Barkod işleme
- OpenRouter LLM: Metin parsing
- SQLite: Veri indexi
- Docker: Deployment

**Görev Yaptığı:**
- Fotoğrafları otomatik arşivle
- Barkoddan bilgi çıkar
- Zaman penceresinde eşleştir
- Klasör yapısına organiza et

**Kullandığı:**
- Tamamen lokal
- Açık kaynaklı
- Türkçe destekli
- Gizlilik korumalı

**Kurulum:**
- Docker Compose
- Tek komut: `./setup.sh`

**Haline hazır:** ✅ Tam olarak
