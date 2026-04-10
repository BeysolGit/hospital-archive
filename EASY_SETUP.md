# 🚀 KOLAY KURULUM - 3 ADIM

## Adım 1: Tüm Ayarları Gir

`.env` dosyasını düzenle ve bu değerleri ekle:

```bash
# Terminal'de
nano .env
```

Veya GitHub'dan aç ve kopyala ([.env](.env)):

```ini
# API Keys (gerekli)
OPENROUTER_API_KEY=sk-or-xxxxx        # https://openrouter.ai/keys
IMMICH_API_KEY=imch_xxxxx             # (Kurulum sonrası Immich'den)

# Klasörler
UPLOAD_LOCATION=/tmp/immich-uploads
ARCHIVE_PATH=/tmp/archive
UNMATCHED_PATH=/tmp/unmatched
EXTERNAL_LIBRARY_PATH=/tmp/external

# n8n
N8N_PASSWORD=admin123

# Eşleştirme
MATCH_WINDOW_MINUTES=30
TZ=Europe/Istanbul
```

**Nerelerden alacağın:**
- **OpenRouter Key:** https://openrouter.ai/keys → Create Key → Token'i kopyala
- **Immich Key:** Kurulum sonra (adım 2'de)

---

## Adım 2: Docker'ı Başlat

```bash
docker compose up -d
```

**Ne olacak:**
- ✅ Immich server başlayacak (http://localhost:2283)
- ✅ barcode-service başlayacak (http://localhost:5001)
- ✅ n8n başlayacak (http://localhost:5678)

**Bekleme:** 1-2 dakika

---

## Adım 3: Immich API Key'i Al ve Ayarla

1. **Immich'i aç:** http://localhost:2283
2. **Admin hesap oluştur** (email + şifre)
3. **Settings → Account → API Keys**
4. **"Create New Key"** → Token'i kopyala
5. **`.env` dosyasında güncelle:**
   ```
   IMMICH_API_KEY=imch_xxxxx
   ```
6. **n8n'i restart'la:**
   ```bash
   docker compose restart n8n
   ```

---

## ✅ Kontrol

Tüm container'lar "healthy" mi?

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

---

## 🧪 Test Et

```bash
# Test verisi oluştur
bash create_test_data.sh

# Sistem testi çalıştır
bash test.sh
```

**Beklenen:** ✅ All tests passed!

---

## 🌐 Sistemin Web Sayfaları

Sistem hazırsa:

| URL | İçin |
|---|---|
| http://localhost:2283 | 📸 Immich (Fotoğraf yönetimi) |
| http://localhost:5678 | ⚙️ n8n (Workflow'lar) |
| http://localhost:5001/docs | 📚 Barcode API |

---

## ❌ Sorun mu var?

```bash
# Logları kontrol et
docker logs barcode-service
docker logs n8n
docker logs immich-server

# Restart et
docker compose restart

# Tüm servisleri sıfırla
docker compose down
docker compose up -d
```

---

**BİTTİ!** 🎉

Şimdi git n8n workflow'larını import et ve test yap!
