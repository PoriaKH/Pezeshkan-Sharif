import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tahlil_front/classes/doctor.dart';
import 'package:tahlil_front/classes/imaging_center.dart';
import 'package:tahlil_front/classes/patient.dart';
import 'package:tahlil_front/classes/referrer.dart';
import 'package:tahlil_front/classes/statistics.dart';
import 'package:tahlil_front/classes/user.dart';
import 'package:tahlil_front/enums/weekday.dart';
import 'package:tahlil_front/services/network.dart';
import 'package:tahlil_front/utils/multipart_file_bytes.dart';
import 'package:tahlil_front/utils/pair.dart';

class ProfileService {
  static ProfileService? _instance;

  static ProfileService get instance {
    _instance ??= ProfileService();
    return _instance!;
  }

  final NetworkService _networkService = NetworkService.instance;

  User? profileCached;

  Future<User?> get profile async {
    if (profileCached == null) {
      final response = await _networkService.get('/profile');
      if (response.isOk) {
        final body = jsonDecode(response.bodyString!);
        switch (body['user_type']) {
          case 'patient':
            profileCached = Patient.fromJson(body);
            break;
          case 'doctor':
            profileCached = Doctor.fromJson(body);
            break;
          case 'referrer':
            profileCached = Referrer.fromJson(body);
            break;
          case 'imaging_center':
            profileCached = ImagingCenter.fromJson(body);
            break;
        }
      }
    }
    return profileCached;
  }

  Future<Pair<bool, String>> editProfile(Map<String, String?> map) async {
    if (map['birth_date'] != null) {
      final birthDate = DateFormat('yyyy-MM-dd').tryParse(map['birth_date']!);

      if (birthDate == null) {
        return Pair(
          false,
          'Birth date should have "yyyy-MM-dd" format. (e.g. 2005-10-15)',
        );
      }
      final age = DateTime.now().difference(birthDate).inDays ~/ 365;
      if (age < 0) return Pair(false, 'Invalid Birth date!');
      if (age > 18) return Pair(false, 'You must be less than 18y/o.');
    }

    final response = await _networkService.put('/profile', map);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.bodyString!);
      switch (body['user_type']) {
        case 'patient':
          profileCached = Patient.fromJson(body);
          break;
        case 'doctor':
          profileCached = Doctor.fromJson(body);
          break;
        case 'referrer':
          profileCached = Referrer.fromJson(body);
          break;
        case 'imaging_center':
          profileCached = ImagingCenter.fromJson(body);
          break;
      }
      return Pair(true, 'Profile Edited successfully!');
    }
    return Pair(false, response.body ?? '');
  }

  Future<bool> editWorkTimes(Map<Weekday, String> workTimes) async {
    final path =
        '/${profileCached?.userType}'.replaceAll(' ', '-').toLowerCase();
    final response = await _networkService.put(
      '$path/work-hours',
      workTimes.map((k, v) => MapEntry('$k', v)),
    );
    if (response.isOk) {
      profileCached = null;
      await profile;
    }
    return response.isOk;
  }

  Future<Pair<bool, String>> uploadProfilePicture(
      String path, Uint8List bytes) async {
    final response = await _networkService.post(
      '/pfp',
      FormData({'pfp': MultipartFileBytes(bytes, filename: path)}),
    );
    if (response.isOk) {
      profileCached = null;
      await profile;
    }
    return Pair(response.isOk, response.body);
  }

  Future<Pair<bool, String>> deleteProfilePicture() async {
    final response = await _networkService.delete('/pfp');
    if (response.isOk) {
      profileCached = null;
      await profile;
    }
    return Pair(response.isOk, response.body ?? '');
  }

  Future<Statistics?> getStatistics({String? userType, String? id}) async {
    final response = await (userType == null
        ? _networkService.get('/stats')
        : _networkService.get('/stats/$userType/$id'));
    if (!response.isOk) return null;
    final body = jsonDecode(response.bodyString ?? '{}');
    final type = userType ?? '${profileCached?.userType.name}';
    switch (type) {
      case 'imaging_center':
        return ImagingCenterStatistics.fromJson(body);
      case 'doctor':
        return DoctorStatistics.fromJson(body);
      case 'referrer':
        return ReferrerStatistics.fromJson(body);
      default:
        throw ArgumentError(type);
    }
  }
}
