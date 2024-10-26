import 'package:tahlil_front/classes/user.dart';
import 'package:tahlil_front/classes/work_time.dart';
import 'package:tahlil_front/enums/weekday.dart';

class Doctor extends User {
  final String medicalId;
  final String? specialty;
  final List<WorkTime> workTimes;

  Doctor({
    required super.ssid,
    required super.firstName,
    required super.lastName,
    required super.password,
    super.referrerSsid,
    super.referrerName,
    super.phoneNumber,
    super.emailAddress,
    super.province,
    super.city,
    super.street,
    super.pfp,
    required super.isVerified,
    required super.isDeclined,
    required this.medicalId,
    required this.specialty,
    required String? workTimes,
  }) : workTimes = workTimes
                ?.split(', ')
                .map(
                  (t) => WorkTime(
                    weekday: Weekday.find(t.split(' ')[0]),
                    startHour: int.parse(t.split(' ')[1].split('-')[0]),
                    endHour: int.parse(t.split(' ')[1].split('-')[1]),
                  ),
                )
                .toList() ??
            [];

  Doctor.fromJson(dynamic json)
      : this(
          ssid: json['ssid'],
          firstName: json['first_name'],
          lastName: json['last_name'],
          password: json['password'],
          referrerSsid: json['referrer'],
          referrerName: json['referrer.full_name'],
          phoneNumber: json['phone_number'],
          emailAddress: json['email_address'],
          province: json['province'],
          city: json['city'],
          street: json['street'],
          isVerified: json['is_verified'],
          isDeclined: json['is_declined'],
          medicalId: json['medical_id'],
          specialty: json['specialty'],
          workTimes: json['work_times'],
          pfp: json['pfp'],
        );

  @override
  bool get isDoctor => true;

  @override
  bool get isIncomplete => super.isIncomplete || specialty == null;
}
