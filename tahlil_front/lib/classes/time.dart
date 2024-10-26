import 'package:intl/intl.dart';
import 'package:tahlil_front/enums/weekday.dart';

class Time {
  final DateTime dateTime;
  final Weekday weekday;

  int get year => dateTime.year;

  int get month => dateTime.month;

  int get day => dateTime.day;

  int get hour => dateTime.hour;

  Time({
    required this.dateTime,
    required this.weekday,
  });

  Time.fromJson(dynamic json)
      : this(
          dateTime: DateFormat('yyyy-MM-ddThh:mm:ss')
              .parse(json['date_time'], true)
              .toLocal(),
          weekday: Weekday.find(json['weekday']),
        );

  bool get isInPast =>
      !DateTime.now().isBefore(DateTime(year, month, day, hour));

  @override
  String toString() => '$weekday $year-$month-$day @$hour:00';
}
