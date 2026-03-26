import 'package:flutter/material.dart' show Color;

import 'app_localizations.dart';

/// Maps Arabic DB status values to localized display strings
String getLocalizedAppointmentStatus(String dbValue, AppLocalizations l10n) {
  switch (dbValue) {
    case 'محجوز':
      return l10n.statusBooked;
    case 'ملغي':
      return l10n.statusCancelled;
    case 'منجز':
      return l10n.statusCompleted;
    case 'لم يحضر':
      return 'No Show';
    default:
      return dbValue;
  }
}

Color appointmentStatusColor(String status) {
  switch (status) {
    case 'منجز':
      return const Color(0xFF4CAF50); // green
    case 'محجوز':
      return const Color(0xFFFFC107); // yellow/amber
    case 'ملغي':
      return const Color(0xFFF44336); // red
    case 'لم يحضر':
      return const Color(0xFF2196F3); // blue
    default:
      return const Color(0xFF9E9E9E); // grey
  }
}

String getLocalizedTreatmentStatus(String dbValue, AppLocalizations l10n) {
  switch (dbValue) {
    case 'قيد التنفيذ':
      return l10n.statusInProgress;
    case 'مكتمل':
      return l10n.statusCompleted;
    case 'متابعة':
      return l10n.statusFollowUp;
    default:
      return dbValue;
  }
}

String getLocalizedInvoiceStatus(String dbValue, AppLocalizations l10n) {
  switch (dbValue) {
    case 'مسودة':
      return l10n.invoiceStatusDraft;
    case 'مدفوعة جزئياً':
      return l10n.invoiceStatusPartiallyPaid;
    case 'مدفوعة بالكامل':
      return l10n.invoiceStatusFullyPaid;
    default:
      return dbValue;
  }
}

String getLocalizedPaymentMethod(String dbValue, AppLocalizations l10n) {
  switch (dbValue) {
    case 'نقدي':
      return l10n.paymentCash;
    case 'بطاقة':
      return l10n.paymentCard;
    case 'تحويل':
      return l10n.paymentTransfer;
    default:
      return dbValue;
  }
}

String getLocalizedGender(String dbValue, AppLocalizations l10n) {
  switch (dbValue) {
    case 'ذكر':
      return l10n.genderMale;
    case 'أنثى':
      return l10n.genderFemale;
    default:
      return dbValue;
  }
}

String getLocalizedMaritalStatus(String dbValue, AppLocalizations l10n) {
  switch (dbValue) {
    case 'أعزب':
      return l10n.maritalSingle;
    case 'متزوج':
      return l10n.maritalMarried;
    case 'مطلق':
      return l10n.maritalDivorced;
    case 'أرمل':
      return l10n.maritalWidowed;
    default:
      return dbValue;
  }
}
