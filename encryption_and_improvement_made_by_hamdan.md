# Encryption & Improvements Made by Hamdan

> **Project:** Dental Clinic Management Application (clinc)  
> **Date:** February 2026  
> **Base Commit:** `63c1783` (first commit — original project)  
> **Latest Commit:** `7953ba4`  
> **Total Changes:** 43 files changed, 3,910 insertions, 485 deletions

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Framework & Libraries](#2-framework--libraries)
3. [Changes Made (Chronological)](#3-changes-made-chronological)
   - [3.1 Full English/Arabic Localization](#31-full-englisharabic-localization)
   - [3.2 Random Test Data Generator](#32-random-test-data-generator)
   - [3.3 Performance Optimization](#33-performance-optimization)
   - [3.4 Appointment Status Localization Fix](#34-appointment-status-localization-fix)
   - [3.5 Password Protection Gate](#35-password-protection-gate)
   - [3.6 SQLCipher Database Encryption (AES-256)](#36-sqlcipher-database-encryption-aes-256)
   - [3.7 macOS Sandbox Entitlement Fix](#37-macos-sandbox-entitlement-fix)
   - [3.8 Encrypted Backup Files (AES-256)](#38-encrypted-backup-files-aes-256)
4. [Summary of All New Files](#4-summary-of-all-new-files)
5. [Security Architecture Overview](#5-security-architecture-overview)

---

## 1. Project Structure

```
clinc/
├── lib/
│   ├── main.dart                      # App entry point, SQLCipher init, password gate
│   ├── l10n/                          # Localization
│   │   ├── app_en.arb                 # English strings
│   │   ├── app_ar.arb                 # Arabic strings
│   │   ├── app_localizations.dart     # Generated base class
│   │   ├── app_localizations_en.dart  # Generated English implementation
│   │   ├── app_localizations_ar.dart  # Generated Arabic implementation
│   │   └── localization_helpers.dart  # Helper functions for localized enums
│   ├── models/                        # Data models
│   │   ├── appointment.dart
│   │   ├── expense.dart
│   │   ├── invoice.dart
│   │   ├── invoice_treatment.dart
│   │   ├── laboratory_item.dart
│   │   ├── patient.dart
│   │   ├── payment.dart
│   │   └── treatment.dart
│   ├── providers/                     # State management (Provider pattern)
│   │   ├── appointment_provider.dart
│   │   ├── expense_provider.dart
│   │   ├── invoice_provider.dart
│   │   ├── laboratory_provider.dart
│   │   ├── patient_provider.dart
│   │   ├── settings_provider.dart
│   │   └── treatment_provider.dart
│   ├── repositories/                  # Data access layer
│   │   ├── appointment_repository.dart
│   │   ├── expense_repository.dart
│   │   ├── invoice_repository.dart
│   │   ├── invoice_treatment_repository.dart
│   │   ├── patient_repository.dart
│   │   ├── payment_repository.dart
│   │   └── treatment_repository.dart
│   ├── screens/                       # UI screens
│   │   ├── appointment_form_screen.dart
│   │   ├── appointments_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── expense_form_screen.dart
│   │   ├── expenses_screen.dart
│   │   ├── invoice_detail_screen.dart
│   │   ├── invoice_form_screen.dart
│   │   ├── invoices_screen.dart
│   │   ├── laboratory_screen.dart
│   │   ├── main_screen.dart
│   │   ├── more_screen.dart
│   │   ├── password_gate_screen.dart  ← NEW (Hamdan)
│   │   ├── patient_detail_screen.dart
│   │   ├── patient_form_screen.dart
│   │   ├── patients_screen.dart
│   │   ├── payment_form_screen.dart
│   │   ├── reports_screen.dart
│   │   ├── settings_screen.dart
│   │   └── treatment_form_screen.dart
│   ├── services/                      # Business logic & utilities
│   │   ├── database_service.dart      # SQLite/SQLCipher DB + BackupService
│   │   ├── encryption_service.dart    ← NEW (Hamdan)
│   │   ├── password_service.dart      ← NEW (Hamdan)
│   │   ├── random_data_generator.dart ← NEW (Hamdan)
│   │   ├── pdf_invoice_service.dart
│   │   ├── pdf_laboratory_service.dart
│   │   └── xray_analysis_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/                       # Reusable UI widgets
├── assets/
│   ├── data/sample_data.json          # Initial sample data
│   └── fonts/                         # Tajawal & Amiri Arabic fonts
├── android/
├── ios/
├── macos/
├── linux/
├── windows/
├── web/
├── test/
├── pubspec.yaml
├── l10n.yaml
├── analysis_options.yaml
└── Database_Encryption_Documentation.pdf  ← NEW (Hamdan)
```

---

## 2. Framework & Libraries

### Core Framework

| Component | Technology | Version |
|---|---|---|
| **Framework** | Flutter | SDK ≥ 3.4.1 |
| **Language** | Dart | SDK ≥ 3.4.1, < 4.0.0 |
| **State Management** | Provider | ^6.1.2 |
| **Database** | sqflite + SQLCipher | sqflite ^2.3.3+1 |
| **Desktop DB** | sqflite_common_ffi | ^2.3.3 |

### Dependencies (pubspec.yaml)

| Package | Version | Purpose |
|---|---|---|
| `flutter_localizations` | SDK | Built-in localization support |
| `intl` | ^0.20.2 | Date/number formatting, ARB file support |
| `provider` | ^6.1.2 | State management (ChangeNotifierProvider) |
| `sqflite` | ^2.3.3+1 | SQLite database access |
| `sqflite_common_ffi` | ^2.3.3 | FFI-based SQLite for desktop (macOS/Linux/Windows) |
| `sqlcipher_flutter_libs` | ^0.6.0 | **SQLCipher binaries** for AES-256 database encryption |
| `sqlite3` | ^2.0.0 | Low-level SQLite API for library override (SQLCipher loading) |
| `crypto` | ^3.0.3 | SHA-256 hashing for password/key derivation |
| `encrypt` | ^5.0.3 | AES-256-CBC encryption for backup files |
| `shared_preferences` | ^2.2.3 | Persistent key-value storage (double-hash for password) |
| `path_provider` | ^2.1.5 | Platform-specific file paths |
| `file_picker` | ^10.3.2 | File/directory picker for export/import |
| `permission_handler` | ^12.0.1 | Runtime permissions (storage on Android/iOS) |
| `fl_chart` | ^0.68.0 | Charts for dashboard/reports |
| `table_calendar` | ^3.1.2 | Calendar widget for appointments |
| `image_picker` | ^1.2.0 | Camera/gallery image selection |
| `pdf` | ^3.11.3 | PDF document generation |
| `printing` | ^5.14.2 | PDF printing and sharing |
| `share_plus` | ^11.1.0 | Share functionality (files, text) |
| `dropdown_search` | ^5.0.6 | Searchable dropdown widget |
| `open_file` | ^3.5.10 | Open files with system default app |
| `url_launcher` | ^6.3.2 | Open URLs (WhatsApp, etc.) |
| `teeth_selector` | ^0.2.2 | Dental chart tooth selection widget |
| `path` | ^1.9.1 | File path manipulation |
| `flutter_gen` | ^5.11.0 | Code generation for assets |
| `flutter_launcher_icons` | ^0.13.1 | App icon generation |
| `cupertino_icons` | ^1.0.6 | iOS-style icons |

### Supported Platforms

| Platform | DB Engine | SQLCipher Loading |
|---|---|---|
| **macOS** | sqflite_common_ffi | Automatic via CocoaPods |
| **iOS** | sqflite | Automatic via CocoaPods |
| **Android** | sqflite | `openCipherOnAndroid()` |
| **Linux** | sqflite_common_ffi | `DynamicLibrary.open()` plugin .so |
| **Windows** | sqflite_common_ffi | Bundled `sqlite3.dll` (automatic) |
| **Web** | N/A | Not supported (no SQLCipher) |

---

## 3. Changes Made (Chronological)

### 3.1 Full English/Arabic Localization

**Commit:** `2973b33`

**What was done:**
- Added complete English and Arabic translations for every string in the application
- Created `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb` with 260+ localized strings
- Generated `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ar.dart`
- Created `lib/l10n/localization_helpers.dart` with helper functions to translate status enums (appointment status, invoice status, payment methods, gender, marital status) based on the current locale
- Added a language switcher in Settings that toggles between English and Arabic
- Configured `l10n.yaml` for Flutter's built-in localization generation
- Updated `main.dart` with `localizationsDelegates` and `supportedLocales`
- Updated all screens to use `AppLocalizations.of(context)!` instead of hardcoded strings

**Files created:**
- `lib/l10n/app_en.arb` — English translations (260+ keys)
- `lib/l10n/app_ar.arb` — Arabic translations (260+ keys)
- `lib/l10n/app_localizations.dart` — Generated base localization class
- `lib/l10n/app_localizations_ar.dart` — Generated Arabic implementation
- `lib/l10n/localization_helpers.dart` — Enum-to-localized-string helpers

**Files modified:**
- `lib/l10n/app_localizations_en.dart` — Expanded with all new string getters
- `lib/main.dart` — Added localization delegates configuration
- `lib/screens/*.dart` — All screens updated to use localized strings
- `pubspec.yaml` — Added `flutter_localizations` SDK dependency

---

### 3.2 Random Test Data Generator

**Commit:** `5b2da29`

**What was done:**
- Created `lib/services/random_data_generator.dart` (504 lines) — a comprehensive test data generator
- Generates realistic random patients, appointments, treatments, invoices, payments, and expenses
- Supports three language modes: Arabic names, English names, or mixed
- User-configurable number of patients (each patient gets associated appointments, treatments, invoices, etc.)
- Accessible from Settings → Development → "Generate Test Data"
- Added a dialog in settings with options for number of patients and data language

**Files created:**
- `lib/services/random_data_generator.dart`

**Files modified:**
- `lib/screens/settings_screen.dart` — Added Generate Test Data UI with dialog

---

### 3.3 Performance Optimization

**Commit:** `37a2aa8`

**What was done:**
- Replaced standard `DataTable` with `PaginatedDataTable` in patients and invoices screens
- This prevents the app from rendering thousands of rows at once when large datasets exist
- Fixed provider refresh logic to avoid unnecessary rebuilds
- Improved search/filter performance in list screens

**Files modified:**
- `lib/screens/patients_screen.dart` — Switched to `PaginatedDataTable`
- `lib/screens/invoices_screen.dart` — Switched to `PaginatedDataTable`
- Various providers — Optimized refresh/notify patterns

---

### 3.4 Appointment Status Localization Fix

**Commit:** `4cc7ef5`

**What was done:**
- Fixed appointment status display in the appointments list to use localized strings instead of raw database values (which were stored in Arabic)
- Ensured status badges show the correct translated label regardless of app language

**Files modified:**
- `lib/screens/appointments_screen.dart`
- `lib/screens/appointment_form_screen.dart`

---

### 3.5 Password Protection Gate

**Commit:** `c3c426c`

**What was done:**
- Created a full-screen password gate (`PasswordGateScreen`) that blocks access to the app until the correct password is entered
- On first launch: user creates a password (with confirmation)
- On subsequent launches: user enters the existing password to unlock
- Password is never stored — only `SHA-256(SHA-256(password))` (double-hash) is saved in SharedPreferences
- Created `PasswordService` for password hashing, saving, and verification
- Added password change functionality in Settings → Security
- Added password verification before destructive operations (e.g., app reset)

**Files created:**
- `lib/screens/password_gate_screen.dart` — Login/create password UI
- `lib/services/password_service.dart` — SHA-256 hashing, double-hash storage, verification

**Files modified:**
- `lib/main.dart` — Wrapped app with `_AppGate` widget that shows password screen first
- `lib/screens/settings_screen.dart` — Added Security section with change password, verify before reset

---

### 3.6 SQLCipher Database Encryption (AES-256)

**Commit:** `6905630`

**What was done:**
- Replaced the standard SQLite engine with **SQLCipher** for transparent page-level AES-256 encryption
- The database file on disk is **always encrypted** — there is never a plaintext phase
- Encryption key = `SHA-256(password)`, held in RAM only, never written to disk
- Created `EncryptionService` — singleton that manages the 256-bit key in memory
- Added `PRAGMA key` in `_onConfigure()` — sets the encryption key before any SQL query runs
- Added `PRAGMA rekey` for password changes — re-encrypts the entire database in place
- Added plaintext database detection — if an old unencrypted DB exists, it is deleted and a fresh encrypted one is created
- Added `WidgetsBindingObserver` in `_AppGate` — clears the key from RAM (overwritten with zeros) when the app terminates
- Cross-platform SQLCipher loading:
  - **macOS/iOS**: Automatic via CocoaPods
  - **Android**: `openCipherOnAndroid()` from `sqlcipher_flutter_libs`
  - **Linux**: `DynamicLibrary.open()` with absolute path to plugin `.so`
  - **Windows**: Bundled `sqlite3.dll` found automatically

**Files created:**
- `lib/services/encryption_service.dart` — Key derivation, RAM-only key management, secure wipe

**Files modified:**
- `lib/services/database_service.dart` — Added `_onConfigure` (PRAGMA key), `openDatabaseWithKey()`, `rekeyDatabase()`, `deleteDatabaseFile()`, `closeDatabase()`, plaintext detection
- `lib/main.dart` — Platform-specific SQLCipher library overrides, FFI init, lifecycle observer
- `lib/screens/password_gate_screen.dart` — Calls `EncryptionService.instance.setKey()` after password entry
- `lib/screens/settings_screen.dart` — Password change triggers `rekeyDatabase()`
- `pubspec.yaml` — Added `sqlcipher_flutter_libs`, `sqlite3`, `crypto`
- `ios/Podfile`, `macos/Podfile` — CocoaPods configuration for SQLCipher
- Platform-specific plugin registrant files (auto-generated)

---

### 3.7 macOS Sandbox Entitlement Fix

**Commit:** `8c53654`

**What was done:**
- Fixed `PlatformException(ENTITLEMENT_NOT_FOUND)` crash when using the Export Data feature on macOS
- Added `com.apple.security.files.user-selected.read-write` entitlement to both Debug and Release entitlements files
- This grants the sandboxed macOS app permission to read/write files selected via the native file picker dialog

**Files modified:**
- `macos/Runner/DebugProfile.entitlements` — Added read-write file access entitlement
- `macos/Runner/Release.entitlements` — Added read-write file access entitlement

---

### 3.8 Encrypted Backup Files (AES-256)

**Commit:** `7953ba4`

**What was done:**
- Completely rewrote the backup export/import system to produce **encrypted `.clinc` backup files** instead of plain `.zip` files
- **Export** process: Query all data → JSON → ZIP (with images) → **AES-256-CBC encrypt** the entire ZIP → output as `.clinc` file
- File format: `[16-byte IV] + [32-byte HMAC-SHA256 tag] + [AES-256-CBC ciphertext]`
- The HMAC tag allows quick password verification before attempting decryption
- **Import** process: User picks `.clinc` file → app asks for the **original backup password** → verifies HMAC → decrypts in RAM → inserts data into current SQLCipher database
- If the user changes their password and then tries to import an old backup, they must enter the **old** password
- Constant-time HMAC comparison to prevent timing attacks
- Backward-compatible: legacy `.zip` backups can still be imported without a password prompt
- Added `WrongPasswordException` class for clear error handling
- Added localized strings (EN/AR) for backup password dialog and wrong password error

**Files modified:**
- `lib/services/database_service.dart` — Rewrote `BackupService` class: `exportData()` now encrypts, `importData()` now accepts password parameter, added `pickBackupFile()`, `isBackupEncrypted()`, `_constantTimeEquals()`
- `lib/services/encryption_service.dart` — Added `keyBytes` getter and static `deriveKeyBytes()` method
- `lib/screens/settings_screen.dart` — New import flow: pick file first, then prompt for password if `.clinc`, handle `WrongPasswordException`
- `lib/l10n/app_en.arb` — Added `backupPasswordTitle`, `backupPasswordMessage`, `wrongBackupPassword`
- `lib/l10n/app_ar.arb` — Added Arabic translations for the above
- `lib/l10n/app_localizations.dart` — Added new string getters
- `lib/l10n/app_localizations_en.dart` — Added English implementations
- `lib/l10n/app_localizations_ar.dart` — Added Arabic implementations
- `pubspec.yaml` — Added `encrypt` package (^5.0.3) for AES-256-CBC

---

## 4. Summary of All New Files

| File | Purpose |
|---|---|
| `lib/screens/password_gate_screen.dart` | Full-screen password login / create password UI |
| `lib/services/encryption_service.dart` | Singleton: holds AES-256 key in RAM, derives from password, secure wipe |
| `lib/services/password_service.dart` | SHA-256 hashing, double-hash storage in SharedPreferences, verification |
| `lib/services/random_data_generator.dart` | Generates realistic random test data (patients, appointments, etc.) |
| `lib/l10n/app_en.arb` | English localization strings (260+ keys) |
| `lib/l10n/app_ar.arb` | Arabic localization strings (260+ keys) |
| `lib/l10n/app_localizations.dart` | Generated localization base class |
| `lib/l10n/app_localizations_ar.dart` | Generated Arabic localization |
| `lib/l10n/localization_helpers.dart` | Helper functions for enum ↔ localized string translation |
| `Database_Encryption_Documentation.pdf` | Detailed encryption architecture document with diagrams |
| `ios/Podfile` | CocoaPods config for iOS (SQLCipher) |
| `macos/Podfile` | CocoaPods config for macOS (SQLCipher) |
| `macos/Podfile.lock` | CocoaPods lock file |

---

## 5. Security Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     User enters password                     │
└─────────────────┬───────────────────────┬───────────────────┘
                  │                       │
        ┌─────────▼─────────┐   ┌────────▼────────┐
        │  SHA-256(password) │   │ SHA-256(password)│
        │  = encryption key  │   │ = single hash    │
        │  (RAM only)        │   │                  │
        └─────────┬─────────┘   │  SHA-256(hash)   │
                  │             │  = double hash    │
                  │             │  (stored on disk) │
                  │             └───────────────────┘
                  │
    ┌─────────────▼──────────────┐
    │  PRAGMA key = hex(key)     │
    │  SQLCipher unlocks DB      │
    │  Every page = AES-256      │
    └─────────────┬──────────────┘
                  │
    ┌─────────────▼──────────────┐
    │  clinc_database.db         │
    │  (always encrypted on disk)│
    └────────────────────────────┘

    Backup: data → JSON → ZIP → AES-256-CBC → .clinc file
    Import: .clinc → password prompt → HMAC verify → decrypt → insert
```

**Key Security Properties:**
- ✅ Database file is **always encrypted** on disk (SQLCipher AES-256)
- ✅ Encryption key exists **only in RAM** — never written to disk
- ✅ Only `hash(hash(password))` is stored — cannot derive the encryption key from it
- ✅ Backup files are **AES-256-CBC encrypted** with HMAC-SHA256 verification
- ✅ Key is **securely wiped** (overwritten with zeros) when app closes
- ✅ Constant-time HMAC comparison prevents timing attacks
- ✅ Cross-platform: identical encryption on macOS, Windows, Linux, Android, iOS
