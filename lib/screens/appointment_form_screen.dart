import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localization_helpers.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import '../providers/appointment_provider.dart';
import '../providers/patient_provider.dart';

class AppointmentFormScreen extends StatefulWidget {
  final Appointment? appointment;
    final int? patientId;

  final DateTime? initialDate; // New optional parameter

  const AppointmentFormScreen({super.key, this.appointment, this.initialDate,this.patientId}); // Add to constructor

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedPatientId;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _notesController;
  late String _status;

  final TextEditingController _patientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.appointment?.patientId;
       if(widget.patientId!=null) {
      _selectedPatientId=widget.patientId;
    }
    _selectedDate = widget.initialDate ?? // Use initialDate if provided
                    (widget.appointment != null
                        ? DateTime.parse(widget.appointment!.appointmentDate)
                        : DateTime.now());
    _selectedTime = widget.appointment != null
        ? TimeOfDay.fromDateTime(
            DateTime.parse(widget.appointment!.appointmentDate))
        : TimeOfDay.now();
    _notesController = TextEditingController(text: widget.appointment?.notes);
 
    _status = widget.appointment?.status ?? 'محجوز';

    // Clear selection if user types a name that is not in the list
    _patientController.addListener(() {
      if (_selectedPatientId != null) {
        final patientProvider = Provider.of<PatientProvider>(context, listen: false);
        final selectedPatient = patientProvider.patients.firstWhere((p) => p.patientId == _selectedPatientId);
        if (selectedPatient == null || _patientController.text != selectedPatient.name) {
          setState(() {
            _selectedPatientId = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _patientController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    //  initialEntryMode: TimePickerEntryMode.
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveAppointment() {
    if (_formKey.currentState!.validate()) {
      final DateTime combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);
      final appLocalizations = AppLocalizations.of(context)!;

      // Check for existing appointments at the same time and date
      final existingAppointments = appointmentProvider.appointments;
      for (var existingApp in existingAppointments) {
        final existingDateTime = DateTime.parse(existingApp.appointmentDate);

        // Check if the existing appointment is at the same date and time
        // and is not the current appointment being edited
        if (existingDateTime.year == combinedDateTime.year &&
            existingDateTime.month == combinedDateTime.month &&
            existingDateTime.day == combinedDateTime.day &&
            existingDateTime.hour == combinedDateTime.hour &&
            existingDateTime.minute == combinedDateTime.minute &&
            (widget.appointment == null || existingApp.appointmentId != widget.appointment!.appointmentId)) {

          // Conflict found! Get the patient's name
          final conflictingPatient = patientProvider.patients.firstWhere(
            (p) => p.patientId == existingApp.patientId,

          );

          // Show error message in Arabic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${appLocalizations.appointmentConflictMessage} ${conflictingPatient.name}',
                textAlign: TextAlign.right, // For Arabic text
              ),
              backgroundColor: Colors.red,
            ),
          );
          return; // Stop saving the appointment
        }
      }

      final newAppointment = Appointment(
        appointmentId: widget.appointment?.appointmentId,
        patientId: _selectedPatientId!,
        appointmentDate: combinedDateTime.toIso8601String(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        doctorNotes:'',
        status: _status,
      );

      if (widget.appointment == null) {
        appointmentProvider.addAppointment(newAppointment);
      } else {
        appointmentProvider.updateAppointment(newAppointment);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final patientProvider = Provider.of<PatientProvider>(context);
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface.withAlpha(10),
    );

    // Set initial value for patient controller if editing
    if (_patientController.text.isEmpty && _selectedPatientId != null) {
      final patient = patientProvider.patients.firstWhere((p) => p.patientId == _selectedPatientId);
      if (patient != null) {
        _patientController.text = patient.name;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null
            ? appLocalizations.addAppointment
            : appLocalizations.editAppointmentTitle),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Autocomplete<Patient>(
                    displayStringForOption: (Patient patient) => patient.name,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Patient>.empty();
                      }
                      return patientProvider.patients.where((Patient patient) {
                        return patient.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (Patient selection) {
                      setState(() {
                        _selectedPatientId = selection.patientId;
                        _patientController.text = selection.name;
                      });
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                      // Sync controllers
                      if (_patientController.text.isNotEmpty) {
                        fieldTextEditingController.text = _patientController.text;
                      }
                      return TextFormField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: inputDecoration.copyWith(labelText: appLocalizations.patientFormField),
                        validator: (value) {
                          if (_selectedPatientId == null) {
                            return appLocalizations.pleaseSelectPatient;
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: inputDecoration.copyWith(
                                labelText: appLocalizations.dateFormField),
                            child: Text(DateFormat.yMd(
                                    appLocalizations.localeName)
                                .format(_selectedDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context),
                          child: InputDecorator(
                            decoration: inputDecoration.copyWith(
                                labelText: appLocalizations.timeFormField),
                            child: Text(_selectedTime.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _notesController,
                    decoration: inputDecoration.copyWith(
                        labelText: appLocalizations.notesFormField,
                        alignLabelWithHint: true),
                    maxLines: 4,
                  ),            
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: inputDecoration.copyWith(
                        labelText: appLocalizations.statusFormField),
                    items: <String>['محجوز', 'ملغي', 'منجز', 'لم يحضر']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(getLocalizedAppointmentStatus(value, appLocalizations)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _status = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _saveAppointment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(widget.appointment == null
                        ? appLocalizations.addAppointment
                        : appLocalizations.updateAppointmentButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
