# 🏥 Hospital Archive - KOLAY KURULUM REHBERI

## 🚀 SUPER HIZLI KURULUM (3 seçenek)

### Seçenek 1: ULTRA OTOMATIK (Tavsiye Edilen)
```bash
cd /Users/beysol/Agents/hospital-archive
bash auto-setup.sh
```

**Ne olur:**
1. ✅ OpenRouter API Key'i sorar
2. ✅ Docker servisleri otomatik başlar
3. ✅ Immich açılır (admin hesap yap)
4. ✅ Immich API Key'i sorar ve kaydeder
5. ✅ n8n restart'lar
6. ✅ **Bitmiş!** - Tüm sistemler çalışıyor

---

### Seçenek 2: STEP-BY-STEP (Denetimli)
```bash
cd /Users/beysol/Agents/hospital-archive
bash quick-install.sh
```

**Ne olur:**
1. ✅ Ön kontroller (Docker, etc)
2. ✅ Klasörleri oluşturur
3. ✅ OpenRouter API Key'i sorar
4. ✅ Docker'ı başlatır ve bekler
5. ✅ Tarayıcıda Immich açar
6. ✅ Immich API Key'i sorar

---

### Seçenek 3: MANUEL (Detaylı Kontrol)

```bash
cd /Users/beysol/Agents/hospital-archive

# 1. .env dosyasını düzenle
vim .env
# OPENROUTER_API_KEY=sk-or-xxxxxxxx

# 2. Servisleri başlat
docker compose up -d

# 3. Bekleme
sleep 30

# 4. Immich'i aç ve admin hesap yap
open http://localhost:2283

# 5. Immich API Key'i al
#    Settings → Account → API Keys → Create New Key

# 6. .env dosyasını güncelle
vim .env
# IMMICH_API_KEY=xxxxx

# 7. n8n yeniden başlat
docker compose restart n8n
```

---

## ✅ KONTROL LISTESI

Kurulumdan sonra bunları kontrol et:

```bash
# 1. Servisler çalışıyor mu?
docker compose ps

# 2. Immich erişilebilir mi?
curl http://localhost:2283 | head -20

# 3. Barcode Service çalışıyor mu?
curl http://localhost:5001/health

# 4. n8n çalışıyor mu?
curl http://localhost:5678/healthz
```

**Beklenen çıktı:**
```
✅ docker compose ps → Tüm servisler "Up (healthy)"
✅ Immich → 200 OK
✅ Barcode Service → {"status": "healthy"}
✅ n8n → 200 OK
```

---

## 🧪 İLK TEST (5 dakika)

```bash
# 1. Test verisi oluştur
bash create_test_data.sh

# 2. Sistem testi çalıştır
bash test.sh
```

**Beklenen çıktı:**
```
✅ All tests passed!
```

---

## 📚 AÇILACAK WEB SAYFALAR

Sistem kurulduktan sonra tarayıcıda aç:

| Uygulama | URL | İşlev |
|---|---|---|
| **Immich** | http://localhost:2283 | Fotoğraf yönetimi + Mobil sync |
| **n8n** | http://localhost:5678 | Workflow'lar |
| **API Docs** | http://localhost:5001/docs | Barcode Service API |

---

## 🔑 API KEY'LER

### OpenRouter
- **Nereden:** https://openrouter.ai/keys
- **Nedir:** LLM (metni parse eder)
- **Gerekli:** ✅ ZORUNLUদ
- **Kaydedilecek yer:** `.env` (OPENROUTER_API_KEY)

### Immich
- **Nereden:** Web UI (Settings → Account → API Keys)
- **Nedir:** n8n ile iletişim için
- **Gerekli:** ✅ ZORUNLUদ (n8n workflow'ları için)
- **Kaydedilecek yer:** `.env` (IMMICH_API_KEY)

---

## ❌ SORUN GİDERME

### "Docker çalışmıyor"
```bash
# Docker Desktop'ı aç
# Veya: brew install docker
```

### "OpenRouter hatası"
```bash
# .env'de OPENROUTER_API_KEY doğru mu?
grep OPENROUTER .env

# Token aktif mi? https://openrouter.ai/keys kontrol et
```

### "Immich API Key'i alamıyorum"
```bash
# Web UI açıl ve manuel oluştur:
# 1. http://localhost:2283
# 2. Settings → Account → API Keys → Create New Key
# 3. .env dosyasında IMMICH_API_KEY'i güncelle
# 4. docker compose restart n8n
```

### "barcode-service sağlıksız"
```bash
docker logs barcode-service
# Hatayı oku
```

### "n8n açılmıyor"
```bash
# Logları kontrol et
docker logs n8n

# Restart'la
docker compose restart n8n
```

---

## 🎯 SONRAKI ADIMLAR

1. ✅ Immich ayarlarını kontrol et
   - Dosya depolama lokasyonu
   - External library (PC'den fotoğraf yüklemesi)

2. ✅ Test et
   ```bash
   bash test.sh
   ```

3. ✅ n8n Workflow'larını import et
   - Workflows → Import From File
   - Seç: `n8n-workflows/01_poll_and_route.json`

4. ✅ Mobil cihaz kur
   - Immich App indir (iOS/Android)
   - Server: `http://<bilgisayar-ip>:2283`

5. ✅ Gerçek test
   - Hastane barkodu fotoğrafla
   - Hasta fotoğrafı yükle
   - Arşivde doğru klasöre gittiğini kontrol et

---

## 📞 HELP

Sorun olursa:
```bash
# Logs kontrol et
docker compose logs

# Servisleri restart'la
docker compose down
docker compose up -d

# Veya: problemi detaylı rapor et
```

---

## 🚀 BİTTİ!

Sistem kuruldu. İlk testini çalıştır:

```bash
bash test.sh
```

Başarı gelirse → Workflow'ları import et → **BITTI!**

Başarısız olursa → docker logs'a bak → ayarla → tekrar dene
