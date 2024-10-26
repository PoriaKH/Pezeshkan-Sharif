import 'package:tahlil_front/enums/weekday.dart';

class WorkTime {
  final Weekday weekday;
  final int startHour, endHour;

  WorkTime({
    required this.weekday,
    required this.startHour,
    required this.endHour,
  });

  WorkTime.fromJson(json) : this (
    weekday: Weekday.find(json['weekday']),
    startHour: int.parse(json['start_hour']),
    endHour: int.parse(json['end_hour']),
  );

  @override
  String toString() {
    return '${weekday.toString().substring(0, 3)} $startHour-$endHour';
  }
}
