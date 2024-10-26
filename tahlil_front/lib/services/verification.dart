import 'dart:convert';

import 'package:tahlil_front/classes/doctor.dart';
import 'package:tahlil_front/classes/imaging_center.dart';
import 'package:tahlil_front/classes/patient.dart';
import 'package:tahlil_front/classes/user.dart';
import 'package:tahlil_front/services/network.dart';

class VerificationService {
  static VerificationService? _instance;

  static VerificationService get instance {
    _instance ??= VerificationService();
    return _instance!;
  }

  final NetworkService _networkService = NetworkService.instance;

  Future<List<User>> verifyList() async {
    final response = await _networkService.get('/referees');
    return (jsonDecode(response.bodyString!) as List)
        .map((json) => json['user_type'] == 'doctor'
            ? Doctor.fromJson(json)
            : json['user_type'] == 'patient'
                ? Patient.fromJson(json)
                : ImagingCenter.fromJson(json))
        .toList();
  }

  Future<bool> decline(User user) async {
    final subpath = (user is! ImagingCenter)
        ? 'users/${user.ssid}'
        : 'imaging-centers/${user.id}';
    final response =
        await _networkService.post('/referees/$subpath/decline', {});
    return response.statusCode == 200;
  }

  Future<bool> accept(User user) async {
    final subpath = (user is! ImagingCenter)
        ? 'users/${user.ssid}'
        : 'imaging-centers/${user.id}';
    final response =
        await _networkService.post('/referees/$subpath/accept', {});
    return response.statusCode == 200;
  }
}
