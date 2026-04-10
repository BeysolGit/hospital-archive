# GitHub'a Push Etme Adımları

## Hızlı Yol (GitHub CLI ile)

```bash
# 1. GitHub CLI kur (Homebrew)
brew install gh

# 2. GitHub'a bağlan (interactive login)
gh auth login

# 3. SSH veya HTTPS seçeneğini seç
# 4. Repository oluştur ve push et:
gh repo create hospital-archive --source=. --remote=origin --push
```

## Manuel Yol (Personal Access Token ile)

### 1. Personal Access Token Oluştur
1. GitHub → Settings → Developer settings → Personal access tokens
2. "Tokens (classic)" → "Generate new token"
3. Scopes:
   - ✅ `repo` (full control of private repositories)
   - ✅ `workflow` (update GitHub Action workflows)
4. Token'ı kopyala

### 2. Repository Oluştur
1. GitHub.com → "New repository"
2. Name: `hospital-archive`
3. Description: "Local hospital photo archiving system with Immich + n8n"
4. Visibility: Public (or Private)
5. **Do NOT initialize with README** (zaten bizde var)
6. Create repository

### 3. Push Et

```bash
# Proje klasörüne gir
cd /Users/beysol/Agents/hospital-archive

# Remote'u konfigür (zaten yapıldı, kontrol et):
git remote -v
# Output: origin  https://github.com/beysol/hospital-archive.git

# Token ile push et:
git push -u origin main

# Terminal tarafından username/token ister:
# Username: <GitHub kullanıcı adı>
# Password: <Personal Access Token>
```

### 4. Credentials Cachelenme (İsteğe Bağlı)

Sonraki push'lar için credentials'ı cache'le:

```bash
# macOS Keychain ile (önerilen)
git config --global credential.helper osxkeychain

# Veya 15 dakika boyunca cache'le:
git config --global credential.helper 'cache --timeout=900'
```

## HTTPS URL Format (Token'li)

```bash
# Format:
https://token@github.com/beysol/hospital-archive.git

# Örnek:
git remote set-url origin https://ghp_xxxxxxxxxxxxxxxxxxxx@github.com/beysol/hospital-archive.git
git push -u origin main
```

## SSH Setup (İleride)

SSH key'i ayarlamak istersan:

```bash
# SSH key oluştur
ssh-keygen -t ed25519 -C "your_email@example.com"

# GitHub'a ekle: Settings → SSH and GPG keys → New SSH key
# ~/.ssh/id_ed25519.pub içeriğini kopyala

# SSH remot'unu kullan:
git remote set-url origin git@github.com:beysol/hospital-archive.git
```

## Sorun Giderme

**"Device not configured" hatası**
- HTTPS token kullan veya gh CLI kur

**"Permission denied (publickey)"**
- SSH key'i GitHub'a eklemedin
- HTTPS token ile dene

**"Could not read from remote repository"**
- Remote kontrol et: `git remote -v`
- Token'ın geçerliliğini kontrol et (expire olmuş olabilir)

## Başarılı Push Sonrası

```bash
# Repository'i web'de aç:
open https://github.com/beysol/hospital-archive
```
