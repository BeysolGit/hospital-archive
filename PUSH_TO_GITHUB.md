# GitHub'a Push Etme - Adım Adım Rehber

## Problem
Eski token scope'u eksikti. Yeni bir token oluşturmanız gerek.

## Çözüm - 5 Adım

### 1. Yeni Personal Access Token Oluştur

1. GitHub'a git: https://github.com/settings/tokens
2. "Generate new token" → "Tokens (classic)"
3. Token ayarları:
   - **Note:** hospital-archive-token
   - **Expiration:** 90 days
   - **Scopes:** ✅ repo (full control)
                  ✅ workflow (Actions)
                  ✅ delete_repo (isteğe bağlı)

4. "Generate token" butonuna bas
5. **Token'i kopyala** (sadece bir kez gösterilir!)

### 2. Repository'yi GitHub'da Oluştur

1. https://github.com/new
2. Repository name: `hospital-archive`
3. Description: `Local hospital photo archiving system with Immich, n8n, and barcode recognition`
4. Visibility: **Public** (açık kaynak)
5. HIÇBIRŞEY seçme (Initialize with...)
6. "Create repository" butonuna bas

### 3. Push Komutunu Çalıştır

Terminal'de:

```bash
cd /Users/beysol/Agents/hospital-archive

# Push komutunu çalıştır
git push -u origin main
```

### 4. Kimlik Doğrulama

Git sorduğunda:
- **Username:** `beysol` (veya GitHub username)
- **Password:** `<token_yapıştır>` (yeni token'i yapıştır)

### 5. Kontrol Et

```bash
# Push başarılı mı?
git push -u origin main

# Veya GitHub'da kontrol:
https://github.com/beysol/hospital-archive
```

---

## Alternative: SSH Kurulumu (İleride)

Bir kerelik SSH kurulum daha güvenli:

```bash
# SSH key oluştur
ssh-keygen -t ed25519 -C "your_email@example.com"

# Public key'i GitHub'a ekle
# GitHub → Settings → SSH and GPG keys → New SSH key
# ~/.ssh/id_ed25519.pub içeriğini yapıştır

# SSH remote'u kullan
git remote set-url origin git@github.com:beysol/hospital-archive.git
git push -u origin main
```

---

## Token Scope'ları Neden Önemli?

| Scope | İçin |
|---|---|
| `repo` | Public + Private repo read/write |
| `workflow` | GitHub Actions dosyalarını update et |
| `delete_repo` | Repository silme |
| `read:org` | Org bilgilerini oku |

Eski token sadece bazı scope'lar vardı, bu yüzden başarısız oldu.

---

## Başarılı Push Sonrası

```bash
# Repo'yu web'de aç
open https://github.com/beysol/hospital-archive

# Commits kontrol et
git log --oneline
```

Repository public olacak, herkes görebilecek! 🎉
