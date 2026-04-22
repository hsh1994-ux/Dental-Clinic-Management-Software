# Database — Structure & Encryption

This document covers the database engine, schema, encryption architecture, and the reasoning behind each design decision in the Clinc dental clinic app.

---

## Engine

| Property | Value |
|---|---|
| Engine | SQLCipher 4 (SQLite + AES-256 encryption) |
| Access layer | `sqflite` + `sqflite_common_ffi` (desktop FFI) |
| Current schema version | 5 |
| File name | `clinc_database.db` |
| Location | `ClinC Data/` folder, next to the app |

SQLCipher was chosen over plain SQLite because it encrypts every page of the database file transparently. From the application's perspective, the API is identical to standard SQLite — the only addition is a single `PRAGMA key` statement issued before the first query. The result is that `clinc_database.db` on disk is indistinguishable from random bytes without the correct key.

---

## Schema

### Entity Relationship Overview

```
Patients
  ├── Treatments (1 : many)
  │     └── Invoice_Treatments (many : many join → Invoices)
  ├── Invoices (1 : many)
  │     └── Payments (1 : many)
  ├── Appointments (1 : many)
  └── PatientXrayImages (1 : many)

Expenses (standalone — not linked to patients)
```

All child tables use `ON DELETE CASCADE`, so deleting a patient removes all their associated records automatically.

---

### Patients

Primary record for every person registered at the clinic.

| Column | Type | Notes |
|---|---|---|
| `patient_id` | INTEGER PK | Auto-increment |
| `name` | TEXT NOT NULL | Full name |
| `birth_date` | TEXT | ISO 8601 date string (`YYYY-MM-DD`) |
| `gender` | TEXT | `Male` / `Female` (localized at display time) |
| `address` | TEXT | |
| `phone` | TEXT | |
| `marital_status` | TEXT | Single / Married / Divorced / Widowed |
| `file_number` | TEXT UNIQUE NOT NULL | Clinic-assigned file number |
| `first_visit_date` | TEXT | ISO 8601 date string |
| `xray_image` | TEXT | Legacy single X-ray path (superseded by `PatientXrayImages`) |

> **Migration note (v1→v4):** The original schema stored `age` as an integer. Version 4 migrated this to `birth_date` (derived year from age) so the patient's age stays accurate over time without manual updates.

---

### Treatments

A clinical treatment record linked to one patient. A patient may have many treatments across visits.

| Column | Type | Notes |
|---|---|---|
| `treatment_id` | INTEGER PK | Auto-increment |
| `patient_id` | INTEGER FK | → `Patients.patient_id` |
| `diagnosis` | TEXT | Free-text diagnosis |
| `treatment` | TEXT | Procedure description |
| `tooth_number` | TEXT | FDI notation (e.g., `11`, `36`) |
| `agreed_amount` | REAL | Total agreed cost for this treatment |
| `agreed_amount_paid` | REAL DEFAULT 0 | Running total paid (added in v2) |
| `treatment_date` | TEXT | ISO 8601 date string |
| `status` | TEXT | `قيد التنفيذ` / `منجز` (in-progress / completed) |
| `expenses` | REAL DEFAULT 0 | Clinic-side costs, e.g. lab fees (added in v3) |
| `laboratory_name` | TEXT | Name of external lab used (added in v3) |

---

### Invoices

A billing document issued to a patient, which may bundle one or more treatments.

| Column | Type | Notes |
|---|---|---|
| `invoice_id` | INTEGER PK | Auto-increment |
| `patient_id` | INTEGER FK | → `Patients.patient_id` |
| `invoice_date` | TEXT NOT NULL | ISO 8601 date string |
| `total_amount` | REAL | Sum of linked treatment amounts |
| `status` | TEXT | `مسودة` / `مدفوع جزئياً` / `مدفوع بالكامل` (Draft / Partially Paid / Fully Paid) |

---

### Invoice_Treatments

Join table that connects invoices to the treatments they cover. A single treatment can only belong to one invoice.

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `invoice_id` | INTEGER FK | → `Invoices.invoice_id` |
| `treatment_id` | INTEGER FK | → `Treatments.treatment_id` |

---

### Payments

Individual payment transactions recorded against an invoice. An invoice may receive multiple partial payments over time.

| Column | Type | Notes |
|---|---|---|
| `payment_id` | INTEGER PK | Auto-increment |
| `invoice_id` | INTEGER FK | → `Invoices.invoice_id` |
| `amount` | REAL NOT NULL | Amount paid in this transaction |
| `payment_date` | TEXT NOT NULL | ISO 8601 date string |
| `method` | TEXT | `نقدي` / `بطاقة` / `تحويل` (Cash / Card / Transfer) |

---

### Appointments

Scheduled clinic visits for a patient.

| Column | Type | Notes |
|---|---|---|
| `appointment_id` | INTEGER PK | Auto-increment |
| `patient_id` | INTEGER FK | → `Patients.patient_id` |
| `appointment_date` | TEXT NOT NULL | `YYYY-MM-DD HH:mm:ss` |
| `notes` | TEXT | Pre-appointment notes |
| `doctor_notes` | TEXT | Post-appointment clinical notes |
| `status` | TEXT | `محجوز` / `منجز` / `ملغى` / `لم يحضر` (Booked / Completed / Cancelled / No Show) |

