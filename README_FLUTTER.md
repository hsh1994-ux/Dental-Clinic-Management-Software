# Flutter — Usage, Rationale & Project Structure

This document explains why Flutter was chosen, how it is used throughout the Clinc project, and how the codebase is organized.

---

## Why Flutter

Clinc needs to run on macOS, Windows, and Linux from a single codebase, with a native-feeling UI and local encrypted storage. Flutter was the right tool for this for several reasons:

- **Single codebase, multiple platforms.** One Dart codebase compiles to native binaries on all three desktop platforms, plus iOS and Android if ever needed. There is no need to maintain separate codebases or deal with platform-specific UI frameworks.
- **Compiled native code.** Flutter compiles to ARM/x64 machine code, not a web view or interpreted runtime. This keeps the UI smooth and the startup time fast for a desktop app that loads from a local database.
- **Rich widget library.** The Material Design widget set covers everything the app needs — data tables, calendars, charts, forms, navigation rails — without requiring third-party UI kits.
- **Desktop maturity.** Flutter's desktop support (macOS, Windows, Linux) is stable as of Flutter 3.x. It supports native file pickers, window management, and platform channels needed for SQLCipher integration.
- **Dart.** Dart's strong typing, async/await model, and null safety make it straightforward to write the kind of data-heavy, form-driven code a clinic management app requires.

---

## SDK & Environment

| Item | Value |
|---|---|
| Flutter SDK | ≥ 3.19.0 (stable) |
| Dart SDK | ≥ 3.4.1, < 4.0.0 |
| Localization | `flutter gen-l10n` via `l10n.yaml` |
| Linting | `package:flutter_lints/flutter.yaml` |

---

## Dependencies

### Core & State Management

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.2 | State management — `ChangeNotifierProvider` pattern |
| `flutter_localizations` | SDK | Built-in localization support |
| `intl` | ^0.20.2 | Date/number formatting and ARB file support |

### Database & Storage

| Package | Version | Purpose |
|---|---|---|
| `sqflite` | ^2.3.3+1 | SQLite database access |
| `sqflite_common_ffi` | ^2.3.3 | FFI-based SQLite for desktop platforms |
| `sqlcipher_flutter_libs` | ^0.6.0 | SQLCipher binaries for AES-256 database encryption |
| `sqlite3` | ^2.0.0 | Low-level SQLite API for SQLCipher library override |
| `path_provider` | ^2.1.5 | Platform-specific file paths |
| `path` | ^1.9.1 | File path manipulation |

### Security & Cryptography

| Package | Version | Purpose |
|---|---|---|
| `crypto` | ^3.0.3 | SHA-256 hashing for key derivation and password verification |
| `encrypt` | ^5.0.3 | AES-256-CBC encryption for backup files |

### UI Widgets

| Package | Version | Purpose |
|---|---|---|
| `fl_chart` | ^0.68.0 | Bar and pie charts for dashboard and reports |
| `table_calendar` | ^3.1.2 | Calendar widget for the appointments screen |
| `dropdown_search` | ^5.0.6 | Searchable dropdown — used in appointment and invoice forms |
| `teeth_selector` | ^0.2.2 | Dental tooth chart widget for treatment forms |
| `cupertino_icons` | ^1.0.6 | iOS-style icons |

### Files, PDF & Sharing

| Package | Version | Purpose |
|---|---|---|
| `file_picker` | ^10.3.2 | Native file/directory picker for backup import/export |
| `image_picker` | ^1.2.0 | Camera and gallery access for X-ray images |
| `pdf` | ^3.11.3 | PDF document generation for invoices and lab reports |
| `printing` | ^5.14.2 | PDF preview, print, and share |
| `share_plus` | ^11.1.0 | Share files (e.g. PDF invoices) via system share sheet |
| `open_file` | ^3.5.10 | Open files with the system default app |
| `url_launcher` | ^6.3.2 | Open URLs — used to open WhatsApp with a patient's number |
| `permission_handler` | ^12.0.1 | Runtime storage permissions on Android/iOS |
| `archive` | transitive | ZIP compression inside backup files |

### Development & Tooling

| Package | Version | Purpose |
|---|---|---|
| `flutter_gen` | ^5.11.0 | Code generation for assets |
| `flutter_launcher_icons` | ^0.13.1 | App icon generation across platforms |
| `flutter_lints` | ^3.0.0 | Lint rules |

---

## Project Structure

```
lib/
├── main.dart                  # Entry point — SQLCipher init, providers, app gate
├── l10n/                      # Localization
├── models/                    # Plain data classes
├── repositories/              # Database access layer
├── providers/                 # State management layer
├── screens/                   # UI screens
├── services/                  # Business logic and utilities
├── theme/                     # App-wide theme
└── widgets/                   # Reusable UI components
```

### main.dart

