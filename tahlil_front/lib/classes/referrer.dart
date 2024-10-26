import 'package:tahlil_front/classes/user.dart';

class Referrer extends User {
  Referrer({
    required super.ssid,
    required super.firstName,
    required super.lastName,
    required super.password,
    super.phoneNumber,
    super.emailAddress,
    super.province,
    super.city,
    super.street,
    super.pfp,
    required super.isVerified,
    required super.isDeclined,
  });

  Referrer.fromJson(dynamic json)
      : this(
          ssid: json['ssid'],
          firstName: json['first_name'],
          lastName: json['last_name'],
          password: json['password'],
          phoneNumber: json['phone_number'],
          emailAddress: json['email_address'],
          province: json['province'],
          city: json['city'],
          street: json['street'],
          isVerified: json['is_verified'],
          isDeclined: json['is_declined'],
          pfp: json['pfp'],
        );

  @override
  bool get isReferrer => true;
}
