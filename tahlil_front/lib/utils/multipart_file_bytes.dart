import 'package:get/get.dart';

class MultipartFileBytes extends MultipartFile {
  MultipartFileBytes(
    super._bytes, {
    required super.filename,
    super.contentType = 'application/octet-stream',
  });
}
