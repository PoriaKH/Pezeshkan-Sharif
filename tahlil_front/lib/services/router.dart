import 'package:go_router/go_router.dart';
import 'package:tahlil_front/main.dart';

class RouterService {
  static void go(String location, {Object? extra}) =>
      GoRouter.of(shellNavigatorKey.currentContext!).go(location, extra: extra);

  static void pop() => GoRouter.of(shellNavigatorKey.currentContext!).pop();
}
