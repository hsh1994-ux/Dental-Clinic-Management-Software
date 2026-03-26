import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localization_helpers.dart';
import '../models/patient_xray.dart';
import '../models/treatment.dart';
import '../repositories/patient_xray_repository.dart';
import '../services/xray_storage_service.dart';
import 'patient_detail_screen.dart'; // for FullScreenImageViewer

class TreatmentDetailScreen extends StatelessWidget {
  final Treatment treatment;
  final String patientName;

  const TreatmentDetailScreen({
    super.key,
    required this.treatment,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final treatmentDay = DateTime.parse(treatment.treatmentDate);
    final currency = NumberFormat.currency(
      locale: l10n.localeName,
      symbol: l10n.currencySymbol,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(treatment.diagnosis ?? l10n.noDiagnosis),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: FutureBuilder<List<PatientXray>>(
        future: PatientXrayRepository().getXraysForPatient(treatment.patientId),
        builder: (context, snapshot) {
          final sameDay = (snapshot.data ?? []).where((x) {
            final xd = DateTime.parse(x.createdAt);
            return xd.year == treatmentDay.year &&
                xd.month == treatmentDay.month &&
                xd.day == treatmentDay.day;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Treatment details ──
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Treatment Details',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      _row(context, Icons.person_outline, l10n.patient,
                          patientName),
                      _row(
                          context,
                          Icons.medical_services_outlined,
                          l10n.diagnosis,
                          treatment.diagnosis ?? '-'),
                      _row(
                          context,
                          Icons.healing_outlined,
                          'Treatment',
                          treatment.treatmentDetails ?? '-'),
                      if (treatment.toothNumber != null)
                        _row(context, Icons.mood_outlined, 'Tooth #',
                            treatment.toothNumber!),
                      _row(
                          context,
                          Icons.calendar_today_outlined,
                          l10n.date,
                          DateFormat.yMd(l10n.localeName).format(treatmentDay)),
                      _row(
                          context,
                          Icons.info_outline,
                          l10n.status,
                          getLocalizedTreatmentStatus(
                              treatment.status, l10n)),
                      if (treatment.agreedAmount != null)
                        _row(
                            context,
                            Icons.attach_money_outlined,
                            'Agreed Amount',
                            currency.format(treatment.agreedAmount)),
                      if (treatment.agreedAmountPaid != null)
                        _row(
                            context,
                            Icons.check_circle_outline,
                            'Amount Paid',
                            currency.format(treatment.agreedAmountPaid)),
                      if (treatment.expenses != null &&
                          treatment.expenses! > 0)
                        _row(
                            context,
                            Icons.money_off_outlined,
                            l10n.expenses,
                            currency.format(treatment.expenses)),
                      if (treatment.laboratoryName != null)
                        _row(
                            context,
                            Icons.science_outlined,
                            'Laboratory',
                            treatment.laboratoryName!),
                    ],
                  ),
                ),
              ),

              // ── Same-day X-Ray images ──
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (sameDay.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('X-Rays taken on this day',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: sameDay.length,
                          itemBuilder: (context, i) {
                            final xray = sameDay[i];
                            final heroTag =
                                'treatment_xray_${xray.xrayId ?? i}';
                            final embeddedBytes =
                                XRayStorageService.decodeEmbeddedBytes(
                                    xray.imagePath);
                            final file = File(xray.imagePath);

                            Widget img;
                            if (embeddedBytes != null) {
                              img = Image.memory(embeddedBytes,
                                  fit: BoxFit.cover,
                                  width: double.infinity);
                            } else if (file.existsSync()) {
                              img = Image.file(file,
                                  fit: BoxFit.cover,
                                  width: double.infinity);
                            } else {
                              img = const Center(
                                  child: Icon(Icons.broken_image));
                            }

                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(
                                    heroTag: heroTag,
                                    imagePath: embeddedBytes == null
                                        ? xray.imagePath
                                        : null,
                                    imageBytes: embeddedBytes,
                                  ),
                                ),
                              ),
                              child: Hero(
                                tag: heroTag,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: img,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 12),
          Text('$label:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
