import 'dart:convert';

import 'package:file_picker/src/platform_file.dart';
import 'package:get/get.dart';
import 'package:tahlil_front/classes/appointment.dart';
import 'package:tahlil_front/classes/doctor.dart';
import 'package:tahlil_front/classes/imaging_center.dart';
import 'package:tahlil_front/classes/service.dart';
import 'package:tahlil_front/services/network.dart';
import 'package:tahlil_front/utils/multipart_file_bytes.dart';
import 'package:tahlil_front/utils/pair.dart';

class AppointmentService {
  static AppointmentService? _instance;

  static AppointmentService get instance {
    _instance ??= AppointmentService();
    return _instance!;
  }

  final NetworkService _networkService = NetworkService.instance;

  List<Service>? servicesCached;

  Future<List<Doctor>> allDoctors({String? search}) async {
    final response = await _networkService
        .get('/doctors', query: {if (search != null) 'search': search});

    return (jsonDecode(response.bodyString!) as List)
        .map(Doctor.fromJson)
        .toList();
  }

  Future<List<ImagingCenter>> allImagingCenters({String? search}) async {
    final response = await _networkService
        .get('/imaging-centers', query: {if (search != null) 'search': search});

    return (jsonDecode(response.bodyString!) as List)
        .map(ImagingCenter.fromJson)
        .toList();
  }

  Future<List<Appointment>> getAppointments({String? patient}) async {
    final response = await _networkService.get(
      '/appointments',
      query: {if (patient != null) 'patient': patient},
    );

    final result = (jsonDecode(response.bodyString!) as List).map((json) {
      if (json['doctor'] != null) {
        return DoctorAppointment.fromJson(json);
      } else {
        return ImagingCenterAppointment.fromJson(json);
      }
    }).toList();
    result.sort((a1, a2) => a1.time.dateTime.compareTo(a2.time.dateTime));
    return result;
  }

  Future<Pair<bool, String>> createAppointment(
    DateTime time, {
    String? doctor,
    String? imagingCenter,
  }) async {
    final response = await _networkService.post('/appointment', {
      if (doctor != null) 'doctor': doctor,
      if (imagingCenter != null) 'imaging_center': imagingCenter,
      'year': time.year,
      'month': time.month,
      'day': time.day,
      'hour': time.hour,
    });
    return Pair(response.isOk, response.bodyString ?? '-');
  }

  Future<Appointment?> getAppointment(int id) async {
    final response = await _networkService.get('/appointment/$id');
    if (response.isOk) {
      final body = jsonDecode(response.bodyString!);
      switch (body['type']) {
        case 'doctor':
          return DoctorAppointment.fromJson(body);
        case 'imaging_center':
          return ImagingCenterAppointment.fromJson(body);
        default:
          throw ArgumentError(body['type']);
      }
    }
    return null;
  }

  Future<Pair<bool, String>> uploadImages({
    required int appointment,
    required List<PlatformFile> files,
  }) async {
    final response = await _networkService.post(
      '/appointment/$appointment/images',
      FormData({
        'images': files
            .map((f) => MultipartFileBytes(f.bytes!, filename: f.name))
            .toList()
      }),
    );
    return Pair(response.isOk, response.body);
  }

  Future<List<String>> getAppointmentImages(int appointment) async {
    final response =
        await _networkService.get('/appointment/$appointment/images');
    return (jsonDecode(response.bodyString ?? '[]') as List).cast<String>();
  }

  Future<Pair<bool, String>> deleteImage(
      {required int appointment, required String image}) async {
    final response = await _networkService
        .delete('/appointment/$appointment/images/${image.split('/').last}');
    return Pair(
      response.isOk,
      response.isOk ? 'Image deleted successfully!' : response.bodyString ?? '',
    );
  }

  Future<bool> rate(Appointment appointment, double rating) async {
    final response = await _networkService.put(
      '/appointment/${appointment.id}',
      {'rating': rating},
    );
    return response.isOk;
  }

  Future<Pair<bool, String>> updateServices(
    int appointment,
    List<String> services,
  ) async {
    final response = await _networkService.put(
      '/appointment/$appointment',
      {'services': services},
    );
    return Pair(response.isOk, response.bodyString!);
  }

  Future<List<Service>> getServices() async {
    if (servicesCached == null) {
      final response = await _networkService.get('/services');
      servicesCached = (jsonDecode(response.bodyString!) as List)
          .map(Service.fromJson)
          .toList();
    }
    return servicesCached!;
  }

  Future<Service> getService(String code) async {
    final response = await _networkService.get('/service/$code');
    return Service.fromJson(jsonDecode(response.bodyString!));
  }
}
