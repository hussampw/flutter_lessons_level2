// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Workshop — Day 4';

  @override
  String hello(String name) {
    return 'Hello $name!';
  }

  @override
  String cartItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: 'One item',
      zero: 'Your cart is empty',
    );
    return '$_temp0';
  }

  @override
  String welcomeBack(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Welcome back, sir',
      'female': 'Welcome back, madam',
      'other': 'Welcome back',
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

    return 'Total: $amountString';
  }

  @override
  String today(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return 'Today is $dateString';
  }

  @override
  String addToCart(String product) {
    return 'Add $product to cart';
  }
}
