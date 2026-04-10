# GitHub Repository Oluşturma Adımları

## 1. GitHub.com'a Giriş Yap

1. https://github.com/beysol (profiline git)
2. Sağ üst köşede "+" → "New repository"

## 2. Repository Ayarlarını Doldur

| Alan | Değer |
|---|---|
| **Repository name** | `hospital-archive` |
| **Description** | `Local hospital photo archiving system with Immich, n8n, and barcode recognition` |
| **Visibility** | Public (önerilen - açık kaynak) veya Private |
| **Initialize this repository with:** | HIÇBIRŞEY SEÇME (zaten dosyalarımız var) |

## 3. Create Repository Butonuna Bas

## 4. Sonra Push Et

```bash
cd /Users/beysol/Agents/hospital-archive

# Token'le push:
git push -u origin main
```

---

## Quick Setup (Alternatif)

Eğer `gh` CLI yüklüyse:

```bash
brew install gh
gh auth login  # Interactive login

cd hospital-archive
gh repo create hospital-archive --source=. --remote=origin --push --public
```

---

**Hepsi bitti mi? Sonra GitHub URL'ine tıkla:**
https://github.com/beysol/hospital-archive
