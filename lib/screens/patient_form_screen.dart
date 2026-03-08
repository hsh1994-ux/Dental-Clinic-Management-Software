import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localization_helpers.dart';
import '../models/patient.dart';
import '../providers/patient_provider.dart';
import '../services/xray_storage_service.dart';

class PatientFormScreen extends StatefulWidget {
  final Patient? patient;

  const PatientFormScreen({super.key, this.patient});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  String? _gender;
  String? _maritalStatus;
  DateTime? _firstVisitDate;
  XFile? _xrayImageFile;
  String? _storedXrayImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.name);
    _ageController =
        TextEditingController(text: widget.patient?.age?.toString());
    _addressController = TextEditingController(text: widget.patient?.address);
    _phoneController = TextEditingController(text: widget.patient?.phone);
    _storedXrayImage = widget.patient?.xrayImage;
    _gender = widget.patient?.gender;
    _maritalStatus = widget.patient?.maritalStatus;
    _firstVisitDate = widget.patient?.firstVisitDate != null
        ? DateTime.parse(widget.patient!.firstVisitDate!)
        : DateTime.now(); // Default to now for new patients
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _firstVisitDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _firstVisitDate) {
      setState(() {
        _firstVisitDate = picked;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() {
        _xrayImageFile = image;
      });
    }
  }

  Future<void> _savePatient() async {
    if (_formKey.currentState!.validate()) {
      String? storedXrayImage = _storedXrayImage;

      try {
        if (_xrayImageFile != null) {
          storedXrayImage = await XRayStorageService.importImage(
            _xrayImageFile!.path,
          );
        } else if (storedXrayImage != null &&
            storedXrayImage.isNotEmpty &&
            !XRayStorageService.isEmbedded(storedXrayImage)) {
          storedXrayImage =
              await XRayStorageService.importImage(storedXrayImage);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        return;
      }

      final newPatient = Patient(
        patientId: widget.patient?.patientId,
        name: _nameController.text,
        age: int.tryParse(_ageController.text),
        gender: _gender,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        maritalStatus: _maritalStatus,
        fileNumber: widget.patient?.fileNumber ?? '', // Handled by provider
        firstVisitDate: _firstVisitDate?.toIso8601String(),
        xrayImage: storedXrayImage,
      );

      final provider = Provider.of<PatientProvider>(context, listen: false);
      if (widget.patient == null) {
        await provider.addPatient(newPatient);
      } else {
        await provider.updatePatient(newPatient);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Uint8List? get _embeddedPreviewBytes {
    return XRayStorageService.decodeEmbeddedBytes(_storedXrayImage);
  }

  String? get _legacyPreviewPath {
    return XRayStorageService.normalizeLegacyPath(_storedXrayImage);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient == null
            ? appLocalizations.addPatient
            : appLocalizations.editPatientTitle),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Padding for bottom bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(
                      context, appLocalizations.personalInformation),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(appLocalizations.name, context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLocalizations.pleaseEnterPatientName;
                      }
                      final patientProvider =
                          Provider.of<PatientProvider>(context, listen: false);
                      final trimmedValue = value.trim().toLowerCase();

                      final isNameExists = patientProvider.patients.any((patient) {
                        if (widget.patient != null &&
                            patient.patientId == widget.patient!.patientId) {
                          return false;
                        }
                        return patient.name.toLowerCase() == trimmedValue;
                      });

                      if (isNameExists) {
                        return appLocalizations.patientNameExists;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: _inputDecoration(appLocalizations.age, context),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: _inputDecoration(appLocalizations.gender, context),
                          items: <String>['ذكر', 'أنثى']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(getLocalizedGender(value, appLocalizations)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _gender = newValue;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _maritalStatus,
                    decoration:
                        _inputDecoration(appLocalizations.maritalStatus, context),
                    items: <String>['أعزب', 'متزوج', 'مطلق', 'أرمل']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(getLocalizedMaritalStatus(value, appLocalizations)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _maritalStatus = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                      context, appLocalizations.contactInformation),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _inputDecoration(appLocalizations.phone, context),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _addressController,
                    decoration: _inputDecoration(appLocalizations.address, context),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, appLocalizations.clinicInformation),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration:
                          _inputDecoration(appLocalizations.firstVisitDate, context),
                      child: Text(
                        _firstVisitDate == null
                            ? appLocalizations.selectFirstVisitDate
                            : DateFormat.yMd(appLocalizations.localeName)
                                .format(_firstVisitDate!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, appLocalizations.xrayGallery),
                  const SizedBox(height: 16),
                  _buildImagePicker(context),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    Widget preview;

    if (_xrayImageFile != null) {
      preview = Image.file(File(_xrayImageFile!.path), fit: BoxFit.cover);
    } else if (_embeddedPreviewBytes != null) {
      preview = Image.memory(_embeddedPreviewBytes!, fit: BoxFit.cover);
    } else if (_legacyPreviewPath != null &&
        _legacyPreviewPath!.isNotEmpty &&
        File(_legacyPreviewPath!).existsSync()) {
      preview = Image.file(File(_legacyPreviewPath!), fit: BoxFit.cover);
    } else {
      preview = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(appLocalizations.noImageSelected),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface.withAlpha(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: preview,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.image_outlined),
              label: Text(appLocalizations.gallery),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(appLocalizations.camera),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  InputDecoration _inputDecoration(String label, BuildContext context) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface.withAlpha(10),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return BottomAppBar(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _savePatient,
          icon: const Icon(Icons.save_outlined),
          label: Text(widget.patient == null
              ? appLocalizations.addPatient
              : appLocalizations.updatePatientButton),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}

