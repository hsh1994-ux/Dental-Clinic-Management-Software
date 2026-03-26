import 'dart:io';
import 'dart:math';

import '../models/appointment.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/invoice_treatment.dart';
import '../models/patient.dart';
import '../models/patient_xray.dart';
import '../models/payment.dart';
import '../models/treatment.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/invoice_treatment_repository.dart';
import '../repositories/patient_repository.dart';
import '../repositories/patient_xray_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/treatment_repository.dart';

enum DataLanguage { arabic, english, mixed }

class RandomDataGenerator {
  final _random = Random();
  final PatientRepository _patientRepo = PatientRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  final TreatmentRepository _treatmentRepo = TreatmentRepository();
  final InvoiceRepository _invoiceRepo = InvoiceRepository();
  final InvoiceTreatmentRepository _invoiceTreatmentRepo =
      InvoiceTreatmentRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final PatientXrayRepository _patientXrayRepo = PatientXrayRepository();

  // ─── Name pools ───

  static const _arabicFirstNamesMale = [
    'أحمد', 'محمد', 'علي', 'حسن', 'خالد', 'عمر', 'سعيد', 'يوسف',
    'إبراهيم', 'عبدالله', 'فيصل', 'سلطان', 'حمدان', 'راشد', 'ماجد',
    'طارق', 'نايف', 'بدر', 'سالم', 'حمد',
  ];
  static const _arabicFirstNamesFemale = [
    'فاطمة', 'عائشة', 'مريم', 'نورة', 'سارة', 'هدى', 'ليلى', 'أمل',
    'دانة', 'لطيفة', 'شيخة', 'موزة', 'حصة', 'علياء', 'رقية',
    'خديجة', 'سلمى', 'ريم', 'جميلة', 'منيرة',
  ];
  static const _arabicLastNames = [
    'الجابري', 'المنصوري', 'السعدي', 'الحارثي', 'البلوشي',
    'الهاشمي', 'الكندي', 'الراشدي', 'العامري', 'المحرزي',
    'الشامسي', 'النعيمي', 'الزعابي', 'الكعبي', 'المقبالي',
    'الرئيسي', 'البريكي', 'الحبسي', 'السيابي', 'الوهيبي',
  ];

