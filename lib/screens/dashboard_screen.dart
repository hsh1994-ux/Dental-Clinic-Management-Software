import 'package:clinc/screens/treatment_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../models/patient_xray.dart';
import '../providers/patient_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/invoice_provider.dart';
import '../repositories/patient_xray_repository.dart';
import '../services/xray_storage_service.dart';
import 'appointment_form_screen.dart';
import 'appointments_screen.dart';
import 'invoice_form_screen.dart';
import 'invoices_screen.dart';
import 'patient_form_screen.dart';
import 'patients_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.dashboard),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1800),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Cards
                      Consumer3<PatientProvider, AppointmentProvider,
                          InvoiceProvider>(
                        builder: (context, patientProvider, appointmentProvider,
                            invoiceProvider, child) {
                          final cards = [
                            DashboardCard(
                              title: appLocalizations.patientsCount,
                              value: patientProvider.patients.length.toString(),
                              icon: Icons.people_outline,
                              color: Colors.blue.shade700,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const PatientsScreen())),
                            ),
                            DashboardCard(
                              title: appLocalizations.todaysAppointments,
                              value: appointmentProvider
                                  .getAppointmentsForDate(DateTime.now())
                                  .length
                                  .toString(),
                              icon: Icons.calendar_today_outlined,
                              color: Colors.green.shade700,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const AppointmentsScreen())),
                            ),
                            DashboardCard(
                              title: appLocalizations.pendingInvoices,
                              value: invoiceProvider.invoices
                                  .where((invoice) =>
                                      invoice.status != 'مدفوعة بالكامل')
                                  .length
                                  .toString(),
                              icon: Icons.receipt_long_outlined,
                              color: Colors.orange.shade700,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const InvoicesScreen())),
                            ),
                          ];
                          return GridView.builder(
                            itemCount: cards.length,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 350,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              childAspectRatio: 1.75,
                            ),
                            itemBuilder: (context, index) => cards[index],
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          appLocalizations.quickActions,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Quick Actions
                      GridView.count(
                        crossAxisCount: constraints.maxWidth > 900 ? 4 : 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        shrinkWrap: true,
                        childAspectRatio: 1.2,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          QuickActionButton(
                            icon: Icons.person_add_alt_1_outlined,
                            label: appLocalizations.addPatient,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PatientFormScreen()),
                              );
                            },
                          ),
                          QuickActionButton(
                            icon: Icons.event_note_outlined,
                            label: appLocalizations.addAppointment,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AppointmentFormScreen()),
                              );
                            },
                          ),
                         
                          QuickActionButton(
                            icon: Icons.healing_outlined,
                            label: appLocalizations.addTreatment,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const TreatmentFormScreen()),
                              );
                            },
                          ),
                          QuickActionButton(
                            icon: Icons.add_photo_alternate_outlined,
                            label: 'Add X-Ray',
                            onPressed: () => _addXRayQuickAction(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium,
                ),
                Icon(icon, size: 32, color: color),
              ],
            ),
            Text(
              value,
              style: textTheme.displaySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

Future<void> _addXRayQuickAction(BuildContext context) async {
  final patient = await showDialog<Patient>(
    context: context,
    builder: (_) => const _PatientPickerDialog(),
  );
  if (patient == null || !context.mounted) return;

  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  if (file == null || !context.mounted) return;

  try {
    final embedded = await XRayStorageService.importImage(file.path);
    if (embedded == null) return;
    await PatientXrayRepository().insertPatientXray(PatientXray(
      patientId: patient.patientId!,
      imagePath: embedded,
      createdAt: DateTime.now().toIso8601String(),
    ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('X-Ray added for ${patient.name}')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

class _PatientPickerDialog extends StatefulWidget {
  const _PatientPickerDialog();

  @override
  State<_PatientPickerDialog> createState() => _PatientPickerDialogState();
}

class _PatientPickerDialogState extends State<_PatientPickerDialog> {
  Patient? _selected;

  @override
  Widget build(BuildContext context) {
    final patients =
        Provider.of<PatientProvider>(context, listen: false).patients;
    return AlertDialog(
      title: const Text('Select Patient'),
      content: SizedBox(
        width: 300,
        child: Autocomplete<Patient>(
          displayStringForOption: (p) => p.name,
          optionsBuilder: (value) {
            if (value.text.isEmpty) return patients;
            return patients.where((p) =>
                p.name.toLowerCase().contains(value.text.toLowerCase()) ||
                p.fileNumber.contains(value.text));
          },
          onSelected: (p) => setState(() => _selected = p),
          fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
              TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: 'Search patient...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed:
              _selected == null ? null : () => Navigator.pop(context, _selected),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
