import 'dart:convert';

import 'package:tahlil_front/classes/doctor.dart';
import 'package:tahlil_front/classes/time.dart';
import 'package:tahlil_front/classes/work_time.dart';
import 'package:tahlil_front/services/network.dart';

class DoctorService {
  static DoctorService? _instance;

  static DoctorService get instance {
    _instance ??= DoctorService();
    return _instance!;
  }

  final NetworkService _networkService = NetworkService.instance;

  Future<Doctor?> getDoctorInfo(String ssid) async {
    final response = await _networkService.get('/doctor/$ssid');
    if (response.isOk) return Doctor.fromJson(jsonDecode(response.bodyString!));
    return null;
  }

  Future<List<WorkTime>> getWorkTimes(String ssid) async {
    final response = await _networkService.get('/doctor/$ssid/working-hours');
    if (response.isOk) {
      return (jsonDecode(response.bodyString!) as List)
          .map(WorkTime.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<Time>> filledTimesSinceToday(String ssid) async {
    final response = await _networkService.get('/doctor/$ssid/filled-times');
    if (response.isOk) {
      return (jsonDecode(response.bodyString!) as List)
          .map(Time.fromJson)
          .where((t) => t.dateTime.isAfter(DateTime.now()))
          .toList();
    }
    return [];
  }
}