  static const _englishFirstNamesMale = [
    'James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard',
    'Joseph', 'Thomas', 'Daniel', 'Matthew', 'Andrew', 'Christopher',
    'Steven', 'Kevin', 'Brian', 'George', 'Edward', 'Mark', 'Paul',
  ];
  static const _englishFirstNamesFemale = [
    'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara',
    'Susan', 'Jessica', 'Sarah', 'Karen', 'Lisa', 'Nancy', 'Betty',
    'Margaret', 'Sandra', 'Ashley', 'Emily', 'Donna', 'Michelle', 'Laura',
  ];
  static const _englishLastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
    'Davis', 'Rodriguez', 'Martinez', 'Anderson', 'Taylor', 'Thomas',
    'Moore', 'Jackson', 'Martin', 'Lee', 'Thompson', 'White', 'Harris',
  ];

  // ─── Dental data pools ───

  static const _diagnosisAr = [
    'تسوس الأسنان', 'التهاب اللثة', 'خراج سني', 'كسر في السن',
    'حساسية الأسنان', 'تآكل المينا', 'التهاب لب السن', 'فقدان الأسنان',
    'سوء إطباق', 'تراكم الجير', 'تقرحات الفم', 'انحسار اللثة',
    'ضرس العقل', 'تبييض الأسنان', 'تقويم الأسنان',
  ];
  static const _diagnosisEn = [
    'Dental caries', 'Gingivitis', 'Dental abscess', 'Tooth fracture',
    'Tooth sensitivity', 'Enamel erosion', 'Pulpitis', 'Tooth loss',
    'Malocclusion', 'Tartar buildup', 'Oral ulcers', 'Gum recession',
    'Wisdom tooth', 'Teeth whitening', 'Orthodontics',
  ];

  static const _treatmentDetailsAr = [
    'حشوة تجميلية', 'قلع السن', 'علاج العصب', 'تنظيف الأسنان',
    'تركيب تاج', 'زراعة أسنان', 'تبييض الأسنان بالليزر',
    'تركيب جسر', 'علاج اللثة', 'حشوة مؤقتة',
    'تقويم أسنان', 'خلع ضرس العقل', 'تلميع الأسنان',
    'تركيب طقم أسنان', 'ترميم الأسنان',
  ];
  static const _treatmentDetailsEn = [
    'Cosmetic filling', 'Tooth extraction', 'Root canal treatment',
    'Dental cleaning', 'Crown placement', 'Dental implant',
    'Laser teeth whitening', 'Bridge placement', 'Gum treatment',
    'Temporary filling', 'Orthodontic treatment', 'Wisdom tooth extraction',
    'Dental polishing', 'Denture fitting', 'Dental restoration',
  ];

  static const _notesAr = [
    'المريض يعاني من ألم شديد', 'متابعة بعد أسبوع',
    'يحتاج صورة أشعة', 'حالة مستعجلة', 'فحص دوري',
    'تحويل لأخصائي', 'المريض يتناول أدوية مسيلة للدم',
    'حساسية من البنسلين', 'يحتاج تخدير موضعي',
  ];
  static const _notesEn = [
    'Patient has severe pain', 'Follow-up in one week',
    'Needs X-ray', 'Urgent case', 'Routine checkup',
    'Referred to specialist', 'Patient on blood thinners',
    'Penicillin allergy', 'Needs local anesthesia',
  ];

  static const _labNamesAr = [
    'مختبر الابتسامة', 'مختبر الأسنان الذهبية', 'مختبر النور',
    'مختبر الخليج', 'مختبر السلامة',
  ];
  static const _labNamesEn = [
    'Smile Lab', 'Golden Dental Lab', 'Al Noor Lab',
    'Gulf Dental Lab', 'SafeCare Lab',
  ];

  static const _addressesAr = [
    'مسقط، الخوض', 'مسقط، بوشر', 'مسقط، السيب', 'مسقط، مطرح',
    'صلالة، صلالة الجديدة', 'صحار، المعبيلة', 'نزوى، المركز',
    'صور، الشرقية', 'عبري، الظاهرة', 'الرستاق، الباطنة',
  ];
  static const _addressesEn = [
    'Muscat, Al Khoud', 'Muscat, Bousher', 'Muscat, Al Seeb',
    'Muscat, Muttrah', 'Salalah, New Salalah', 'Sohar, Al Maabilah',
    'Nizwa, City Center', 'Sur, Al Sharqiyah', 'Ibri, Al Dhahira',
    'Al Rustaq, Al Batinah',
  ];

  static const _expenseDescriptionsAr = [
    'إيجار العيادة', 'رواتب الموظفين', 'مواد تعقيم',
    'أدوات طبية', 'صيانة الأجهزة', 'فاتورة كهرباء',
    'مستلزمات مكتبية', 'تأمين طبي', 'مواد تنظيف',
  ];
  static const _expenseDescriptionsEn = [
    'Clinic rent', 'Staff salaries', 'Sterilization supplies',
    'Medical instruments', 'Equipment maintenance', 'Electricity bill',
    'Office supplies', 'Medical insurance', 'Cleaning supplies',
  ];

  // ─── Helpers ───

  T _pick<T>(List<T> list) => list[_random.nextInt(list.length)];

  bool _useArabic(DataLanguage lang) {
    switch (lang) {
      case DataLanguage.arabic:
        return true;
      case DataLanguage.english:
        return false;
      case DataLanguage.mixed:
        return _random.nextBool();
    }
  }

  String _generatePhone() {
    // Omani-style phone: +968 9XXXXXXX
    final prefix = [9, 7][_random.nextInt(2)];
    final number =
        List.generate(7, (_) => _random.nextInt(10)).join();
    return '+968$prefix$number';
  }

  DateTime _randomDateInRange(DateTime start, DateTime end) {
    final diff = end.difference(start).inDays;
    return start.add(Duration(days: _random.nextInt(diff.clamp(1, 99999))));
  }

  // ─── Build combined x-ray image path list from x-ray_images folder ───

  List<String> _buildXrayImagePaths() {
    final paths = <String>[];
    // Try to locate the x-ray_images folder relative to the executable or
    // common dev locations.
    final candidates = [
      Platform.resolvedExecutable, // running binary path
      Platform.script.toFilePath(), // script path (dart run)
    ];

    for (final candidate in candidates) {
      // Walk up until we find the folder or run out of parents
      var dir = Directory(candidate).parent;
      for (int i = 0; i < 10; i++) {
        final xrayDir = Directory('${dir.path}/x-ray_images');
        if (xrayDir.existsSync()) {
          for (final sub in ['1', '2']) {
            final subDir = Directory('${xrayDir.path}/$sub');
            if (subDir.existsSync()) {
              final files = subDir
                  .listSync()
                  .whereType<File>()
                  .where((f) {
                    final ext = f.path.toLowerCase();
                    return ext.endsWith('.jpg') ||
                        ext.endsWith('.jpeg') ||
                        ext.endsWith('.png');
                  })
                  .map((f) => f.path)
                  .toList();
              paths.addAll(files);
            }
          }
          return paths;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    }
    return paths;
  }

  // ─── Main generate method ───

  Future<void> generate({
    required int patientCount,
    required DataLanguage language,
    required void Function(double progress) onProgress,
  }) async {
    final now = DateTime.now();
    final twoYearsAgo = now.subtract(const Duration(days: 730));

    // Build combined x-ray image path list once
    final xrayImagePaths = _buildXrayImagePaths();

    // 1. Create patients
    final List<int> patientIds = [];
    for (int i = 0; i < patientCount; i++) {
      final isArabic = _useArabic(language);
      final isMale = _random.nextBool();

      String firstName;
      String lastName;
      String gender;
      String maritalStatus;

      if (isArabic) {
        firstName = isMale
            ? _pick(_arabicFirstNamesMale)
            : _pick(_arabicFirstNamesFemale);
        lastName = _pick(_arabicLastNames);
        gender = isMale ? 'ذكر' : 'أنثى';
        maritalStatus = _pick(['أعزب', 'متزوج', 'مطلق', 'أرمل']);
      } else {
        firstName = isMale
            ? _pick(_englishFirstNamesMale)
            : _pick(_englishFirstNamesFemale);
        lastName = _pick(_englishLastNames);
        gender = isMale ? 'ذكر' : 'أنثى'; // DB always uses Arabic keys
        maritalStatus = _pick(['أعزب', 'متزوج', 'مطلق', 'أرمل']);
      }

      final age = 18 + _random.nextInt(62); // 18-79
      final firstVisitDate = _randomDateInRange(twoYearsAgo, now);

      final patient = Patient(
        name: '$firstName $lastName',
        age: age,
        gender: gender,
        address: isArabic ? _pick(_addressesAr) : _pick(_addressesEn),
        phone: _generatePhone(),
        maritalStatus: maritalStatus,
        fileNumber: '', // will be set after insert
        firstVisitDate: firstVisitDate.toIso8601String(),
      );

      final id = await _patientRepo.insertPatient(patient);
      // Update file number to match id
      final finalPatient = Patient(
        patientId: id,
        name: patient.name,
        age: age,
        gender: patient.gender,
        address: patient.address,
        phone: patient.phone,
        maritalStatus: patient.maritalStatus,
        fileNumber: id.toString(),
        firstVisitDate: patient.firstVisitDate,
      );
      await _patientRepo.updatePatient(finalPatient);
      patientIds.add(id);

      onProgress((i + 1) / patientCount * 0.25); // 0–25%
    }

    // 2. Create treatments (1-4 per patient) + x-ray images with treatment-related dates
    final List<_TreatmentInfo> treatmentInfos = [];
    for (int pi = 0; pi < patientIds.length; pi++) {
      final patientId = patientIds[pi];
      final treatmentCount = 1 + _random.nextInt(4);
      final isArabic = _useArabic(language);
      final patientTreatmentDates = <DateTime>[];

      for (int t = 0; t < treatmentCount; t++) {
        final agreedAmount = (100 + _random.nextInt(900)).toDouble(); // 100-999
        final expenses =
            _random.nextDouble() < 0.4 ? (10 + _random.nextInt(100)).toDouble() : 0.0;
        final statusOptions = ['قيد التنفيذ', 'مكتمل', 'متابعة'];
        final status = _pick(statusOptions);
        final treatmentDate = _randomDateInRange(
            DateTime.parse(
                '${now.year - 1}-01-01'), // within the last year
            now);

        final treatment = Treatment(
          patientId: patientId,
          diagnosis: isArabic ? _pick(_diagnosisAr) : _pick(_diagnosisEn),
          treatmentDetails: isArabic
              ? _pick(_treatmentDetailsAr)
              : _pick(_treatmentDetailsEn),
          toothNumber: (1 + _random.nextInt(32)).toString(),
          agreedAmount: agreedAmount,
          agreedAmountPaid: 0.0,
          treatmentDate: treatmentDate.toIso8601String(),
          status: status,
          expenses: expenses,
          laboratoryName: _random.nextDouble() < 0.3
              ? (isArabic ? _pick(_labNamesAr) : _pick(_labNamesEn))
              : null,
        );

        final treatmentId = await _treatmentRepo.insertTreatment(treatment);
        treatmentInfos.add(_TreatmentInfo(
          treatmentId: treatmentId,
          patientId: patientId,
          agreedAmount: agreedAmount,
          treatmentDate: treatmentDate,
        ));
        patientTreatmentDates.add(treatmentDate);
      }

      // Assign 0–10 x-ray images per patient, each dated near a treatment date
      if (xrayImagePaths.isNotEmpty && patientTreatmentDates.isNotEmpty) {
        final imageCount = _random.nextInt(11); // 0 to 10
        final shuffled = List<String>.from(xrayImagePaths)..shuffle(_random);
        final selected = shuffled.take(imageCount);
        for (final imagePath in selected) {
          // Pick a random treatment date and offset 0–7 days before it
          final baseDate = _pick(patientTreatmentDates);
          final daysOffset = _random.nextInt(8); // 0–7 days before treatment
          final xrayDate = baseDate.subtract(Duration(days: daysOffset));
          await _patientXrayRepo.insertPatientXray(PatientXray(
            patientId: patientId,
            imagePath: imagePath,
            createdAt: xrayDate.toIso8601String(),
          ));
        }
      }

      onProgress(0.25 + (pi + 1) / patientIds.length * 0.25); // 25–50%
    }

    // 3. Create appointments (1-3 per patient)
    for (int pi = 0; pi < patientIds.length; pi++) {
      final patientId = patientIds[pi];
      final appointmentCount = 1 + _random.nextInt(3);
      final isArabic = _useArabic(language);

      for (int a = 0; a < appointmentCount; a++) {
        final appointmentDate = _randomDateInRange(
            DateTime.parse('${now.year}-01-01'),
            now.add(const Duration(days: 30)));
        final hour = 8 + _random.nextInt(10); // 8 AM - 5 PM
        final minute = [0, 15, 30, 45][_random.nextInt(4)];
        final fullDate = DateTime(appointmentDate.year, appointmentDate.month,
            appointmentDate.day, hour, minute);
        final statusOptions = ['محجوز', 'ملغي', 'منجز'];
        final status = fullDate.isBefore(now)
            ? _pick(['منجز', 'ملغي'])
            : _pick(statusOptions);

        final appointment = Appointment(
          patientId: patientId,
          appointmentDate: fullDate.toIso8601String(),
          notes: _random.nextDouble() < 0.5
              ? (isArabic ? _pick(_notesAr) : _pick(_notesEn))
              : null,
          doctorNotes: '',
          status: status,
        );

        await _appointmentRepo.insertAppointment(appointment);
      }

      onProgress(0.5 + (pi + 1) / patientIds.length * 0.1); // 50–60%
    }

    // 4. Create invoices and link treatments
    // Group treatments by patient
    final Map<int, List<_TreatmentInfo>> treatmentsByPatient = {};
    for (var ti in treatmentInfos) {
      treatmentsByPatient.putIfAbsent(ti.patientId, () => []).add(ti);
    }

    final List<_InvoiceInfo> invoiceInfos = [];
    int invoiceIdx = 0;
    final totalInvoiceSteps = treatmentsByPatient.length;
    for (var entry in treatmentsByPatient.entries) {
      final patientId = entry.key;
      final treatments = entry.value;

      // Create 1-2 invoices per patient, splitting treatments
      final invoiceCount = treatments.length > 2 ? 1 + _random.nextInt(2) : 1;
      final treatmentsPerInvoice =
          (treatments.length / invoiceCount).ceil();

      for (int inv = 0; inv < invoiceCount; inv++) {
        final start = inv * treatmentsPerInvoice;
        final end = (start + treatmentsPerInvoice).clamp(0, treatments.length);
        if (start >= treatments.length) break;
        final invoiceTreatments = treatments.sublist(start, end);

        final totalAmount =
            invoiceTreatments.fold(0.0, (s, t) => s + t.agreedAmount);

        // Determine invoice status
        final roll = _random.nextDouble();
        String status;
        double paidAmount;
        if (roll < 0.35) {
          status = 'مدفوعة بالكامل';
          paidAmount = totalAmount;
        } else if (roll < 0.65) {
          status = 'مدفوعة جزئياً';
          paidAmount = (totalAmount * (0.2 + _random.nextDouble() * 0.6))
              .roundToDouble();
        } else {
          status = 'مسودة';
          paidAmount = 0;
        }

        final invoiceDate = invoiceTreatments.first.treatmentDate;

        final invoice = Invoice(
          patientId: patientId,
          invoiceDate: invoiceDate.toIso8601String(),
          totalAmount: totalAmount,
          status: status,
        );

        final invoiceId = await _invoiceRepo.insertInvoice(invoice);

        // Link treatments to invoice
        for (var ti in invoiceTreatments) {
          await _invoiceTreatmentRepo.insertInvoiceTreatment(
            InvoiceTreatment(
                invoiceId: invoiceId, treatmentId: ti.treatmentId),
          );

          // Update treatment's agreedAmountPaid proportionally
          if (paidAmount > 0) {
            final ratio = paidAmount / totalAmount;
            final paid = (ti.agreedAmount * ratio).roundToDouble();
            await _treatmentRepo.updateTreatmentPaidAmount(
                ti.treatmentId, paid);
          }
        }

        invoiceInfos.add(_InvoiceInfo(
          invoiceId: invoiceId,
          totalAmount: totalAmount,
          paidAmount: paidAmount,
          invoiceDate: invoiceDate,
        ));
      }

      invoiceIdx++;
      onProgress(0.6 + invoiceIdx / totalInvoiceSteps * 0.2); // 60–80%
    }

    // 5. Create payments for paid invoices
    for (int ii = 0; ii < invoiceInfos.length; ii++) {
      final info = invoiceInfos[ii];
      if (info.paidAmount <= 0) continue;

      // 1-3 payments per invoice
      final paymentCount = 1 + _random.nextInt(3);
      double remaining = info.paidAmount;

      for (int p = 0; p < paymentCount && remaining > 0; p++) {
        double payAmount;
        if (p == paymentCount - 1 || remaining < 10) {
          payAmount = remaining;
        } else {
          payAmount =
              (remaining * (0.3 + _random.nextDouble() * 0.5)).roundToDouble();
        }
        payAmount = payAmount.clamp(1, remaining);

        final paymentDate = _randomDateInRange(
            info.invoiceDate, now);

        final payment = Payment(
          invoiceId: info.invoiceId,
          amount: payAmount,
          paymentDate: paymentDate.toIso8601String(),
          method: _pick(['نقدي', 'بطاقة', 'تحويل']),
        );

        await _paymentRepo.insertPayment(payment);
        remaining -= payAmount;
      }

      onProgress(0.8 + (ii + 1) / invoiceInfos.length * 0.1); // 80–90%
    }

    // 6. Create expenses (clinic-level)
    final isArabicExpenses = _useArabic(language);
    final expenseCount = 5 + _random.nextInt(16); // 5-20 expenses
    for (int e = 0; e < expenseCount; e++) {
      final expenseDate = _randomDateInRange(twoYearsAgo, now);
      final categories = ['rent', 'salaries', 'medical_supplies', 'other'];
      final category = _pick(categories);
      double amount;
      switch (category) {
        case 'rent':
          amount = (500 + _random.nextInt(1500)).toDouble();
          break;
        case 'salaries':
          amount = (300 + _random.nextInt(2000)).toDouble();
          break;
        case 'medical_supplies':
          amount = (50 + _random.nextInt(500)).toDouble();
          break;
        default:
          amount = (10 + _random.nextInt(300)).toDouble();
      }

      final expense = Expense(
        description: isArabicExpenses
            ? _pick(_expenseDescriptionsAr)
            : _pick(_expenseDescriptionsEn),
        amount: amount,
        expenseDate: expenseDate.toIso8601String(),
        category: category,
      );

      await _expenseRepo.insertExpense(expense);

      onProgress(0.9 + (e + 1) / expenseCount * 0.1); // 90–100%
    }
  }
}

class _TreatmentInfo {
  final int treatmentId;
  final int patientId;
  final double agreedAmount;
  final DateTime treatmentDate;

  _TreatmentInfo({
    required this.treatmentId,
    required this.patientId,
    required this.agreedAmount,
    required this.treatmentDate,
  });
}

class _InvoiceInfo {
  final int invoiceId;
  final double totalAmount;
  final double paidAmount;
  final DateTime invoiceDate;

  _InvoiceInfo({
    required this.invoiceId,
    required this.totalAmount,
    required this.paidAmount,
    required this.invoiceDate,
  });
}