Past appointments with status `محجوز` (Booked) are automatically promoted to `منجز` (Completed) by a background timer that runs every 2 hours.

---

### PatientXrayImages

One-to-many X-ray image gallery per patient (added in v5, replacing the single `xray_image` column on `Patients`).

| Column | Type | Notes |
|---|---|---|
| `xray_id` | INTEGER PK | Auto-increment |
| `patient_id` | INTEGER FK | → `Patients.patient_id` |
| `image_path` | TEXT NOT NULL | Absolute path to image file on disk |
| `created_at` | TEXT NOT NULL | ISO 8601 datetime |

---

### Expenses

Clinic operating expenses. Not linked to any patient — represents overhead costs.

| Column | Type | Notes |
|---|---|---|
| `expense_id` | INTEGER PK | Auto-increment |
| `description` | TEXT | Free-text description |
| `amount` | REAL NOT NULL | |
| `expense_date` | TEXT NOT NULL | ISO 8601 date string |
| `category` | TEXT | Rent / Salaries / Medical Supplies / Other |

---

## Schema Versions

| Version | Change |
|---|---|
| 1 | Initial schema: Patients (with `age`), Treatments, Invoices, Invoice_Treatments, Payments, Expenses, Appointments |
| 2 | Added `agreed_amount_paid` to Treatments |
| 3 | Added `expenses` and `laboratory_name` to Treatments |
| 4 | Migrated `age` (integer) → `birth_date` (TEXT) on Patients |
| 5 | Added `PatientXrayImages` table |

---

## Encryption Architecture

### Layer 1 — Database (SQLCipher AES-256)

SQLCipher encrypts every 4 KB page of the database file using AES-256 in CBC mode. The key is set once per session via:

```sql
PRAGMA key = "x'<64-char hex key>'";
```

This must be the very first statement issued after opening the file. Until it is set, no data can be read or written. The file on disk is always encrypted — there is no plaintext phase, even when the database is first created.

**Key derivation:**

```
password  →  SHA-256(password)  →  32-byte key (256 bits)
```

The key lives exclusively in RAM (`EncryptionService` singleton). It is never written to disk in any form. When the app terminates, the key bytes are overwritten with zeros before the reference is released.

**Why SHA-256 directly (no PBKDF2)?**
SQLCipher 4 applies its own internal KDF (`PBKDF2-HMAC-SHA512`, 256 000 iterations by default) on top of the raw key material passed via `PRAGMA key`. Adding another KDF layer in application code would be redundant. The single SHA-256 step is used purely to convert the variable-length password string into a fixed 32-byte hex value expected by the PRAGMA syntax.

---

### Layer 2 — Password Verification

The app needs to verify the user's password at startup without storing it or the database key on disk. The solution:

```
password  →  SHA-256(password)  →  SHA-256(SHA-256(password))  →  stored in settings.json
```

- The **single hash** is the database encryption key (RAM only).
- The **double hash** is the verifier stored on disk.
- Given only the double hash on disk, an attacker cannot derive the single hash and therefore cannot derive the encryption key.

---

### Layer 3 — Backup Files (.clinc)

Exported backups use a separate AES-256-CBC encryption layer so that backup files are safe to store on external drives or cloud storage.

**Export process:**

```
All DB data → JSON → ZIP (includes X-ray images) → AES-256-CBC encrypt → .clinc file
```

**File format:**

```
[ 16 bytes  — IV (random, generated per backup) ]
[ 32 bytes  — HMAC-SHA256(IV + ciphertext, key) ]
[ N bytes   — AES-256-CBC ciphertext            ]
```

The HMAC tag allows the app to verify the password quickly before attempting full decryption. HMAC comparison uses a constant-time algorithm to prevent timing-based attacks.

**Key used for backup encryption:** `SHA-256(login_password)` — the same key as the database. This means one password unlocks both the live database and any backup made with it. If the user changes their password after making a backup, they must provide the **old password** to import that backup.

**Legacy `.zip` backups** (created before encryption was added) are still importable without a password prompt.

---

### Security Properties Summary

| Property | Status |
|---|---|
| Database always encrypted on disk | Yes — SQLCipher AES-256, every page |
| Encryption key ever written to disk | No — RAM only, zeroed on app exit |
| Password stored on disk | No — only `SHA-256(SHA-256(password))` |
| Backup files encrypted | Yes — AES-256-CBC with HMAC-SHA256 |
| Timing-safe password comparison | Yes — constant-time HMAC verify |
| Cross-platform identical encryption | Yes — macOS, Windows, Linux, iOS, Android |

---

## Data Storage Locations

| Data | Location |
|---|---|
| `clinc_database.db` | `ClinC Data/` folder next to the app |
| `settings.json` (password verifier + app settings) | `ClinC Data/` folder next to the app |
| Backup files (`.clinc`) | User-configured; defaults to `~/Library/Application Support/.../ClinC Backups/` |
| X-ray images | Absolute paths on local disk, referenced from `PatientXrayImages` |
