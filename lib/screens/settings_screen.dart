import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/appointment_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/treatment_provider.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';
import '../services/password_service.dart';
import '../services/random_data_generator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _exportData(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(appLocalizations.exportingData)));

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        if (!status.isGranted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                  content: Text(appLocalizations.storagePermissionRequired)),
            );
          return;
        }
      }

      final String? outputDirectory =
          await FilePicker.platform.getDirectoryPath(
        dialogTitle: appLocalizations.selectExportDirectory,
      );

      if (outputDirectory == null) {
        // User canceled the picker
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        return;
      }

      final backupService = BackupService();
      final tempFilePath = await backupService.exportData();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (tempFilePath != null) {
        final tempFile = File(tempFilePath);
        final fileName = path.basename(tempFile.path);
        final newPath = path.join(outputDirectory, fileName);

        await tempFile.copy(newPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${appLocalizations.exportSuccessful} $newPath'),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.backupFailed)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${appLocalizations.backupFailed}: $e')),
        );
    }
  }

  void _importData(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.restoreWarningTitle),
        content: Text(appLocalizations.restoreWarningContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(appLocalizations.restore,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Pick the backup file first (.clinc or legacy .zip)
    final backupService = BackupService();
    final zipFilePath = await backupService.pickBackupFile();
    if (zipFilePath == null) return; // User canceled

    // If encrypted, prompt for the backup password
    String? backupPassword;
    if (backupService.isBackupEncrypted(zipFilePath)) {
      if (!context.mounted) return;
      backupPassword = await _askBackupPassword(context);
      if (backupPassword == null) return; // User canceled
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(appLocalizations.importingData)));

    try {
      final success = await backupService.importData(
        zipFilePath: zipFilePath,
        password: backupPassword,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (success) {
        // Reload all data after import
        await Future.wait([
          Provider.of<PatientProvider>(context, listen: false).fetchPatients(),
          Provider.of<AppointmentProvider>(context, listen: false)
              .fetchAppointments(),
          Provider.of<TreatmentProvider>(context, listen: false)
              .fetchTreatments(),
          Provider.of<InvoiceProvider>(context, listen: false).fetchInvoices(),
          Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses(),
        ]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.restoreSuccessful)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.restoreFailed)),
        );
      }
    } on WrongPasswordException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(appLocalizations.wrongBackupPassword)),
        );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${appLocalizations.restoreFailed}: $e')),
        );
    }
  }

  Future<String?> _askBackupPassword(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.backupPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(appLocalizations.backupPasswordMessage),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: appLocalizations.password,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.of(context).pop(value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(appLocalizations.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: Text(appLocalizations.unlock),
          ),
        ],
      ),
    );
  }

  void _resetApp(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;

    // First verify the current password
    final passwordVerified = await _verifyCurrentPassword(context);
    if (passwordVerified != true) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.resetAppWarningTitle),
        content: Text(appLocalizations.resetAppWarningContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(appLocalizations.reset,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(appLocalizations.resettingApp)));

    try {
      await DatabaseService().clearDatabase();
      // Clear the old password; DB stays open with current key
      await PasswordService.clearPassword();

      // Reload all data after clearing
      await Future.wait([
        Provider.of<PatientProvider>(context, listen: false).fetchPatients(),
        Provider.of<AppointmentProvider>(context, listen: false)
            .fetchAppointments(),
        Provider.of<TreatmentProvider>(context, listen: false)
            .fetchTreatments(),
        Provider.of<InvoiceProvider>(context, listen: false).fetchInvoices(),
        Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses(),
      ]);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(appLocalizations.resetAppSuccess)),
        );

      // Ask the user to create a new password
      await _showCreateNewPasswordDialog(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${appLocalizations.resetAppFailed}: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.settings),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle(context, appLocalizations.displaySettings),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    _buildLanguageTile(context, appLocalizations),
                    const Divider(height: 1),
                    _buildThemeTile(context, appLocalizations),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, appLocalizations.security),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(appLocalizations.changePassword),
                      subtitle: Text(appLocalizations.changePasswordSubtitle),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, appLocalizations.dataManagement),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file_outlined),
                      title: Text(appLocalizations.exportData),
                      subtitle: Text(appLocalizations.exportDataSubtitle),
                      onTap: () => _exportData(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_for_offline_outlined),
                      title: Text(appLocalizations.importData),
                      subtitle: Text(appLocalizations.importDataSubtitle),
                      onTap: () => _importData(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.delete_forever_outlined,
                          color: Theme.of(context).colorScheme.error),
                      title: Text(
                        appLocalizations.resetApp,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      subtitle: Text(appLocalizations.resetAppSubtitle),
                      onTap: () => _resetApp(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, appLocalizations.development),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.auto_fix_high_outlined),
                      title: Text(appLocalizations.generateTestData),
                      subtitle: Text(appLocalizations.generateTestDataSubtitle),
                      onTap: () => _showGenerateTestDataDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGenerateTestDataDialog(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final patientCountController = TextEditingController(text: '20');
    DataLanguage selectedLanguage = DataLanguage.mixed;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setState) {
            return AlertDialog(
              title: Text(appLocalizations.generateTestData),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: patientCountController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.numberOfPatients,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLocalizations.pleaseEnterNumberOfPatients;
                        }
                        final n = int.tryParse(value);
                        if (n == null || n <= 0) {
                          return appLocalizations
                              .pleaseEnterValidPositiveNumber;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<DataLanguage>(
                      value: selectedLanguage,
                      decoration: InputDecoration(
                        labelText: appLocalizations.dataLanguage,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: DataLanguage.arabic,
                          child: Text(appLocalizations.dataLanguageArabic),
                        ),
                        DropdownMenuItem(
                          value: DataLanguage.english,
                          child: Text(appLocalizations.dataLanguageEnglish),
                        ),
                        DropdownMenuItem(
                          value: DataLanguage.mixed,
                          child: Text(appLocalizations.dataLanguageMixed),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(appLocalizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final count = int.parse(patientCountController.text);
                      Navigator.pop(dialogContext);
                      _generateTestData(context, count, selectedLanguage);
                    }
                  },
                  child: Text(appLocalizations.generate),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _generateTestData(
      BuildContext context, int patientCount, DataLanguage language) async {
    final appLocalizations = AppLocalizations.of(context)!;

    // Show a progress dialog and wait for generation to finish
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _GeneratingProgressDialog(
          patientCount: patientCount,
          language: language,
        );
      },
    );

    if (!context.mounted) return;

    if (result == null || result == 'success') {
      // Reload all providers sequentially
      await Provider.of<PatientProvider>(context, listen: false)
          .fetchPatients();
      await Provider.of<AppointmentProvider>(context, listen: false)
          .fetchAppointments();
      await Provider.of<TreatmentProvider>(context, listen: false)
          .fetchTreatments();
      await Provider.of<InvoiceProvider>(context, listen: false)
          .fetchInvoices();
      await Provider.of<ExpenseProvider>(context, listen: false)
          .fetchExpenses();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(appLocalizations.testDataGenerated)),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${appLocalizations.testDataError}: $result')),
        );
    }
  }

  /// Verifies the current password via a dialog. Returns true if verified.
  Future<bool?> _verifyCurrentPassword(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    bool obscure = true;
    String? error;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(appLocalizations.verifyPassword),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: appLocalizations.currentPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(appLocalizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final valid =
                        await PasswordService.verifyPassword(controller.text);
                    if (valid) {
                      Navigator.pop(dialogContext, true);
                    } else {
                      setState(() {
                        error = appLocalizations.incorrectPassword;
                      });
                    }
                  },
                  child: Text(appLocalizations.verify),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a dialog to change the password (current → new + confirm).
  void _showChangePasswordDialog(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? currentError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(appLocalizations.changePassword),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: appLocalizations.currentPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => obscureCurrent = !obscureCurrent),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText: currentError,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLocalizations.pleaseEnterPassword;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: appLocalizations.newPassword,
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => obscureNew = !obscureNew),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLocalizations.pleaseEnterPassword;
                        }
                        if (value.length < 4) {
                          return appLocalizations.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: appLocalizations.confirmPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => obscureConfirm = !obscureConfirm),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLocalizations.pleaseConfirmPassword;
                        }
                        if (value != newController.text) {
                          return appLocalizations.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(appLocalizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Clear previous error
                    setState(() => currentError = null);

                    if (!formKey.currentState!.validate()) return;

                    final valid = await PasswordService.verifyPassword(
                        currentController.text);
                    if (!valid) {
                      setState(() {
                        currentError = appLocalizations.incorrectPassword;
                      });
                      return;
                    }

                    await PasswordService.savePassword(newController.text);
                    EncryptionService.instance.setKey(newController.text);
                    await DatabaseService().rekeyDatabase();
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(appLocalizations.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (!context.mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(appLocalizations.passwordChanged)),
        );
    }
  }

  /// Shows a dialog to create a new password (after reset).
  Future<void> _showCreateNewPasswordDialog(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(appLocalizations.createPassword),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(appLocalizations.createNewPasswordAfterReset),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: appLocalizations.newPassword,
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => obscureNew = !obscureNew),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLocalizations.pleaseEnterPassword;
                        }
                        if (value.length < 4) {
                          return appLocalizations.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: appLocalizations.confirmPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => obscureConfirm = !obscureConfirm),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLocalizations.pleaseConfirmPassword;
                        }
                        if (value != newController.text) {
                          return appLocalizations.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await PasswordService.savePassword(newController.text);
                    EncryptionService.instance.setKey(newController.text);
                    await DatabaseService().rekeyDatabase();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(appLocalizations.createPasswordButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildLanguageTile(
      BuildContext context, AppLocalizations appLocalizations) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: Text(appLocalizations.language),
      trailing: DropdownButton<String>(
        value: settingsProvider.locale.languageCode,
        underline: const SizedBox.shrink(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            settingsProvider.setLanguage(newValue);
          }
        },
        items:
            <String>['en', 'ar'].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value == 'en'
                ? appLocalizations.english
                : appLocalizations.arabic),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeTile(
      BuildContext context, AppLocalizations appLocalizations) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return SwitchListTile(
      secondary: const Icon(Icons.brightness_6_outlined),
      title: Text(appLocalizations.theme),
      value: settingsProvider.themeMode == ThemeMode.dark,
      onChanged: (bool value) {
        settingsProvider.toggleTheme(value);
      },
    );
  }
}

class _GeneratingProgressDialog extends StatefulWidget {
  final int patientCount;
  final DataLanguage language;

  const _GeneratingProgressDialog({
    required this.patientCount,
    required this.language,
  });

  @override
  State<_GeneratingProgressDialog> createState() =>
      _GeneratingProgressDialogState();
}

class _GeneratingProgressDialogState extends State<_GeneratingProgressDialog> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  Future<void> _startGeneration() async {
    try {
      final generator = RandomDataGenerator();
      await generator.generate(
        patientCount: widget.patientCount,
        language: widget.language,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
      );
      if (mounted) {
        Navigator.pop(context, 'success');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(appLocalizations.generatingTestData),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Text('${(_progress * 100).toInt()}%'),
        ],
      ),
    );
  }
}
