# Fotograf Arsivleme Sistemi

Barkod etiketli fotograflari otomatik olarak arsivleyen, tamamen lokal calisan sistem.

## Nasil Calisir

1. Telefondan veya PC'den fotograf cekilir (Immich uygulamasi ile)
2. Barkod etiketi fotograflanir
3. Sistem barkodu okur, kisi bilgilerini cikarir
4. Ayni zaman dilimindeki fotograflari eslestirip `Arsiv/YYYY-MM-DD/Kisi_Adi/` klasorune tasir

## Kurulum

**Gereklilikler:** Docker Desktop, Git, Python 3

Eksik olanlari otomatik kurmak icin:
```bash
bash <(curl -s https://raw.githubusercontent.com/BeysolGit/fotograf-arsivleme/main/setup-dependencies.sh)
```

**Kurulum:**
```bash
git clone https://github.com/BeysolGit/fotograf-arsivleme.git
cd fotograf-arsivleme
bash install.sh
```

Tarayici otomatik acilir → OpenRouter API Key gir → Tamamla.

## Kaldirma

```bash
bash uninstall.sh
```

## Servisler

| Servis | Adres |
|---|---|
| Immich | http://localhost:2283 |
| n8n | http://localhost:5678 |
| Barkod API | http://localhost:5001/docs |

## Mobil

1. Immich uygulamasini indir (App Store / Google Play)
2. Server: `http://bilgisayar-ip:2283`
3. Giris yap, WiFi yedekleme aktif et

## Sorun Giderme

```bash
# Servislerin durumu
docker compose ps

# Loglari gor
docker compose logs -f

# Yeniden baslat
docker compose restart
```
