import 'dart:convert';

import 'package:tahlil_front/classes/imaging_center.dart';
import 'package:tahlil_front/classes/time.dart';
import 'package:tahlil_front/classes/work_time.dart';
import 'package:tahlil_front/services/network.dart';

class ImagingCenterService {
  static ImagingCenterService? _instance;

  static ImagingCenterService get instance {
    _instance ??= ImagingCenterService();
    return _instance!;
  }

  final NetworkService _networkService = NetworkService.instance;

  Future<ImagingCenter?> getImagingCenterInfo(String id) async {
    final response = await _networkService.get('/imaging-center/$id');
    if (response.isOk) {
      return ImagingCenter.fromJson(jsonDecode(response.bodyString!));
    }
    return null;
  }

  Future<List<WorkTime>> getWorkTimes(String id) async {
    final response =
        await _networkService.get('/imaging-center/$id/working-hours');
    if (response.isOk) {
      return (jsonDecode(response.bodyString!) as List)
          .map(WorkTime.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<Time>> filledTimesSinceToday(String id) async {
    final response =
        await _networkService.get('/imaging-center/$id/filled-times');
    if (response.isOk) {
      return (jsonDecode(response.bodyString!) as List)
          .map(Time.fromJson)
          .where((t) => t.dateTime.isAfter(DateTime.now()))
          .toList();
    }
    return [];
  }
}
