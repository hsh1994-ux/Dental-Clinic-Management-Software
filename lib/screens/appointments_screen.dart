import 'package:clinc/models/patient.dart';
import 'package:clinc/providers/patient_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localization_helpers.dart';
import '../providers/appointment_provider.dart';
import 'appointment_form_screen.dart';
import 'package:flutter/material.dart' show Colors;

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.appointments),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildWideLayout(context);
          } else {
            return _buildNarrowLayout(context);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AppointmentFormScreen(initialDate: Provider.of<AppointmentProvider>(context, listen: false).selectedDay)), // Pass _selectedDay
          );
        },
        tooltip: appLocalizations.addAppointment,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final appointmentProvider = Provider.of<AppointmentProvider>(context);

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          locale: appLocalizations.localeName,
          firstDay: DateTime.utc(2010, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: appointmentProvider.focusedDay,
          calendarFormat: appointmentProvider.calendarFormat,
          selectedDayPredicate: (day) => isSameDay(appointmentProvider.selectedDay, day),
          onDaySelected: appointmentProvider.onDaySelected,
          onFormatChanged: appointmentProvider.onFormatChanged,
          onPageChanged: appointmentProvider.onPageChanged,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentList(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final patientProvider =
        Provider.of<PatientProvider>(context, listen: false);
    final selectedAppointments = appointmentProvider.appointmentsForSelectedDate;

    if (selectedAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(appLocalizations.noAppointmentsForDate,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: selectedAppointments.length,
      itemBuilder: (context, index) {
        final appointment = selectedAppointments[index];
        Patient? patient;
        try {
          patient = patientProvider.patients
              .firstWhere((p) => p.patientId == appointment.patientId);
        } catch (e) {
          // Patient not found, handle gracefully
        }

        final statusColor = appointmentStatusColor(appointment.status);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: statusColor, width: 5),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColorLight,
              child: Text(
                patient?.name.substring(0, 1) ?? '?',
                style: TextStyle(color: Theme.of(context).primaryColorDark),
              ),
            ),
            title: Text(patient?.name ??
                '${appLocalizations.patient} #${appointment.patientId}'),
            subtitle: Text(
                '${DateFormat.jm(appLocalizations.localeName).format(DateTime.parse(appointment.appointmentDate))} - ${getLocalizedAppointmentStatus(appointment.status, appLocalizations)}'),
            trailing: Container(
              width: 96,  
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: appLocalizations.editAppointmentTitle,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AppointmentFormScreen(appointment: appointment),
                        ),
                      );
                    },
                  ),
                IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, appLocalizations, () {
                    Provider.of<AppointmentProvider>(context, listen: false)
                        .deleteAppointment(appointment.appointmentId!);
                  });
                },
              ),
                ],
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AppointmentFormScreen(appointment: appointment),
                ),
              );
            },
          ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, AppLocalizations appLocalizations, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.delete),
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
                onDelete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 450,
          child: _buildCalendar(context),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: _buildAppointmentList(context),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      children: [
        _buildCalendar(context),
        Expanded(
          child: _buildAppointmentList(context),
        ),
      ],
    );
  }
}
