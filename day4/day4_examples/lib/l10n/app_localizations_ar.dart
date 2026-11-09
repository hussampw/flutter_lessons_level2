// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ورشة Flutter — اليوم الرابع';

  @override
  String hello(String name) {
    return 'أهلاً $name!';
  }

  @override
  String cartItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منتج',
      many: '$count منتجاً',
      few: '$count منتجات',
      two: 'منتجان',
      one: 'منتج واحد',
      zero: 'السلة فارغة',
    );
    return '$_temp0';
  }

  @override
  String welcomeBack(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'أهلاً بعودتك',
      'female': 'أهلاً بعودتكِ',
      'other': 'أهلاً بعودتك',
    });
    return '$_temp0';
  }

  @override
  String total(double amount) {
    final intl.NumberFormat amountNumberFormat = intl.NumberFormat.currency(
      locale: localeName,
      name: 'SAR',
      decimalDigits: 2,
    );
    final String amountString = amountNumberFormat.format(amount);

    return 'الإجمالي: $amountString';
  }

  @override
  String today(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return 'اليوم $dateString';
  }

  @override
  String addToCart(String product) {
    return 'أضف $product إلى السلة';
  }
}
