import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'عيادة الأسنان'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @patients.
  ///
  /// In ar, this message translates to:
  /// **'المرضى'**
  String get patients;

  /// No description provided for @appointments.
  ///
  /// In ar, this message translates to:
  /// **'المواعيد'**
  String get appointments;

  /// No description provided for @invoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get invoices;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get more;

  /// No description provided for @dashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dashboard;

  /// No description provided for @amountMustBePositive.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون المبلغ أكبر من الصفر'**
  String get amountMustBePositive;

  /// No description provided for @editPayment.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الدفعة'**
  String get editPayment;

  /// No description provided for @errorUpdatingPayment.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحديث الدفعة'**
  String get errorUpdatingPayment;

  /// No description provided for @paymentDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الدفع'**
  String get paymentDate;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @appointmentConflictMessage.
  ///
  /// In ar, this message translates to:
  /// **'يوجد موعد في نفس الوقت مع المريض:'**
  String get appointmentConflictMessage;

  /// No description provided for @patientsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد المرضى'**
  String get patientsCount;

  /// No description provided for @todaysAppointments.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد اليوم'**
  String get todaysAppointments;

  /// No description provided for @pendingInvoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير المعلقة'**
  String get pendingInvoices;

  /// No description provided for @addPatient.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مريض'**
  String get addPatient;

  /// No description provided for @addAppointment.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موعد'**
  String get addAppointment;

  /// No description provided for @addInvoice.
  ///
  /// In ar, this message translates to:
  /// **'إضافة فاتورة'**
  String get addInvoice;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @fileNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الملف'**
  String get fileNumber;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// No description provided for @age.
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In ar, this message translates to:
  /// **'الجنس'**
  String get gender;

  /// No description provided for @actions.
  ///
  /// In ar, this message translates to:
  /// **'التحكم'**
  String get actions;

  /// No description provided for @noLinkedTreatmentsFound.
  ///
  /// In ar, this message translates to:
  /// **'لا علاجات لهذا المريض'**
  String get noLinkedTreatmentsFound;

  /// No description provided for @pleaseSelectPatientFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر مريض رجاء'**
  String get pleaseSelectPatientFirst;

  /// No description provided for @viewInvoice.
  ///
  /// In ar, this message translates to:
  /// **'رؤية الفاتورة'**
  String get viewInvoice;

  /// No description provided for @time.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get time;

  /// No description provided for @viewPatient.
  ///
  /// In ar, this message translates to:
  /// **'رؤية المريض'**
  String get viewPatient;

  /// No description provided for @notEnoughDataForTrend.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد معلومات كافية'**
  String get notEnoughDataForTrend;

  /// No description provided for @exportingData.
  ///
  /// In ar, this message translates to:
  /// **'تصدير البيانات'**
  String get exportingData;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In ar, this message translates to:
  /// **'تصريح التخزين مطلوب'**
  String get storagePermissionRequired;

  /// No description provided for @backupFileTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسم الملف'**
  String get backupFileTitle;

  /// No description provided for @importingData.
  ///
  /// In ar, this message translates to:
  /// **'استيراد البيانات'**
  String get importingData;

  /// No description provided for @displaySettings.
  ///
  /// In ar, this message translates to:
  /// **'الاعدادات'**
  String get displaySettings;

  /// No description provided for @development.
  ///
  /// In ar, this message translates to:
  /// **'التطوير'**
  String get development;

  /// No description provided for @whatsappNotInstalled.
  ///
  /// In ar, this message translates to:
  /// **'واتس اب غير مثبت'**
  String get whatsappNotInstalled;

  /// No description provided for @patientInformation.
  ///
  /// In ar, this message translates to:
  /// **'معلومات المريض'**
  String get patientInformation;

  /// No description provided for @patientName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المريض'**
  String get patientName;

  /// No description provided for @dataManagement.
  ///
  /// In ar, this message translates to:
  /// **'ادارة البيانات'**
  String get dataManagement;

  /// No description provided for @invoiceNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الفاتورة'**
  String get invoiceNumber;

  /// No description provided for @fullyPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوعة بالكامل'**
  String get fullyPaid;

  /// No description provided for @clinicInformation.
  ///
  /// In ar, this message translates to:
  /// **'معلومات العيادة'**
  String get clinicInformation;

  /// No description provided for @contactInformation.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التواصل '**
  String get contactInformation;

  /// No description provided for @personalInformation.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الشخصية'**
  String get personalInformation;

  /// No description provided for @currencySymbol.
  ///
  /// In ar, this message translates to:
  /// **'ل.س'**
  String get currencySymbol;

  /// No description provided for @maritalStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة الاجتماعية'**
  String get maritalStatus;

  /// No description provided for @address.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get address;

  /// No description provided for @firstVisitDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ أول زيارة'**
  String get firstVisitDate;

  /// No description provided for @xrayGallery.
  ///
  /// In ar, this message translates to:
  /// **'معرض الأشعة السينية'**
  String get xrayGallery;

  /// No description provided for @noTreatmentsFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على علاجات.'**
  String get noTreatmentsFound;

  /// No description provided for @noInvoicesFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على فواتير.'**
  String get noInvoicesFound;

  /// No description provided for @noAppointmentsFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على مواعيد.'**
  String get noAppointmentsFound;

  /// No description provided for @noDiagnosis.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تشخيص'**
  String get noDiagnosis;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @invoice.
  ///
  /// In ar, this message translates to:
  /// **'الفاتورة'**
  String get invoice;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @appointment.
  ///
  /// In ar, this message translates to:
  /// **'الموعد'**
  String get appointment;

  /// No description provided for @treatments.
  ///
  /// In ar, this message translates to:
  /// **'العلاجات'**
  String get treatments;

  /// No description provided for @patient.
  ///
  /// In ar, this message translates to:
  /// **'المريض'**
  String get patient;

  /// No description provided for @invoiceDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الفاتورة'**
  String get invoiceDate;

  /// No description provided for @totalAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ الإجمالي'**
  String get totalAmount;

  /// No description provided for @linkedTreatments.
  ///
  /// In ar, this message translates to:
  /// **'العلاجات المرتبطة'**
  String get linkedTreatments;

  /// No description provided for @noLinkedTreatments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد علاجات مرتبطة.'**
  String get noLinkedTreatments;

  /// No description provided for @payments.
  ///
  /// In ar, this message translates to:
  /// **'المدفوعات'**
  String get payments;

  /// No description provided for @addPayment.
  ///
  /// In ar, this message translates to:
  /// **'إضافة دفعة'**
  String get addPayment;

  /// No description provided for @noPaymentsFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على مدفوعات.'**
  String get noPaymentsFound;

  /// No description provided for @amount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get amount;

  /// No description provided for @method.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get method;

  /// No description provided for @editAppointmentTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الموعد'**
  String get editAppointmentTitle;

  /// No description provided for @patientFormField.
  ///
  /// In ar, this message translates to:
  /// **'المريض'**
  String get patientFormField;

  /// No description provided for @pleaseSelectPatient.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء اختيار مريض'**
  String get pleaseSelectPatient;

  /// No description provided for @dateFormField.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get dateFormField;

  /// No description provided for @timeFormField.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get timeFormField;

  /// No description provided for @notesFormField.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get notesFormField;

  /// No description provided for @doctorNotesFormField.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الطبيب'**
  String get doctorNotesFormField;

  /// No description provided for @statusFormField.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get statusFormField;

  /// No description provided for @updateAppointmentButton.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الموعد'**
  String get updateAppointmentButton;

  /// No description provided for @noAppointmentsForDate.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواعيد لهذا التاريخ.'**
  String get noAppointmentsForDate;

  /// No description provided for @quickActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get quickActions;

  /// No description provided for @addExpenseTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مصروف'**
  String get addExpenseTitle;

  /// No description provided for @editExpenseTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المصروف'**
  String get editExpenseTitle;

  /// No description provided for @descriptionFormField.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get descriptionFormField;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال المبلغ'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال رقم صحيح'**
  String get pleaseEnterValidNumber;

  /// No description provided for @categoryFormField.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get categoryFormField;

  /// No description provided for @addExpenseButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مصروف'**
  String get addExpenseButton;

  /// No description provided for @updateExpenseButton.
  ///
  /// In ar, this message translates to:
  /// **'تحديث المصروف'**
  String get updateExpenseButton;

  /// No description provided for @expenses.
  ///
  /// In ar, this message translates to:
  /// **'المصروفات'**
  String get expenses;

  /// No description provided for @filterByCategory.
  ///
  /// In ar, this message translates to:
  /// **'تصفية حسب الفئة'**
  String get filterByCategory;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'جميع الفئات'**
  String get allCategories;

  /// No description provided for @noExpensesForCategory.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مصاريف لهذه الفئة.'**
  String get noExpensesForCategory;

  /// No description provided for @noDescription.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد وصف'**
  String get noDescription;

  /// No description provided for @patientNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على المريض'**
  String get patientNotFound;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @editInvoiceTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الفاتورة'**
  String get editInvoiceTitle;

  /// No description provided for @invoiceDateFormField.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الفاتورة'**
  String get invoiceDateFormField;

  /// No description provided for @totalAmountFormField.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ الإجمالي'**
  String get totalAmountFormField;

  /// No description provided for @pleaseEnterTotalAmount.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال المبلغ الإجمالي'**
  String get pleaseEnterTotalAmount;

  /// No description provided for @noTreatmentsForPatient.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد علاجات متاحة لهذا المريض.'**
  String get noTreatmentsForPatient;

  /// No description provided for @updateInvoiceButton.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الفاتورة'**
  String get updateInvoiceButton;

  /// No description provided for @invoiceId.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة #'**
  String get invoiceId;

  /// No description provided for @patientId.
  ///
  /// In ar, this message translates to:
  /// **'رقم المريض'**
  String get patientId;

  /// No description provided for @reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @editPatientTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات المريض'**
  String get editPatientTitle;

  /// No description provided for @pleaseEnterPatientName.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال اسم المريض'**
  String get pleaseEnterPatientName;

  /// No description provided for @selectFirstVisitDate.
  ///
  /// In ar, this message translates to:
  /// **'اختر تاريخ الزيارة الأولى'**
  String get selectFirstVisitDate;

  /// No description provided for @xrayImagePath.
  ///
  /// In ar, this message translates to:
  /// **'مسار صورة الأشعة'**
  String get xrayImagePath;

  /// No description provided for @updatePatientButton.
  ///
  /// In ar, this message translates to:
  /// **'تحديث بيانات المريض'**
  String get updatePatientButton;

  /// No description provided for @searchPatientsHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن المرضى...'**
  String get searchPatientsHint;

  /// No description provided for @noPatientsFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على مرضى.'**
  String get noPatientsFound;

  /// No description provided for @fileNo.
  ///
  /// In ar, this message translates to:
  /// **'رقم الملف:'**
  String get fileNo;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف:'**
  String get phoneLabel;

  /// No description provided for @na.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get na;

  /// No description provided for @editPaymentTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الدفعة'**
  String get editPaymentTitle;

  /// No description provided for @updatePaymentButton.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الدفعة'**
  String get updatePaymentButton;

  /// No description provided for @financialOverview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة مالية'**
  String get financialOverview;

  /// No description provided for @totalRevenue.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الإيرادات'**
  String get totalRevenue;

  /// No description provided for @totalExpenses.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المصروفات'**
  String get totalExpenses;

  /// No description provided for @outstandingInvoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير المستحقة'**
  String get outstandingInvoices;

  /// No description provided for @expenseBreakdown.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المصروفات'**
  String get expenseBreakdown;

  /// No description provided for @revenueTrend.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه الإيرادات'**
  String get revenueTrend;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @theme.
  ///
  /// In ar, this message translates to:
  /// **'السمة'**
  String get theme;

  /// No description provided for @importSampleData.
  ///
  /// In ar, this message translates to:
  /// **'استيراد بيانات عينة (JSON)'**
  String get importSampleData;

  /// No description provided for @importSampleDataSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تحميل بيانات عينة من assets/data/sample_data.json'**
  String get importSampleDataSubtitle;

  /// No description provided for @sampleDataImportInitiated.
  ///
  /// In ar, this message translates to:
  /// **'بدء استيراد بيانات العينة.'**
  String get sampleDataImportInitiated;

  /// No description provided for @addTreatment.
  ///
  /// In ar, this message translates to:
  /// **'إضافة علاج'**
  String get addTreatment;

  /// No description provided for @editTreatment.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العلاج'**
  String get editTreatment;

  /// No description provided for @diagnosis.
  ///
  /// In ar, this message translates to:
  /// **'التشخيص'**
  String get diagnosis;

  /// No description provided for @treatmentDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العلاج'**
  String get treatmentDetails;

  /// No description provided for @toothNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم السن'**
  String get toothNumber;

  /// No description provided for @agreedAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المتفق عليه'**
  String get agreedAmount;

  /// No description provided for @updateTreatment.
  ///
  /// In ar, this message translates to:
  /// **'تحديث العلاج'**
  String get updateTreatment;

  /// No description provided for @expenseCategoryRent.
  ///
  /// In ar, this message translates to:
  /// **'إيجار'**
  String get expenseCategoryRent;

  /// No description provided for @expenseCategorySalaries.
  ///
  /// In ar, this message translates to:
  /// **'رواتب'**
  String get expenseCategorySalaries;

  /// No description provided for @expenseCategoryMedicalSupplies.
  ///
  /// In ar, this message translates to:
  /// **'مواد طبية'**
  String get expenseCategoryMedicalSupplies;

  /// No description provided for @expenseCategoryOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get expenseCategoryOther;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء اختيار فئة'**
  String get pleaseSelectCategory;

  /// No description provided for @paidAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المدفوع'**
  String get paidAmount;

  /// No description provided for @remainingAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المتبقي'**
  String get remainingAmount;

  /// No description provided for @noImageSelected.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم اختيار أي صورة.'**
  String get noImageSelected;

  /// No description provided for @gallery.
  ///
  /// In ar, this message translates to:
  /// **'المعرض'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا'**
  String get camera;

  /// No description provided for @treatmentAlreadyInvoiced.
  ///
  /// In ar, this message translates to:
  /// **'موجود بالفعل في الفاتورة رقم {invoiceId}'**
  String treatmentAlreadyInvoiced(int invoiceId);

  /// No description provided for @exportData.
  ///
  /// In ar, this message translates to:
  /// **'تصدير البيانات'**
  String get exportData;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حفظ جميع بيانات التطبيق في ملف مضغوط'**
  String get exportDataSubtitle;

  /// No description provided for @importData.
  ///
  /// In ar, this message translates to:
  /// **'استيراد البيانات'**
  String get importData;

  /// No description provided for @importDataSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة البيانات من ملف نسخ احتياطي. سيؤدي هذا إلى الكتابة فوق جميع البيانات الحالية.'**
  String get importDataSubtitle;

  /// No description provided for @backupSuccessful.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء النسخة الاحتياطية بنجاح'**
  String get backupSuccessful;

  /// No description provided for @backupFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إنشاء النسخة الاحتياطية'**
  String get backupFailed;

  /// No description provided for @restoreSuccessful.
  ///
  /// In ar, this message translates to:
  /// **'تم استعادة البيانات بنجاح'**
  String get restoreSuccessful;

  /// No description provided for @restoreFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل استعادة البيانات'**
  String get restoreFailed;

  /// No description provided for @restoreWarningTitle.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد؟'**
  String get restoreWarningTitle;

  /// No description provided for @restoreWarningContent.
  ///
  /// In ar, this message translates to:
  /// **'سيؤدي استعادة البيانات إلى الكتابة فوق جميع البيانات الحالية في التطبيق. لا يمكن التراجع عن هذا الإجراء.'**
  String get restoreWarningContent;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @restore.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get restore;

  /// No description provided for @selectExportDirectory.
  ///
  /// In ar, this message translates to:
  /// **'اختر مجلد التصدير'**
  String get selectExportDirectory;

  /// No description provided for @exportSuccessful.
  ///
  /// In ar, this message translates to:
  /// **'تم التصدير بنجاح، تم حفظ الملف في:'**
  String get exportSuccessful;

  /// No description provided for @amountCannotBeZero.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون المبلغ أكبر من الصفر.'**
  String get amountCannotBeZero;

  /// No description provided for @amountExceedsRemaining.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ يتجاوز الرصيد المتبقي وهو'**
  String get amountExceedsRemaining;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @searchInvoicesHint.
  ///
  /// In ar, this message translates to:
  /// **'البحث باسم المريض أو رقم الفاتورة'**
  String get searchInvoicesHint;

  /// No description provided for @patientNameExists.
  ///
  /// In ar, this message translates to:
  /// **'يوجد مريض بهذا الاسم بالفعل.'**
  String get patientNameExists;

  /// No description provided for @netIncome.
  ///
  /// In ar, this message translates to:
  /// **'صافي الدخل'**
  String get netIncome;

  /// No description provided for @totalInvoices.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الفواتير'**
  String get totalInvoices;

  /// No description provided for @paidInvoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير المدفوعة'**
  String get paidInvoices;

  /// No description provided for @phoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneNumber;

  /// No description provided for @notAvailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get notAvailable;

  /// No description provided for @thankYouMessage.
  ///
  /// In ar, this message translates to:
  /// **'شكرا لك'**
  String get thankYouMessage;

  /// No description provided for @treatment.
  ///
  /// In ar, this message translates to:
  /// **'العلاج'**
  String get treatment;

  /// No description provided for @invoicePdfMessage.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء العثور على فاتورتك مرفقة.'**
  String get invoicePdfMessage;

  /// No description provided for @patientPhoneNumberMissing.
  ///
  /// In ar, this message translates to:
  /// **'رقم هاتف المريض مفقود. لا يمكن فتح الواتساب مباشرة.'**
  String get patientPhoneNumberMissing;

  /// No description provided for @laboratory.
  ///
  /// In ar, this message translates to:
  /// **'المخبر'**
  String get laboratory;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @items.
  ///
  /// In ar, this message translates to:
  /// **'عناصر'**
  String get items;

  /// No description provided for @noData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get noData;

  /// No description provided for @reset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين'**
  String get reset;

  /// No description provided for @resetApp.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين التطبيق'**
  String get resetApp;

  /// No description provided for @resetAppFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إعادة تعيين التطبيق'**
  String get resetAppFailed;

  /// No description provided for @resetAppSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف جميع البيانات وإعادة تعيين التطبيق إلى حالته الأولية.'**
  String get resetAppSubtitle;

  /// No description provided for @resetAppSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة تعيين التطبيق بنجاح'**
  String get resetAppSuccess;

  /// No description provided for @resetAppWarningContent.
  ///
  /// In ar, this message translates to:
  /// **'سيؤدي هذا إلى حذف جميع البيانات بشكل دائم. لا يمكن التراجع عن هذا الإجراء.'**
  String get resetAppWarningContent;

  /// No description provided for @resetAppWarningTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين التطبيق؟'**
  String get resetAppWarningTitle;

  /// No description provided for @resettingApp.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ إعادة تعيين التطبيق...'**
  String get resettingApp;

  /// No description provided for @deletePatient.
  ///
  /// In ar, this message translates to:
  /// **'حذف المريض'**
  String get deletePatient;

  /// No description provided for @deletePatientConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد أنك تريد حذف هذا المريض وجميع بياناته المرتبطة به؟'**
  String get deletePatientConfirmation;

  /// No description provided for @errorLoadingImage.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحميل الصورة'**
  String get errorLoadingImage;

  /// No description provided for @annotatedImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة مشروحة'**
  String get annotatedImage;

  /// No description provided for @patientExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصروفات المرضى'**
  String get patientExpenses;

  /// No description provided for @passwordDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال كلمة المرور'**
  String get passwordDialogTitle;

  /// No description provided for @passwordHintText.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordHintText;

  /// No description provided for @submit.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get submit;

  /// No description provided for @wrongPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور خاطئة, الرجاء المحاولة مرة أخرى'**
  String get wrongPassword;

  /// No description provided for @passwordRequired.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور مطلوبة'**
  String get passwordRequired;

  /// No description provided for @xRayAnalysisError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحليل الأشعة السينية'**
  String get xRayAnalysisError;

  /// No description provided for @xRayAnalysisResults.
  ///
  /// In ar, this message translates to:
  /// **'نتائج تحليل الأشعة السينية'**
  String get xRayAnalysisResults;

  /// No description provided for @analysisId.
  ///
  /// In ar, this message translates to:
  /// **'معرف التحليل'**
  String get analysisId;

  /// No description provided for @analysisDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التحليل'**
  String get analysisDate;

  /// No description provided for @imageQuality.
  ///
  /// In ar, this message translates to:
  /// **'جودة الصورة'**
  String get imageQuality;

  /// No description provided for @findings.
  ///
  /// In ar, this message translates to:
  /// **'النتائج'**
  String get findings;

  /// No description provided for @noSpecificFindingsDetected.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم الكشف عن نتائج محددة.'**
  String get noSpecificFindingsDetected;

  /// No description provided for @severity.
  ///
  /// In ar, this message translates to:
  /// **'الخطورة'**
  String get severity;

  /// No description provided for @recommendation.
  ///
  /// In ar, this message translates to:
  /// **'التوصية'**
  String get recommendation;

  /// No description provided for @medicalAdviceSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص النصيحة الطبية'**
  String get medicalAdviceSummary;

  /// No description provided for @noSummaryAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد ملخص متاح'**
  String get noSummaryAvailable;

  /// No description provided for @financialSummary.
  ///
  /// In ar, this message translates to:
  /// **'الملخص المالي'**
  String get financialSummary;

  /// No description provided for @totalExpensesLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المصاريف'**
  String get totalExpensesLabel;

  /// No description provided for @totalProfits.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأرباح'**
  String get totalProfits;

  /// No description provided for @confidence.
  ///
  /// In ar, this message translates to:
  /// **'ثقة'**
  String get confidence;

  /// No description provided for @appointmentOn.
  ///
  /// In ar, this message translates to:
  /// **'موعد في {date}'**
  String appointmentOn(String date);

  /// No description provided for @totalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get totalLabel;

  /// No description provided for @costs.
  ///
  /// In ar, this message translates to:
  /// **'تكاليف'**
  String get costs;

  /// No description provided for @costsCannotExceedAgreed.
  ///
  /// In ar, this message translates to:
  /// **'التكاليف لا يمكن أن تكون أكبر من المبلغ المتفق عليه'**
  String get costsCannotExceedAgreed;

  /// No description provided for @labName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المخبر'**
  String get labName;

  /// No description provided for @genderMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get genderFemale;

  /// No description provided for @maritalSingle.
  ///
  /// In ar, this message translates to:
  /// **'أعزب'**
  String get maritalSingle;

  /// No description provided for @maritalMarried.
  ///
  /// In ar, this message translates to:
  /// **'متزوج'**
  String get maritalMarried;

  /// No description provided for @maritalDivorced.
  ///
  /// In ar, this message translates to:
  /// **'مطلق'**
  String get maritalDivorced;

  /// No description provided for @maritalWidowed.
  ///
  /// In ar, this message translates to:
  /// **'أرمل'**
  String get maritalWidowed;

  /// No description provided for @statusBooked.
  ///
  /// In ar, this message translates to:
  /// **'محجوز'**
  String get statusBooked;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get statusCancelled;

  /// No description provided for @statusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'منجز'**
  String get statusCompleted;

  /// No description provided for @statusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get statusInProgress;

  /// No description provided for @statusFollowUp.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get statusFollowUp;

  /// No description provided for @invoiceStatusDraft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get invoiceStatusDraft;

  /// No description provided for @invoiceStatusPartiallyPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوعة جزئياً'**
  String get invoiceStatusPartiallyPaid;

  /// No description provided for @invoiceStatusFullyPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوعة بالكامل'**
  String get invoiceStatusFullyPaid;

  /// No description provided for @paymentCash.
  ///
  /// In ar, this message translates to:
  /// **'نقدي'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة'**
  String get paymentCard;

  /// No description provided for @paymentTransfer.
  ///
  /// In ar, this message translates to:
  /// **'تحويل'**
  String get paymentTransfer;

  /// No description provided for @generateTestData.
  ///
  /// In ar, this message translates to:
  /// **'توليد بيانات تجريبية'**
  String get generateTestData;

  /// No description provided for @generateTestDataSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء مرضى ومواعيد وعلاجات وفواتير ومصاريف عشوائية للاختبار'**
  String get generateTestDataSubtitle;

  /// No description provided for @numberOfPatients.
  ///
  /// In ar, this message translates to:
  /// **'عدد المرضى'**
  String get numberOfPatients;

  /// No description provided for @dataLanguage.
  ///
  /// In ar, this message translates to:
  /// **'لغة البيانات'**
  String get dataLanguage;

  /// No description provided for @dataLanguageArabic.
  ///
  /// In ar, this message translates to:
  /// **'عربي'**
  String get dataLanguageArabic;

  /// No description provided for @dataLanguageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'إنجليزي'**
  String get dataLanguageEnglish;

  /// No description provided for @dataLanguageMixed.
  ///
  /// In ar, this message translates to:
  /// **'مختلط'**
  String get dataLanguageMixed;

  /// No description provided for @generate.
  ///
  /// In ar, this message translates to:
  /// **'توليد'**
  String get generate;

  /// No description provided for @generating.
  ///
  /// In ar, this message translates to:
  /// **'جاري التوليد...'**
  String get generating;

  /// No description provided for @generatingTestData.
  ///
  /// In ar, this message translates to:
  /// **'جاري توليد البيانات التجريبية...'**
  String get generatingTestData;

  /// No description provided for @testDataGenerated.
  ///
  /// In ar, this message translates to:
  /// **'تم توليد البيانات التجريبية بنجاح!'**
  String get testDataGenerated;

  /// No description provided for @testDataError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في توليد البيانات التجريبية'**
  String get testDataError;

  /// No description provided for @pleaseEnterNumberOfPatients.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال عدد المرضى'**
  String get pleaseEnterNumberOfPatients;

  /// No description provided for @pleaseEnterValidPositiveNumber.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال رقم صحيح موجب'**
  String get pleaseEnterValidPositiveNumber;

  /// No description provided for @security.
  ///
  /// In ar, this message translates to:
  /// **'الأمان'**
  String get security;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @createPassword.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء كلمة مرور'**
  String get createPassword;

  /// No description provided for @createPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'قم بتعيين كلمة مرور لحماية بيانات العيادة'**
  String get createPasswordSubtitle;

  /// No description provided for @createPasswordButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء كلمة المرور'**
  String get createPasswordButton;

  /// No description provided for @enterPassword.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بعودتك'**
  String get enterPassword;

  /// No description provided for @enterPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور لفتح التطبيق'**
  String get enterPasswordSubtitle;

  /// No description provided for @confirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPassword;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال كلمة المرور'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء تأكيد كلمة المرور'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن تكون كلمة المرور 4 أحرف على الأقل'**
  String get passwordTooShort;

  /// No description provided for @incorrectPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير صحيحة'**
  String get incorrectPassword;

  /// No description provided for @unlock.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get unlock;

  /// No description provided for @changePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديث كلمة مرور التطبيق'**
  String get changePasswordSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور بنجاح'**
  String get passwordChanged;

  /// No description provided for @verifyPassword.
  ///
  /// In ar, this message translates to:
  /// **'التحقق من كلمة المرور'**
  String get verifyPassword;

  /// No description provided for @verify.
  ///
  /// In ar, this message translates to:
  /// **'تحقق'**
  String get verify;

  /// No description provided for @createNewPasswordAfterReset.
  ///
  /// In ar, this message translates to:
  /// **'تم إعادة تعيين بيانات التطبيق. الرجاء إنشاء كلمة مرور جديدة.'**
  String get createNewPasswordAfterReset;

  /// No description provided for @backupPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور النسخة الاحتياطية'**
  String get backupPasswordTitle;

  /// No description provided for @backupPasswordMessage.
  ///
  /// In ar, this message translates to:
  /// **'هذه النسخة الاحتياطية مشفرة. أدخل كلمة المرور التي تم استخدامها عند إنشائها.'**
  String get backupPasswordMessage;

  /// No description provided for @wrongBackupPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور النسخة الاحتياطية خاطئة. يرجى المحاولة مرة أخرى.'**
  String get wrongBackupPassword;

  /// No description provided for @backup.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get backup;

  /// No description provided for @backupLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع النسخ الاحتياطي'**
  String get backupLocation;

  /// No description provided for @backupLocationSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يتم حفظ ملفات النسخ الاحتياطي في هذا المجلد'**
  String get backupLocationSubtitle;

  /// No description provided for @selectBackupDirectory.
  ///
  /// In ar, this message translates to:
  /// **'اختر مجلد النسخ الاحتياطي'**
  String get selectBackupDirectory;

  /// No description provided for @backupNow.
  ///
  /// In ar, this message translates to:
  /// **'نسخ احتياطي الآن'**
  String get backupNow;

  /// No description provided for @backupNowSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء نسخة احتياطية مشفرة في الموقع المحدد'**
  String get backupNowSubtitle;

  /// No description provided for @backupInProgress.
  ///
  /// In ar, this message translates to:
  /// **'جاري إنشاء النسخة الاحتياطية...'**
  String get backupInProgress;

  /// No description provided for @backupSavedAt.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ النسخة الاحتياطية في:'**
  String get backupSavedAt;

  /// No description provided for @defaultBackupLocation.
  ///
  /// In ar, this message translates to:
  /// **'افتراضي (دعم التطبيق/ClinC Backups)'**
  String get defaultBackupLocation;

  /// No description provided for @autoBackupSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء النسخة الاحتياطية التلقائية بنجاح'**
  String get autoBackupSuccess;

  /// No description provided for @autoBackupFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل النسخ الاحتياطي التلقائي — تحقق من موقع النسخ الاحتياطي في الإعدادات'**
  String get autoBackupFailed;

  /// No description provided for @backupRetentionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاحتفاظ بالنسخ الاحتياطية لمدة'**
  String get backupRetentionTitle;

  /// No description provided for @backupRetentionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يتم حذف النسخ الاحتياطية الأقدم من هذا تلقائياً'**
  String get backupRetentionSubtitle;

  /// No description provided for @autoBackupFrequencyTitle.
  ///
  /// In ar, this message translates to:
  /// **'تكرار النسخ الاحتياطي التلقائي'**
  String get autoBackupFrequencyTitle;

  /// No description provided for @autoBackupFrequencySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كم مرة يتم إنشاء نسخ احتياطية تلقائية'**
  String get autoBackupFrequencySubtitle;

  /// No description provided for @day.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get day;

  /// No description provided for @days.
  ///
  /// In ar, this message translates to:
  /// **'أيام'**
  String get days;

  /// No description provided for @every6Hours.
  ///
  /// In ar, this message translates to:
  /// **'كل 6 ساعات'**
  String get every6Hours;

  /// No description provided for @every12Hours.
  ///
  /// In ar, this message translates to:
  /// **'كل 12 ساعة'**
  String get every12Hours;

  /// No description provided for @daily.
  ///
  /// In ar, this message translates to:
  /// **'يومياً'**
  String get daily;

  /// No description provided for @every2Days.
  ///
  /// In ar, this message translates to:
  /// **'كل يومين'**
  String get every2Days;

  /// No description provided for @weekly.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعياً'**
  String get weekly;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
