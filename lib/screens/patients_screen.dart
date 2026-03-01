import 'package:clinc/providers/appointment_provider.dart';
import 'package:clinc/providers/invoice_provider.dart';
import 'package:clinc/providers/treatment_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/patient.dart';
import '../providers/patient_provider.dart';
import 'patient_detail_screen.dart';
import 'patient_form_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late PatientProvider _patientProvider;

  @override
  void initState() {
    super.initState();
    _patientProvider = Provider.of<PatientProvider>(context, listen: false);
    _patientProvider.addListener(_onPatientProviderChanged);
    _searchController.addListener(() {
      if (_patientProvider.searchQuery != _searchController.text) {
        _patientProvider.setSearchQuery(_searchController.text);
      }
    });
  }

  void _onPatientProviderChanged() {
    if (_searchController.text != _patientProvider.searchQuery) {
      _searchController.text = _patientProvider.searchQuery;
    }
  }

  @override
  void dispose() {
    _patientProvider.removeListener(_onPatientProviderChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.patients),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: appLocalizations.searchPatientsHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surface.withAlpha(10),
                ),
              ),
            ),
            Expanded(
              child: Consumer<PatientProvider>(
                builder: (context, patientProvider, child) {
                  if (patientProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (patientProvider.patients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline,
                              size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(appLocalizations.noPatientsFound,
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    );
                  }
                  return LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return _buildDataTable(context, patientProvider.patients,
                          appLocalizations, constraints);
                    } else {
                      return _buildListView(
                          context, patientProvider.patients, appLocalizations);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PatientFormScreen()),
          );
        },
        tooltip: appLocalizations.addPatient,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<Patient> patients,
      AppLocalizations appLocalizations) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(patient.name.isNotEmpty ? patient.name[0] : '?'),
            ),
            title: Text(patient.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text('${appLocalizations.fileNumber}: ${patient.fileNumber}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: appLocalizations.delete,
                  onPressed: () =>
                      _showDeleteConfirmationDialog(context, patient),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailScreen(patient: patient),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDataTable(BuildContext context, List<Patient> patients,
      AppLocalizations appLocalizations, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: PaginatedDataTable(
              showCheckboxColumn: false,
              columnSpacing: 20,
              horizontalMargin: 16,
              dataRowMaxHeight: 56,
              headingRowHeight: 56,
              rowsPerPage: 20,
              showFirstLastButtons: true,
              columns: [
                DataColumn(
                    label: Expanded(
                        child: Text(appLocalizations.name,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)))),
                DataColumn(
                    label: Expanded(
                        child: Text(appLocalizations.fileNumber,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)))),
                DataColumn(
                    label: Expanded(
                        child: Text(appLocalizations.phone,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)))),
                DataColumn(
                    label: Expanded(
                        child: Center(
                            child: Text(appLocalizations.actions,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold))))),
              ],
              source: _PatientDataSource(
                patients: patients,
                theme: theme,
                colorScheme: colorScheme,
                appLocalizations: appLocalizations,
                onView: (patient) => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PatientDetailScreen(patient: patient))),
                onEdit: (patient) => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PatientFormScreen(patient: patient))),
                onDelete: (patient) =>
                    _showDeleteConfirmationDialog(context, patient),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Patient patient) {
    final appLocalizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.deletePatient),
          content: Text(appLocalizations.deletePatientConfirmation),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(appLocalizations.delete),
              onPressed: () {
                Provider.of<PatientProvider>(context, listen: false)
                    .deletePatient(patient.patientId!);
                Provider.of<InvoiceProvider>(context, listen: false)
                    .deleteInvoice(patient.patientId!);

                Provider.of<AppointmentProvider>(context, listen: false)
                    .deleteAppointment(patient.patientId!);
                Provider.of<TreatmentProvider>(context, listen: false)
                    .deleteTreatment(patient.patientId!);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _PatientDataSource extends DataTableSource {
  final List<Patient> patients;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations appLocalizations;
  final void Function(Patient) onView;
  final void Function(Patient) onEdit;
  final void Function(Patient) onDelete;

  _PatientDataSource({
    required this.patients,
    required this.theme,
    required this.colorScheme,
    required this.appLocalizations,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= patients.length) return null;
    final patient = patients[index];
    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withOpacity(0.15);
        }
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withOpacity(0.08);
        }
        return index.isEven
            ? Colors.transparent
            : colorScheme.surface.withAlpha(10);
      }),
      onSelectChanged: (isSelected) {
        if (isSelected ?? false) {
          onView(patient);
        }
      },
      cells: [
        DataCell(Text(patient.name, style: theme.textTheme.bodyMedium)),
        DataCell(Text(patient.fileNumber, style: theme.textTheme.bodyMedium)),
        DataCell(Text(patient.phone ?? appLocalizations.na,
            style: theme.textTheme.bodyMedium)),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.visibility_outlined, size: 20),
                tooltip: appLocalizations.viewPatient,
                onPressed: () => onView(patient),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: appLocalizations.editPatientTitle,
                onPressed: () => onEdit(patient),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: appLocalizations.delete,
                onPressed: () => onDelete(patient),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => patients.length;

  @override
  int get selectedRowCount => 0;
}
