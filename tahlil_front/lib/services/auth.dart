import 'package:tahlil_front/enums/user_type.dart';
import 'package:tahlil_front/services/network.dart';
import 'package:tahlil_front/services/profile.dart';
import 'package:tahlil_front/utils/pair.dart';

class AuthService {
  static AuthService? _instance;

  static AuthService get instance {
    _instance ??= AuthService();
    return _instance!;
  }

  final NetworkService _networkService = NetworkService.instance;
  final ProfileService _profileService = ProfileService.instance;

  Future<bool> isLoggedIn() async {
    final response = await _networkService.get('/auth/is_logged_in');
    return response.statusCode == 200;
  }

  Future<Pair<bool, String>> login({
    String? ssid,
    String? name,
    required String password,
  }) async {
    if (((ssid?.isEmpty ?? false) && (name?.isEmpty ?? false)) ||
        password.isEmpty) {
      return Pair(false, 'All fields are required!');
    }

    final response = await _networkService.post(
      '/auth/login',
      {
        if (ssid != null) 'ssid': ssid,
        if (name != null) 'name': name,
        'password': password,
      },
    );
    if (response.statusCode == 200) {
      _profileService.profileCached = null;
      await _profileService.profile;
    }
    return Pair(response.statusCode == 200, response.body ?? '');
  }

  Future<Pair<bool, String>> register({
    String? ssid,
    String? name,
    required String firstName,
    required String lastName,
    required String password,
    required String repeatPassword,
    required String referrer,
    required UserType userType,
    String medicalId = '',
  }) async {
    if (userType == UserType.imaging_center) {
      if ((name?.isEmpty ?? false) ||
          password.isEmpty ||
          repeatPassword.isEmpty ||
          referrer.isEmpty) {
        return Pair(false, 'All fields are required!');
      }
    } else {
      if ((ssid?.isEmpty ?? false) ||
          firstName.isEmpty ||
          lastName.isEmpty ||
          password.isEmpty ||
          repeatPassword.isEmpty ||
          (userType != UserType.referrer && referrer.isEmpty) ||
          (userType == UserType.doctor && medicalId.isEmpty)) {
        return Pair(false, 'All fields are required!');
      }
      if (!RegExp('^[0-9]{10}\$').hasMatch(ssid!)) {
        return Pair(false, 'SSID must be a string of 10 digits!');
      }
    }
    if (password.length < 8) {
      return Pair(false, 'Password must be at least 8 characters!');
    }
    if (password != repeatPassword) {
      return Pair(false, 'Password and Repeat Password must match!');
    }
    if (userType == UserType.imaging_center) {
      final response = await _networkService.post(
        '/imaging-center',
        {
          'name': name,
          'password': password,
          'repeat_password': repeatPassword,
          if (referrer.isNotEmpty) 'referrer': referrer,
        },
      );
      return Pair(response.statusCode == 201, response.body ?? '');
    } else {
      final response = await _networkService.post(
        '/auth/register',
        {
          'ssid': ssid,
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
          'repeat_password': repeatPassword,
          if (referrer.isNotEmpty) 'referrer': referrer,
          if (userType == UserType.doctor) 'medical_id': medicalId,
          'user_type': '$userType'.toLowerCase().replaceAll(' ', '_')
        },
      );
      return Pair(response.statusCode == 201, response.body ?? '');
    }
  }

  Future<Pair<bool, String>> logout() async {
    final response = await _networkService.delete('/auth/logout');

    if (response.statusCode == 204) {
      _profileService.profileCached = null;
    }
    return Pair(response.statusCode == 204, response.body ?? '');
  }
}
