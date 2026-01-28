---
description: Menjalankan Laravel API dan Drizzle Studio untuk School Payment System
---

# Menjalankan Server School Payment System

## Prerequisites
- Laragon terinstall di `C:\laragon`
- Node.js terinstall

## Langkah-langkah

// turbo-all

### 1. Jalankan Laravel API Server
```powershell
C:\laragon\bin\php\php-8.2.27-Win32-vs16-x64\php.exe artisan serve
```
Direktori: `c:\Users\PC LAB 09\.gemini\antigravity\school-payment\school-payment-api`

Server akan berjalan di: **http://127.0.0.1:8000**

### 2. Jalankan Drizzle Studio
```powershell
cmd /c "npm run studio"
```
Direktori: `c:\Users\PC LAB 09\.gemini\antigravity\school-payment\school-payment-api\db-studio`

Drizzle Studio akan berjalan di: **https://local.drizzle.studio**

## Catatan Penting

- **Gunakan `cmd /c` untuk npm** karena PowerShell execution policy mungkin memblokir script npm
- **Gunakan path lengkap PHP Laragon** karena PHP tidak ada di system PATH
- Database SQLite terletak di `school-payment-api/database/database.sqlite`
- Kedua perintah berjalan di background, gunakan Ctrl+C untuk menghentikan
