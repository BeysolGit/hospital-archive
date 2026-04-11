# 🚀 BAŞLA - Fotograf Arsivleme Kurulumu

**Sistem** henüz 3 yapı seçenek ile kurula var - **birini seç:**

---

## ⚡ Option 1: ULTRA OTOMATIK (30 saniye)
Hiçbir şey düşünme, sadece çalıştır.

```bash
cd fotograf-arsivleme
bash auto-setup.sh
```

**Ne happens:**
1. ✅ OpenRouter API Key'i sorar
2. ✅ Docker servisleri otomatik başlar
3. ✅ Immich açılır (sen admin hesap yap)
4. ✅ Immich API Key'i sorar
5. ✅ n8n yapılandırır
6. ✅ **DONE** - Sistem çalışır!

**Gerekli:** OpenRouter ve Immich API Key'leri (1 dakika'da online'dan alabilirsin)

---

## 📋 Option 2: STEP-BY-STEP (Kontrollü)
Adım adım ilerle, her şeyi kontrol et.

```bash
bash quick-install.sh
```

**Avantajı:** Hata bulursan anında görsün, fix'leyebilirsin.

**Detaylı rehber:** [KURULUM.md](KURULUM.md)

---

## 🔧 Option 3: MANUEL (Gelişmiş)
Tüm adımları kendin yap, detaylı kontrol.

1. `.env` dosyasını düzenle (OPENROUTER_API_KEY ekle)
2. `docker compose up -d` çalıştır
3. `http://localhost:2283` acilir (Immich)
4. Admin hesap oluştur
5. API Key al (Settings → Account → API Keys)
6. `.env` dosyasında IMMICH_API_KEY'i güncelle
7. `docker compose restart n8n` çalıştır

---

## 🎯 HEMEN BAŞLA

### Tavsiye: **Auto-setup** (Seçenek 1)

```bash
bash auto-setup.sh
```

Bu seçeneği tavsiye ediyorum çünkü:
- ✅ Otomatik yapılandırma
- ✅ Error handling var
- ✅ En hızlı
- ✅ İsim böyle isim: "auto" = otomatik = sen sadece API key'leri yapıştır

---

## 🔑 API KEY'LERİ NEREDE ALACAKSIN?

### 1. OpenRouter
**URL:** https://openrouter.ai/keys  
**Button:** "Create Key"  
**Kopyala:** Sarı token'i  
**Yapıştır:** Script sorduğunda

### 2. Immich
**Adımlar:**
1. Script sonra: http://localhost:2283 aç
2. Admin hesap yap (email + şifre)
3. Settings → Account → **API Keys**
4. **"Create New Key"** butonuna tıkla
5. Token'i kopyala
6. Script sorduğunda yapıştır

---

## ✅ KONTROL: SISTEM ÇALIŞIYOR MU?

Script bittikten sonra şunu çalıştır:

```bash
# Tüm container'lar "healthy" mi?
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

## 🧪 İLK TEST (5 DAKIKA)

```bash
# 1. Test verisi oluştur
bash create_test_data.sh

# 2. Sistem testi çalıştır
bash test.sh
```

**Beklenen sonuç:**
```
✅ All tests passed!
```

---

## 🌐 AÇILACAK SAYFALAR

Sistem başarılı olursa tarayıcıda aç:

| Uygulama | URL | Kullanım |
|---|---|---|
| **Immich** | http://localhost:2283 | Fotoğraf yönetimi + Mobil sync |
| **n8n** | http://localhost:5678 | Workflow'ları yapılandır |
| **API Docs** | http://localhost:5001/docs | Barcode API |

---

## ❌ SORUN MI VAR?

```bash
# Logları kontrol et
docker logs barcode-service
docker logs n8n
docker logs immich-server

# Restart et
docker compose restart

# Veya detaylı rehber
cat KURULUM.md
```

---

## 🎉 SON ADIM: WORKFLOW'LARI IMPORT ET

Sistem test'ten geçtikten sonra:

1. **n8n'i aç:** http://localhost:5678
2. **Workflows** → **Import From File**
3. **Seç:** `n8n-workflows/01_poll_and_route.json`
4. **Done!**

---

## 🚀 HADİ BAŞLA!

```bash
bash auto-setup.sh
```

**Sorunu gelirse:** `cat KURULUM.md` (Detaylı troubleshooting)

**Happy archiving!** 🏥📸
