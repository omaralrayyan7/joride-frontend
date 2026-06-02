import 'package:flutter/material.dart';

/// Simple compile-time localization — no build_runner required.
/// To add more strings: add a key to [_en] and [_ar], then call
/// AppLocalizations.of(context).t('your_key').
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const delegate = _AppLocalizationsDelegate();

  // ── English strings ────────────────────────────────────────────────────────
  static const Map<String, String> _en = {
    // Auth
    'welcome_back': 'Welcome Back',
    'login_subtitle': 'Login to continue',
    'email': 'Email Address',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'login': 'Login',
    'logging_in': 'Logging in...',
    'continue_guest': 'Continue as Guest',
    'no_account': "Don't have an account?",
    'register_now': 'Register Now',
    'forgot_password': 'Forgot Password?',
    // Register
    'create_account': 'Create New Account',
    'full_name': 'Full Name',
    'phone': 'Phone Number',
    'id_number': 'ID Number',
    'license_number': 'Driving License Number',
    'sign_up': 'Sign Up & Verify',
    // Navigation / Drawer
    'map': 'Map',
    'reservations': 'My Reservations',
    'your_key': 'Your Key',
    'wallet': 'Wallet',
    'notifications': 'Notifications',
    'settings': 'Settings',
    'admin_dashboard': 'Admin Dashboard',
    'logout': 'Logout',
    // Settings
    'appearance': 'Appearance',
    'dark_mode': 'Dark Mode',
    'language': 'Language',
    'notif_section': 'Notifications',
    'push_notif': 'Push Notifications',
    'email_promo': 'Email Promotions',
    'security_section': 'Vehicle Key & Security',
    'biometric_unlock': 'Biometric Key Unlock',
    'auto_lock': 'Auto-lock After Trip Ends',
    'account_section': 'Account & Security',
    'change_password': 'Change Password',
    'privacy_policy': 'Privacy Policy',
    'contact_support': 'Contact Support',
    'clear_cache': 'Clear Local Active Rental Cache',
    'delete_account': 'Delete Account',
    // Pages
    'forgot_password_title': 'Forgot Password',
    'forgot_password_subtitle': 'Enter your registered email to receive a reset link.',
    'send_reset_link': 'Send Reset Link',
    'back_to_login': 'Back to Login',
    'privacy_policy_title': 'Privacy Policy',
    'contact_support_title': 'Contact Support',
    'support_phone': '+962790550787',
    // Vehicle categories (filter chips on map)
    'cat_all': 'All',
    'cat_economy': 'Economy',
    'cat_luxury': 'Luxury',
    'cat_suv': 'SUV',
    'cat_electric': 'Electric',
    // Inspection page
    'inspection_title': 'Car Inspection',
    'inspection_before': 'Before Rental',
    'inspection_after': 'After Return',
    'inspection_front_left': 'Front Left',
    'inspection_front_right': 'Front Right',
    'inspection_rear_left': 'Rear Left',
    'inspection_rear_right': 'Rear Right',
    'inspection_note': 'Notes / Comments',
    'inspection_confirm': 'Confirm & Continue',
    'inspection_subtitle': 'Please document any existing damage before driving.',
    'inspection_subtitle_before': 'Please document any existing damage before driving.',
    'inspection_subtitle_after': 'Please capture the vehicle condition after your trip — note any new damage or issues from your drive.',
    // Return zone (geofence check before ending trip)
    'return_zone_title': 'Return Zone',
    'return_zone_msg': 'Please park the car inside Amman city as shown on the map before ending your trip.',
    'return_zone_inside': 'You are inside the return zone',
    'return_zone_outside': 'You appear to be outside Amman',
    'return_zone_confirm': 'Confirm Parking Location',
    'return_zone_cancel': 'Cancel — I\'m not parked yet',
    'amman_city': 'Amman',
    // Booking duration picker
    'duration_days': 'Days',
    'duration_hours': 'Hours',
    'duration_minutes': 'Minutes',
    'duration_summary': 'Duration',
    // Cleanliness rating slider (post-trip inspection)
    'cleanliness_rating': 'Cleanliness Rating',
    'cleanliness_subtitle': 'Rate the vehicle cleanliness out of 10.',
    // End trip
    'end_trip': 'End Trip',
    'end_trip_confirm': 'Are you sure you want to end this trip?',
    'yes_end_it': 'Yes, end it',
    // Common
    'save': 'Save',
    'cancel': 'Cancel',
    'ok': 'OK',
    'retry': 'Retry',
    'loading': 'Loading...',
    'error': 'Error',
  };

  // ── Arabic strings ─────────────────────────────────────────────────────────
  static const Map<String, String> _ar = {
    // Auth
    'welcome_back': 'مرحباً بعودتك',
    'login_subtitle': 'سجّل دخولك للمتابعة',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'confirm_password': 'تأكيد كلمة المرور',
    'login': 'تسجيل الدخول',
    'logging_in': 'جارٍ تسجيل الدخول...',
    'continue_guest': 'المتابعة كضيف',
    'no_account': 'ليس لديك حساب؟',
    'register_now': 'سجّل الآن',
    'forgot_password': 'نسيت كلمة المرور؟',
    // Register
    'create_account': 'إنشاء حساب جديد',
    'full_name': 'الاسم الكامل',
    'phone': 'رقم الهاتف',
    'id_number': 'رقم الهوية',
    'license_number': 'رقم رخصة القيادة',
    'sign_up': 'إنشاء حساب والتحقق',
    // Navigation / Drawer
    'map': 'الخريطة',
    'reservations': 'حجوزاتي',
    'your_key': 'مفتاحك',
    'wallet': 'المحفظة',
    'notifications': 'الإشعارات',
    'settings': 'الإعدادات',
    'admin_dashboard': 'لوحة الإدارة',
    'logout': 'تسجيل الخروج',
    // Settings
    'appearance': 'المظهر',
    'dark_mode': 'الوضع المظلم',
    'language': 'اللغة',
    'notif_section': 'الإشعارات',
    'push_notif': 'إشعارات الدفع',
    'email_promo': 'العروض عبر البريد',
    'security_section': 'مفتاح السيارة والأمان',
    'biometric_unlock': 'فتح القفل ببصمة الإصبع',
    'auto_lock': 'القفل التلقائي بعد انتهاء الرحلة',
    'account_section': 'الحساب والأمان',
    'change_password': 'تغيير كلمة المرور',
    'privacy_policy': 'سياسة الخصوصية',
    'contact_support': 'التواصل مع الدعم',
    'clear_cache': 'مسح ذاكرة التخزين المحلية',
    'delete_account': 'حذف الحساب',
    // Pages
    'forgot_password_title': 'نسيت كلمة المرور',
    'forgot_password_subtitle': 'أدخل بريدك الإلكتروني المسجّل لاستلام رابط إعادة التعيين.',
    'send_reset_link': 'إرسال رابط إعادة التعيين',
    'back_to_login': 'العودة لتسجيل الدخول',
    'privacy_policy_title': 'سياسة الخصوصية',
    'contact_support_title': 'التواصل مع الدعم',
    'support_phone': '‎+962790550787',
    // Vehicle categories
    'cat_all': 'الكل',
    'cat_economy': 'اقتصادي',
    'cat_luxury': 'فاخر',
    'cat_suv': 'دفع رباعي',
    'cat_electric': 'كهربائي',
    // Inspection
    'inspection_title': 'فحص السيارة',
    'inspection_before': 'قبل الإيجار',
    'inspection_after': 'بعد الإعادة',
    'inspection_front_left': 'الأمام الأيسر',
    'inspection_front_right': 'الأمام الأيمن',
    'inspection_rear_left': 'الخلف الأيسر',
    'inspection_rear_right': 'الخلف الأيمن',
    'inspection_note': 'ملاحظات / تعليقات',
    'inspection_confirm': 'تأكيد والمتابعة',
    'inspection_subtitle': 'يرجى توثيق أي أضرار موجودة قبل القيادة.',
    // Booking duration
    'duration_days': 'أيام',
    'duration_hours': 'ساعات',
    'duration_minutes': 'دقائق',
    'duration_summary': 'المدة',
    // Cleanliness slider
    'cleanliness_rating': 'تقييم النظافة',
    'cleanliness_subtitle': 'قيّم نظافة السيارة من 10.',
    // End trip
    'end_trip': 'إنهاء الرحلة',
    'end_trip_confirm': 'هل أنت متأكد من إنهاء هذه الرحلة؟',
    'yes_end_it': 'نعم، أنهِها',
    // Common
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'ok': 'حسناً',
    'retry': 'إعادة المحاولة',
    'loading': 'جارٍ التحميل...',
    'error': 'خطأ',
  };

  String t(String key) {
    final map = locale.languageCode == 'ar' ? _ar : _en;
    return map[key] ?? _en[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
