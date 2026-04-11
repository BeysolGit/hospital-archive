# 🚀 QUICK START - 2 KOMUT (Tamamen Otomatik)

## ADIM 1: Gereklilikler Kurulsun (İlk Defa)

Bunu sadece **ilk defa** çalıştır. Docker, Git, Python3 otomatik kurulacak:

```bash
bash <(curl -s https://raw.githubusercontent.com/BeysolGit/fotograf-arsivleme/main/setup-dependencies.sh)
```

## ADIM 2: Fotograf Arsivleme Kurulsun

```bash
# Eski klasörü sil (varsa)
rm -rf fotograf-arsivleme

# Yeni repository'i indir
git clone https://github.com/BeysolGit/fotograf-arsivleme.git
cd fotograf-arsivleme

# Kurulumu başlat
bash install.sh
```

**NOT:** Docker Desktop macOS'ta açık olmalı! Eğer kapalıysa kurulum otomatik açacak, biraz beklersen başlar.

## Hepsi bu!

**Ne olacak:**
1. ✅ Repository indirilecek
2. ✅ Docker servisleri otomatik başlayacak (2-3 dakika)
3. ✅ Web sayfası otomatik açılacak (http://localhost:9000)

---

## Web Sayfasında (Tarayıcı):

1. **OpenRouter API Key'i yapıştır**
   - https://openrouter.ai/keys → Create Key
   - Token'i kopyala (sk-or-...)
   - Web sayfasına yapıştır

2. **Kurulumu Tamamla butonuna tıkla**

3. **Immich açılacak (http://localhost:2283)**
   - Admin hesap yap
   - Settings → Account → API Keys
   - Create New Key → Token'i kopyala

4. **Web sayfasında Immich API Key'i yapıştır**

5. **Hazır! Sisteminiz çalışıyor!**

---

## 🌐 Açılacak Sayfalar:

- 📸 **Immich**: http://localhost:2283
- ⚙️ **n8n**: http://localhost:5678
- 📚 **API Docs**: http://localhost:5001/docs

---

## 📱 Mobil Kurulumu (2 dakika):

1. Immich App indir (App Store / Google Play)
2. Server: http://bilgisayar-ip:2283
3. Email ve şifre gir
4. Settings → WiFi-only backup aktif et
5. Fotoğraf çek → Otomatik yüklenir

---

## 🎯 Kullanım:

1. Fotografi Immich'ten çek (mobil/PC)
2. Barkod etiketini fotoğrafla
3. Sistem otomatik arşivler: `/tmp/archive/YYYY-MM-DD/Kisi_Adi/`

---

## ❌ Sorun?

```bash
# Logları kontrol et
docker logs immich-server
docker logs barcode-service

# Restart'la
docker compose restart

# Detaylı rehber: cat INSTALL.md
```

---

**Tüm bilgi:** [INSTALL.md](INSTALL.md)