The entry point does four things before showing any UI:

1. **Platform-specific SQLCipher initialization** — overrides the default SQLite library with SQLCipher on each platform (CocoaPods on macOS/iOS, dynamic library on Linux, bundled DLL on Windows, `openCipherOnAndroid()` on Android).
2. **FFI setup** — calls `sqfliteFfiInit()` and assigns `databaseFactoryFfi` so sqflite uses the FFI-based driver on desktop.
3. **Provider tree** — wraps the app in a `MultiProvider` with seven `ChangeNotifierProvider` instances (see State Management below).
4. **App gate** — the root widget is `_AppGate`, which blocks access to the main UI until the user authenticates.

`_AppGate` has three states managed by `_GateState`:

| State | Shown |
|---|---|
| `locked` | `PasswordGateScreen` — create password (first run) or enter password (returning) |
| `loading` | `CircularProgressIndicator` — while opening the encrypted DB and loading providers |
| `ready` | `MainScreen` — full application |

`_AppGate` also implements `WidgetsBindingObserver` to clear the encryption key from RAM when the app terminates.

---

### l10n/ — Localization

The app supports English and Arabic with full RTL layout switching.

| File | Purpose |
|---|---|
| `app_en.arb` | English strings (300+ keys) |
| `app_ar.arb` | Arabic strings (300+ keys) |
| `app_localizations.dart` | Generated base class — do not edit manually |
| `app_localizations_en.dart` | Generated English implementation |
| `app_localizations_ar.dart` | Generated Arabic implementation |
| `localization_helpers.dart` | Helpers that translate status enums to localized strings |

`l10n.yaml` configures the generator:

```yaml
arb-dir: lib/l10n
template-arb-file: app_ar.arb
output-localization-file: app_localizations.dart
```

To regenerate after editing an `.arb` file:
```bash
flutter gen-l10n
```

Never edit the generated `app_localizations*.dart` files directly — they are overwritten by `gen-l10n`.

---

### models/ — Data Classes

Plain Dart classes with no dependencies. Each model represents one database table and provides `toMap()` / `fromMap()` for serialization.

| File | Entity |
|---|---|
| `patient.dart` | Patient record |
| `appointment.dart` | Clinic appointment |
| `treatment.dart` | Clinical treatment per tooth |
| `invoice.dart` | Billing invoice |
| `invoice_treatment.dart` | Join entity linking invoices to treatments |
| `payment.dart` | Payment transaction against an invoice |
| `expense.dart` | Clinic operating expense |
| `laboratory_item.dart` | Lab work item |
| `patient_xray.dart` | X-ray image record |

All date fields are stored as ISO 8601 strings (`TEXT` in SQLite). The `Patient` model includes an `age` getter/setter that derives the value from `birth_date` at runtime rather than storing it.

---

### repositories/ — Database Access Layer

Each repository wraps raw SQLite queries for one table or entity group. Repositories take a `DatabaseService` instance and return model objects. They contain no business logic — only CRUD operations.

| File | Table(s) |
|---|---|
| `patient_repository.dart` | Patients |
| `appointment_repository.dart` | Appointments |
| `treatment_repository.dart` | Treatments |
| `invoice_repository.dart` | Invoices |
| `invoice_treatment_repository.dart` | Invoice_Treatments |
| `payment_repository.dart` | Payments |
| `expense_repository.dart` | Expenses |
| `patient_xray_repository.dart` | PatientXrayImages |

---

### providers/ — State Management

State is managed with the `provider` package using `ChangeNotifier`. Each provider owns one domain area, holds the in-memory list for that domain, and exposes methods that call the appropriate repository then call `notifyListeners()`.

| Provider | Responsibility |
|---|---|
| `PatientProvider` | Patient list, search/filter |
| `AppointmentProvider` | Appointment list, calendar date selection, reset |
| `TreatmentProvider` | Treatment list per patient |
| `InvoiceProvider` | Invoice list, search/filter, linked treatments via proxy |
| `ExpenseProvider` | Expense list, category filter |
| `LaboratoryProvider` | Lab item list, search |
| `SettingsProvider` | Theme mode, locale, backup location and frequency settings |

`InvoiceProvider` is registered as a `ChangeNotifierProxyProvider<TreatmentProvider, InvoiceProvider>` because it needs a reference to `TreatmentProvider` to resolve which treatments are already invoiced.

