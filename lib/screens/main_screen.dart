import 'dart:io';

import 'package:clinc/providers/appointment_provider.dart';
import 'package:clinc/providers/expense_provider.dart';
import 'package:clinc/providers/invoice_provider.dart';
import 'package:clinc/providers/laboratory_provider.dart';
import 'package:clinc/providers/patient_provider.dart';
import 'package:clinc/providers/settings_provider.dart';
import 'package:clinc/screens/expenses_screen.dart';
import 'package:clinc/screens/reports_screen.dart';
import 'package:clinc/screens/settings_screen.dart';
import 'package:clinc/screens/laboratory_screen.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../widgets/password_dialog.dart';
import 'appointments_screen.dart';
import 'dashboard_screen.dart';
import 'invoices_screen.dart';
import 'patients_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoBackupIfNeeded());
  }

  Future<void> _runAutoBackupIfNeeded() async {
    if (!mounted) return;
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    if (!settingsProvider.shouldAutoBackup) return;

    final dirPath = settingsProvider.backupLocation ??
        path.join(
            (await getApplicationDocumentsDirectory()).path, 'ClinC Backups');

    final savedPath = await BackupService().backupToDirectory(
      dirPath,
      retentionDays: settingsProvider.backupRetentionDays,
    );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    if (savedPath != null) {
      await settingsProvider.updateLastBackupTime();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.autoBackupSuccess),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.autoBackupFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _checkPassword() async {
    final appDirectory = Directory(Platform.resolvedExecutable).parent.path;
    final passwordFlagFile = File('$appDirectory/.password_set');

    final bool passwordAlreadySet = await passwordFlagFile.exists();

    if (!passwordAlreadySet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPasswordDialog(passwordFlagFile);
      });
    }
  }

  void _showPasswordDialog(File passwordFlagFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PasswordDialog(
          onPasswordCorrect: () async {
            await passwordFlagFile.create();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  static const List<Widget> _screens = <Widget>[
    DashboardScreen(),
    PatientsScreen(),
    AppointmentsScreen(),
    InvoicesScreen(),
    ExpensesScreen(),
    ReportsScreen(),
    SettingsScreen(),
    //  LaboratoryScreen(),
  ];
  void _onDestinationSelected(int index) {
    if (_selectedIndex != index) {
      Provider.of<PatientProvider>(context, listen: false).setSearchQuery('');
      Provider.of<InvoiceProvider>(context, listen: false).setSearchQuery('');
      Provider.of<ExpenseProvider>(context, listen: false).setSelectedCategory(null);
      Provider.of<LaboratoryProvider>(context, listen: false).setSearchQuery('');
      Provider.of<AppointmentProvider>(context, listen: false).resetCalendar();

      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final destinations = [
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: Text(appLocalizations.home),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.people_outline),
        selectedIcon: const Icon(Icons.people),
        label: Text(appLocalizations.patients),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.calendar_today_outlined),
        selectedIcon: const Icon(Icons.calendar_today),
        label: Text(appLocalizations.appointments),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.receipt_outlined),
        selectedIcon: const Icon(Icons.receipt),
        label: Text(appLocalizations.invoices),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.money_off_outlined),
        selectedIcon: const Icon(Icons.money_off),
        label: Text(appLocalizations.expenses),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.bar_chart_outlined),
        selectedIcon: const Icon(Icons.bar_chart),
        label: Text(appLocalizations.reports),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: Text(appLocalizations.settings),
      ),
      // NavigationRailDestination(
      //   icon: const Icon(Icons.science_outlined),
      //   selectedIcon: const Icon(Icons.science),
      //   label: Text(appLocalizations.laboratory),
      // ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final mainContent = Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              backgroundColor: Colors.transparent,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: destinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Container(child: _screens[_selectedIndex]),
            ),
          ],
        ),
      );
      if (constraints.maxWidth < 640) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            currentIndex: _selectedIndex,
            onTap: _onDestinationSelected,
            items: destinations.map((d) {
              return BottomNavigationBarItem(
                icon: d.icon,
                activeIcon: d.selectedIcon,
                label: (d.label as Text).data,
              );
            }).toList(),
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            unselectedFontSize: 10,
          ),
        );
      } else {
        return mainContent;
      }
    });
  }
}
