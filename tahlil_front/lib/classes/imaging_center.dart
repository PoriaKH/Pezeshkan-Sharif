import 'package:tahlil_front/classes/user.dart';
import 'package:tahlil_front/classes/work_time.dart';
import 'package:tahlil_front/enums/weekday.dart';

class ImagingCenter extends User {
  final int id;
  final String name;
  final List<WorkTime> workTimes;

  ImagingCenter({
    required this.id,
    required this.name,
    super.referrerSsid,
    super.firstName = '',
    super.lastName = '',
    super.ssid = '',
    required super.password,
    super.phoneNumber,
    super.emailAddress,
    super.province,
    super.city,
    super.street,
    required super.isVerified,
    required super.isDeclined,
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

  ImagingCenter.fromJson(dynamic json)
      : this(
          id: json['id'],
          name: json['name'],
          password: json['password'],
          phoneNumber: json['phone_number'],
          emailAddress: json['email_address'],
          province: json['province'],
          city: json['city'],
          street: json['street'],
          referrerSsid: json['referrer'],
          isVerified: json['is_verified'],
          isDeclined: json['is_declined'],
          workTimes: json['work_times'],
        );

  @override
  bool get isImagingCenter => true;
}