The provider tree is set up in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => PatientProvider()),
    ChangeNotifierProvider(create: (_) => AppointmentProvider()),
    ChangeNotifierProvider(create: (_) => TreatmentProvider()),
    ChangeNotifierProxyProvider<TreatmentProvider, InvoiceProvider>(...),
    ChangeNotifierProvider(create: (_) => ExpenseProvider()),
    ChangeNotifierProvider(create: (_) => LaboratoryProvider()),
  ],
  ...
)
```

Screens access providers via `Provider.of<T>(context)` or `Consumer<T>`.

---

### screens/ — UI Screens

Each screen is a `StatefulWidget` or `StatelessWidget` that reads from providers and delegates user actions back to them.

| File | Screen |
|---|---|
| `main_screen.dart` | Navigation shell — `NavigationRail` (desktop) or `BottomNavigationBar` (mobile) |
| `dashboard_screen.dart` | Overview cards — today's appointments, patient count, outstanding invoices |
| `patients_screen.dart` | Paginated patient list with search |
| `patient_detail_screen.dart` | Full patient record — treatments, invoices, appointments, X-rays |
| `patient_form_screen.dart` | Add / edit patient form |
| `appointments_screen.dart` | Calendar view + daily appointment list |
| `appointment_form_screen.dart` | Add / edit appointment form |
| `treatment_form_screen.dart` | Add / edit treatment form |
| `treatment_detail_screen.dart` | Treatment detail with invoice link |
| `invoices_screen.dart` | Paginated invoice list with search |
| `invoice_detail_screen.dart` | Invoice detail — linked treatments and payment history |
| `invoice_form_screen.dart` | Add / edit invoice form |
| `payment_form_screen.dart` | Add / edit payment form |
| `expenses_screen.dart` | Expense list with category filter |
| `expense_form_screen.dart` | Add / edit expense form |
| `reports_screen.dart` | Financial charts — revenue trend, expense breakdown, net income |
| `settings_screen.dart` | All settings — language, theme, security, data management |
| `password_gate_screen.dart` | First-run password creation / returning user unlock |
| `laboratory_screen.dart` | Lab items list and PDF generation |
| `more_screen.dart` | Overflow navigation for smaller screens |

`MainScreen` adapts its navigation component based on screen width — `NavigationRail` for screens ≥ 640 px, `BottomNavigationBar` for smaller screens.

---

### services/ — Business Logic & Utilities

| File | Purpose |
|---|---|
| `database_service.dart` | SQLCipher DB lifecycle, schema migrations, `BackupService` |
| `encryption_service.dart` | Singleton — holds AES-256 key in RAM, derives from password, zeroes on exit |
| `password_service.dart` | SHA-256 double-hash, save/verify password via `FilePreferences` |
| `file_preferences.dart` | JSON file-based key-value store replacing `SharedPreferences` |
| `app_storage.dart` | Resolves platform-correct paths for `ClinC Data/` folder |
| `pdf_invoice_service.dart` | Generates PDF invoices using the `pdf` package |
| `pdf_laboratory_service.dart` | Generates PDF lab reports |
| `xray_storage_service.dart` | Manages X-ray image file paths |
| `random_data_generator.dart` | Generates realistic test data (patients, appointments, etc.) |

---

### theme/ — App Theme

`app_theme.dart` defines `AppTheme.lightTheme` and `AppTheme.darkTheme`, both using the `Tajawal` font family (which supports Arabic and Latin scripts). The primary brand color is `#055B66` (dark teal).

The active theme is stored in `SettingsProvider` and applied at the `MaterialApp` level, so switching themes in Settings takes effect immediately without restarting.

---

### widgets/ — Reusable Components

| File | Widget |
|---|---|
| `password_dialog.dart` | Inline password prompt dialog used in settings for password-protected actions |

---

## Platform-Specific Notes

### macOS

- SQLCipher is pulled in via CocoaPods (`macos/Podfile`).
- The app is **not sandboxed** (`com.apple.security.app-sandbox = false`) to allow writing `ClinC Data/` next to the app bundle.
- The entitlement `com.apple.security.files.user-selected.read-write` is set to allow the native file picker to read and write user-selected files.

### Windows

- SQLCipher ships as a bundled `sqlite3.dll` that is discovered automatically at runtime.
- The distribution folder (`Release\`) contains the `.exe`, all required DLLs, and the `ClinC Data\` folder created on first run.

### Linux

- SQLCipher is compiled into the plugin shared library (`libsqlcipher_flutter_libs_plugin.so`).
- The app loads it at startup using `DynamicLibrary.open()` with an absolute path resolved from `Platform.resolvedExecutable`.

---

## Data Flow Summary

```
User action (tap / form submit)
        │
        ▼
   Screen widget
        │  calls provider method
        ▼
   Provider (ChangeNotifier)
        │  calls repository
        ▼
   Repository
        │  executes SQL via DatabaseService
        ▼
   DatabaseService (SQLCipher)
        │  reads/writes encrypted pages
        ▼
   clinc_database.db  (ClinC Data/ folder)
```

On completion, the repository returns model objects, the provider updates its in-memory list and calls `notifyListeners()`, and any `Consumer` or `Provider.of(context, listen: true)` widget in the tree rebuilds automatically.
