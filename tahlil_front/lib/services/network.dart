import 'package:get/get.dart';

class NetworkService extends GetConnect {
  static NetworkService get instance {
    Get.put(NetworkService());
    return Get.find<NetworkService>();
  }

  @override
  void onInit() {
    withCredentials = true;
    maxAuthRetries = 3;
    timeout = const Duration(seconds: 15);
  }

  String _buildUrl(String path, Map<String, dynamic>? query) {
    const scheme = String.fromEnvironment('base_scheme');
    const url = String.fromEnvironment('base_url');
    return Uri(
      scheme: scheme,
      host: url,
      port: scheme == 'http' ? 80 : 443,
      path: path.substring(1),
      queryParameters: query,
    ).toString();
  }

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    Response<T> response = await super.get(
      _buildUrl(url, query),
      headers: headers,
      contentType: contentType,
      decoder: decoder,
    );
    if (response.statusCode == 401 &&
        !url.contains('login') &&
        !url.contains('register') &&
        !url.contains('refresh') &&
        !url.contains('is_logged_in')) {
      for (int i = 0; i < maxAuthRetries; i++) {
        if ((await post('/auth/refresh', {})).statusCode == 200) break;
      }
      response = await super.get(
        _buildUrl(url, query),
        headers: headers,
        contentType: contentType,
        decoder: decoder,
      );
    }
    return response;
  }

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    Response<T> response = await super.post(
      _buildUrl(url!, query),
      body,
      contentType: contentType,
      headers: headers,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );
    if (response.statusCode == 401 &&
        !url.contains('login') &&
        !url.contains('register') &&
        !url.contains('refresh') &&
        !url.contains('is_logged_in')) {
      for (int i = 0; i < maxAuthRetries; i++) {
        if ((await super.post('/auth/refresh', {})).isOk) break;
      }
      response = await super.post(
        _buildUrl(url, query),
        body,
        contentType: contentType,
        headers: headers,
        decoder: decoder,
        uploadProgress: uploadProgress,
      );
    }
    return response;
  }

  @override
  Future<Response<T>> put<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    Response<T> response = await super.put(
      _buildUrl(url, query),
      body,
      contentType: contentType,
      headers: headers,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );
    if (response.statusCode == 401) {
      for (int i = 0; i < maxAuthRetries; i++) {
        if ((await super.post('/auth/refresh', {})).statusCode == 200) break;
      }
      response = await super.put(
        _buildUrl(url, query),
        body,
        contentType: contentType,
        headers: headers,
        decoder: decoder,
        uploadProgress: uploadProgress,
      );
    }
    return response;
  }

  @override
  Future<Response<T>> delete<T>(
    String url, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    Response<T> response = await super.delete(
      _buildUrl(url, query),
      contentType: contentType,
      headers: headers,
      decoder: decoder,
    );
    if (response.statusCode == 401) {
      for (int i = 0; i < maxAuthRetries; i++) {
        if ((await super.post('/auth/refresh', {})).statusCode == 200) break;
      }
      response = await super.delete(
        _buildUrl(url, query),
        contentType: contentType,
        headers: headers,
        decoder: decoder,
      );
    }
    return response;
  }
}
