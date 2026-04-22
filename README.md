# Clinc – Dental Clinic Management Software

A cross-platform desktop application built with Flutter for managing dental clinic operations. Supports Windows, macOS, and Linux.

## Features

- **Patient Management** — Add, edit, and search patient records with file numbers, contact details, and visit history.
- **Appointment Scheduling** — Visual calendar with color-coded appointment statuses (Booked, Completed, Cancelled, No Show).
- **Treatment Records** — Track diagnoses, tooth numbers, agreed amounts, and treatment progress per patient.
- **Invoicing & Payments** — Generate invoices linked to treatments, record partial or full payments, and export PDF invoices.
- **X-Ray Gallery** — Attach and view X-ray images directly within patient records.
- **Expenses Tracking** — Log and categorize clinic expenses with financial summaries.
- **Reports & Dashboard** — Overview of daily appointments, revenue, outstanding invoices, and expense breakdown charts.
- **Encrypted Backup** — Automatic and manual AES-256 encrypted backups using the login password. Configurable backup location, frequency, and retention period.
- **Password Protection** — App-level password with SQLCipher database encryption.
- **Arabic & English** — Full RTL/LTR localization support.

---

## Prerequisites

- **Flutter SDK** 3.19.0 or higher — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** is bundled with Flutter — no separate install needed
- Platform-specific toolchain (see per-platform sections below)

---

## Getting Started

```bash
# Clone the repository
git clone https://github.com/hsh1994-ux/Dental-Clinic-Management-Software.git
cd Dental-Clinic-Management-Software

# Install Flutter dependencies
flutter pub get
```

---

## Running in Development

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

---

## Building for Production

### macOS

**Requirements:** Xcode 14+ and CocoaPods installed.

```bash
# Ensure Flutter build artifacts are fully cached (required for release builds)
flutter precache --force --universal

# Install CocoaPods dependencies
cd macos && pod install && cd ..

# Build release app bundle
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/clinc.app`

To distribute outside the App Store, open the `.app` in Finder and verify it runs. For notarization, use Xcode's Organizer or `xcrun notarytool`.

---

### Windows

**Requirements:** Visual Studio 2022 with the **Desktop development with C++** workload installed.

```bash
flutter build windows --release
```

Output: `build\windows\x64\runner\Release\`

The output folder contains the `.exe` and all required DLLs. Copy the entire folder to distribute, or wrap it with an installer tool such as [Inno Setup](https://jrsoftware.org/isinfo.php).

---

### Linux

**Requirements:** The following packages must be installed:

```bash
sudo apt-get install clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev
```

```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`

The output bundle folder is self-contained. Copy it to distribute, or package it as a `.deb` or `.AppImage` using your preferred tool.

---

## Built With

- [Flutter](https://flutter.dev/) — UI framework
- [Dart](https://dart.dev/) — Language
- [SQLite + SQLCipher](https://www.zetetic.net/sqlcipher/) — Encrypted local database
- [fl_chart](https://pub.dev/packages/fl_chart) — Charts and graphs
- [table_calendar](https://pub.dev/packages/table_calendar) — Calendar widget
- [encrypt](https://pub.dev/packages/encrypt) — AES-256 backup encryption
