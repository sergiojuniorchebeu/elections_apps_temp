import 'package:intl/intl.dart';
import '../../l10n/strings.dart';

/// Every date / number shown on screen goes through here, so changing
/// the locale changes all formats at once.
abstract final class Formats {
  static String get _locale => Intl.getCurrentLocale();

  /// 14 mai 1994
  static String date(DateTime d) => DateFormat('d MMM y', _locale).format(d);

  /// NOV (French abbreviations end with a dot: « nov. » -> NOV)
  static String monthShort(DateTime d) => DateFormat('MMM', _locale)
      .format(d)
      .replaceAll('.', '')
      .toUpperCase();

  /// 12
  static String day(DateTime d) => DateFormat('d', _locale).format(d);

  /// 14:05
  static String time(DateTime d) => DateFormat.Hm(_locale).format(d);

  /// mardi 12 novembre
  static String longDay(DateTime d) =>
      DateFormat('EEEE d MMMM', _locale).format(d);

  /// 8 420
  /// French groups with a narrow no-break space (U+202F) that Outfit
  /// renders almost invisibly: use a regular no-break space instead.
  static String number(num n) => NumberFormat.decimalPattern(_locale)
      .format(n)
      .replaceAll('\u202F', '\u00A0');

  /// "Aujourd’hui", "Hier", or a date: headers of grouped lists.
  static String dayHeader(DateTime d, {DateTime? now}) {
    final today = _dayOnly(now ?? DateTime.now());
    final day = _dayOnly(d);
    final diff = today.difference(day).inDays;
    if (diff == 0) return CommonStrings.today;
    if (diff == 1) return CommonStrings.yesterday;
    return date(d);
  }

  /// "Il y a 5 min", "Il y a 3 h", "Il y a 2 j" or a date.
  static String relative(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inMinutes < 1) return CommonStrings.justNow;
    if (diff.inHours < 1) return CommonStrings.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return CommonStrings.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return CommonStrings.daysAgo(diff.inDays);
    return date(d);
  }

  /// "•••• 4829"
  static String masked(String last4) => '•••• $last4';

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
