// ignore_for_file: use_super_parameters

import 'package:tahlil_front/enums/month.dart';

class Statistics {}

class DoctorImagingCenterStatistics extends Statistics {
  final Map<int, int> groupedRating;
  final double avgRating;
  final Map<int, int> groupedAppointmentsThisYearByMonth,
      groupedAppointmentsByYear,
      groupedAppointmentsThisMonth;

  DoctorImagingCenterStatistics({
    required this.groupedRating,
    required this.avgRating,
    required this.groupedAppointmentsThisYearByMonth,
    required this.groupedAppointmentsByYear,
    required this.groupedAppointmentsThisMonth,
  });

  DoctorImagingCenterStatistics.fromJson(json)
      : this(
          groupedRating: {
            ...Map.fromEntries(List.generate(5, (i) => MapEntry(i, 0))),
            ...(json['grouped_ratings'] as List)
                .asMap()
                .map((_, e) => MapEntry(e['rating']!, int.parse(e['count']))),
          },
          avgRating: double.parse(json['avg_rating']),
          groupedAppointmentsThisYearByMonth: {
            ...Map.fromEntries(
              List.generate(Month.values.length, (i) => MapEntry(i + 1, 0)),
            ),
            ...(json['grouped_appointments_this_year'] as List?)?.asMap().map(
                      (_, e) => MapEntry(
                          int.parse(e['month']!), int.parse(e['count']!)),
                    ) ??
                {}
          },
          groupedAppointmentsThisMonth: {
            ...Map.fromEntries(
              List.generate(
                Month.values[DateTime.now().month-1].daysInMonth,
                (i) => MapEntry(i + 1, 0),
              ),
            ),
            ...(json['grouped_appointments_this_month'] as List?)?.asMap().map(
                      (_, e) => MapEntry(
                          int.parse(e['day']!), int.parse(e['count']!)),
                    ) ??
                {}
          },
          groupedAppointmentsByYear:
              (json['grouped_appointments_by_year'] as List?)?.asMap().map(
                        (_, e) => MapEntry(
                            int.parse(e['year']!), int.parse(e['count']!)),
                      ) ??
                  {},
        );
}

class ReferrerStatistics extends Statistics {
  final Map<String, int> refereePercentages;

  ReferrerStatistics({required this.refereePercentages});

  ReferrerStatistics.fromJson(json)
      : this(
          refereePercentages: {
            'verified': 0,
            'declined': 0,
            'waiting': 0,
            ...(json['referee_percentages'] as List)
                .asMap()
                .map((_, e) => MapEntry(e['status']!, int.parse(e['count']!))),
          },
        );
}

class ImagingCenterStatistics extends DoctorImagingCenterStatistics {
  ImagingCenterStatistics({
    required super.groupedRating,
    required super.avgRating,
    required super.groupedAppointmentsThisYearByMonth,
    required super.groupedAppointmentsByYear,
    required super.groupedAppointmentsThisMonth,
  });

  ImagingCenterStatistics.fromJson(json) : super.fromJson(json);
}

class DoctorStatistics extends DoctorImagingCenterStatistics {
  final Map<int, int> groupedPatientsByAge;
  final Map<int, int> groupedRepeatCount;

  DoctorStatistics({
    required super.groupedRating,
    required super.avgRating,
    required super.groupedAppointmentsThisYearByMonth,
    required super.groupedAppointmentsByYear,
    required super.groupedAppointmentsThisMonth,
    required this.groupedPatientsByAge,
    required this.groupedRepeatCount,
  });

  DoctorStatistics.fromJson(json)
      : groupedPatientsByAge =
            (json['grouped_patients_by_age'] as List).asMap().map(
                  (_, e) =>
                      MapEntry(int.parse(e['age']!), int.parse(e['count']!)),
                ),
        groupedRepeatCount = (json['grouped_repeat_count'] as List).asMap().map(
              (_, e) => MapEntry(
                int.parse(e['repeat_count']!),
                int.parse(e['count']!),
              ),
            ),
        super.fromJson(json);
}
