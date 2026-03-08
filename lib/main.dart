import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'dart:io'; // Added for Platform check
import 'dart:ffi';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Added for FFI initialization
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import 'services/database_service.dart';
import 'services/encryption_service.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/treatment_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/laboratory_provider.dart';

import 'screens/main_screen.dart';
import 'screens/password_gate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure sqlite3 to use SQLCipher on every platform
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  } else if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      // SQLCipher is compiled into the plugin shared library on Linux.
      // Resolve absolute path from executable location.
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return DynamicLibrary.open(
          '$exeDir/lib/libsqlcipher_flutter_libs_plugin.so');
    });
  }
  // Windows: sqlcipher_flutter_libs builds a separate sqlite3.dll (SQLCipher)
  //   that is bundled in the app directory — found automatically.
  // macOS/iOS: SQLCipher linked via CocoaPods — found automatically.

  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // DB is always encrypted on disk (SQLCipher) — no crash cleanup needed.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => TreatmentProvider()),
        ChangeNotifierProxyProvider<TreatmentProvider, InvoiceProvider>(
          create: (_) => InvoiceProvider(),
          update: (_, treatmentProvider, invoiceProvider) =>
              invoiceProvider!..setTreatmentProvider(treatmentProvider),
        ),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => LaboratoryProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.themeMode,
            locale: settingsProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('ar', ''), // Arabic
            ],
            home: const _AppGate(),
          );
        },
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

enum _GateState { locked, loading, ready }

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  _GateState _state = _GateState.locked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Close DB and wipe key when app is terminating.
      // The file on disk remains encrypted (SQLCipher).
      DatabaseService().closeDatabase();
      EncryptionService.instance.clearKey();
    }
  }

  Future<void> _onAuthenticated() async {
    setState(() => _state = _GateState.loading);

    // Open SQLCipher-encrypted DB (handles migration if needed)
    await DatabaseService().openDatabaseWithKey();
    await DatabaseService().checkAndInsertInitialData();

    if (!mounted) return;

    // Refresh all providers with the real (decrypted) data
    await Provider.of<PatientProvider>(context, listen: false).fetchPatients();
    await Provider.of<AppointmentProvider>(context, listen: false)
        .fetchAppointments();
    await Provider.of<TreatmentProvider>(context, listen: false)
        .fetchTreatments();
    await Provider.of<InvoiceProvider>(context, listen: false).fetchInvoices();
    await Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();

    if (!mounted) return;
    setState(() => _state = _GateState.ready);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GateState.locked:
        return MainScreen();
      case _GateState.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case _GateState.ready:
        return const MainScreen();
    }
  }
}
