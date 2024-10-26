import 'package:tahlil_front/enums/user_type.dart';

class User {
  final String ssid;
  final String firstName;
  final String lastName;
  final String password;
  final String? referrerSsid;
  final String? referrerName;
  final String? phoneNumber;
  final String? emailAddress;
  final String? province;
  final String? city;
  final String? street;
  final bool isVerified, isDeclined;
  final String? pfp;

  User({
    required this.ssid,
    required this.firstName,
    required this.lastName,
    required this.password,
    this.referrerSsid,
    this.referrerName,
    this.phoneNumber,
    this.emailAddress,
    this.province,
    this.city,
    this.street,
    this.pfp,
    required this.isVerified,
    required this.isDeclined,
  });

  bool get isDoctor => false;

  bool get isPatient => false;

  bool get isReferrer => false;

  bool get isImagingCenter => false;

  UserType get userType => isDoctor
      ? UserType.doctor
      : isPatient
          ? UserType.patient
          : isReferrer
              ? UserType.referrer
              : UserType.imaging_center;

  bool get isIncomplete => [
        phoneNumber,
        emailAddress,
        province,
        city,
        street,
        pfp,
      ].any((e) => e == null);

  String get fullName => '$firstName $lastName';
}
