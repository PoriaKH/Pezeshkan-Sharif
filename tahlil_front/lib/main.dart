import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tahlil_front/enums/toast_type.dart';
import 'package:tahlil_front/enums/user_type.dart';
import 'package:tahlil_front/pages/appointment.dart';
import 'package:tahlil_front/pages/appointments.dart';
import 'package:tahlil_front/pages/auth.dart';
import 'package:tahlil_front/pages/create_appointment.dart';
import 'package:tahlil_front/pages/dashboard.dart';
import 'package:tahlil_front/pages/explore.dart';
import 'package:tahlil_front/pages/not_found.dart';
import 'package:tahlil_front/pages/profile.dart';
import 'package:tahlil_front/pages/services.dart';
import 'package:tahlil_front/pages/verification.dart';
import 'package:tahlil_front/services/auth.dart';
import 'package:tahlil_front/services/profile.dart';
import 'package:tahlil_front/services/router.dart';
import 'package:tahlil_front/utils/theme.dart';
import 'package:tahlil_front/widgets/toast.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

int get timestamp => DateTime.now().millisecondsSinceEpoch;

void main() {
  runApp(TahlilApp());
}

class TahlilApp extends StatelessWidget {
  static final AuthService _authService = AuthService.instance;
  static final ProfileService _profileService = ProfileService.instance;

  final ThemeData _lightTheme = generateTheme(ThemeMode.light);
  final ThemeData _darkTheme = generateTheme(ThemeMode.dark);

  final _router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    onException: (_, context, state) => RouterService.go('/not-found'),
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => Scaffold(
          backgroundColor: Theme.of(context).canvasColor,
          appBar: AppBar(
            elevation: 10,
            centerTitle: false,
            title: FutureBuilder<UserType?>(
              future: _profileService.profile.then((user) => user?.userType),
              builder: (context, snapshot) {
                return Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => RouterService.go('/'),
                        child: const Text(
                          'Pezeshkan-sharif',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 25),
                    if (snapshot.data != null) ...[
                      if (snapshot.data == UserType.patient) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: TextButton(
                            onPressed: () => RouterService.go('/doctors'),
                            child: const Text('Explore Doctors'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: TextButton(
                            onPressed: () =>
                                RouterService.go('/imaging-centers'),
                            child: const Text('Explore Imaging Centers'),
                          ),
                        )
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: TextButton(
                            onPressed: () => RouterService.go('/dashboard'),
                            child: const Text('Dashboard'),
                          ),
                        ),
                      if (snapshot.data == UserType.referrer)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: TextButton(
                            onPressed: () => RouterService.go('/verification'),
                            child: const Text('Verification'),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: TextButton(
                            onPressed: () => RouterService.go('/appointments'),
                            child: const Text('Appointments'),
                          ),
                        ),
                    ]
                  ],
                );
              },
            ),
            actions: [
              FutureBuilder<bool>(
                future: _authService.isLoggedIn(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Container();
                  if (snapshot.hasError || !snapshot.data!) {
                    return TextButton.icon(
                      onPressed: () => RouterService.go('/auth'),
                      label: const Text('Register / Login'),
                      icon: const FaIcon(FontAwesomeIcons.rightToBracket),
                    );
                  }
                  return TextButton.icon(
                    onPressed: () => RouterService.go('/profile'),
                    label: const Text('Profile'),
                    icon: const FaIcon(FontAwesomeIcons.user),
                  );
                },
              ),
            ],
          ),
          body: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            redirect: (context, state) async {
              if (state.fullPath == '/') {
                if (!(await _authService.isLoggedIn())) return '/auth';
                final profile = await _profileService.profile;
                if (profile == null) return '/auth';
                if (profile.isReferrer) return '/verification';
                return '/appointments';
              }
              return state.fullPath;
            },
          ),
          GoRoute(
            path: '/auth',
            redirect: needsNoAuthRedirect,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AuthPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            redirect: needsAuthRedirect,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
          GoRoute(
            path: '/verification',
            redirect: (context, state) async {
              if ((await needsAuthRedirect(context, state)) != state.fullPath) {
                return '/auth';
              }
              if ((await _profileService.profile)?.isReferrer ?? false) {
                return state.fullPath;
              }
              return '/not-found';
            },
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VerificationPage(),
            ),
          ),
          GoRoute(
            path: '/appointments',
            redirect: (context, state) async {
              if ((await needsAuthRedirect(context, state)) != state.fullPath) {
                return '/auth';
              }
              if ((await _profileService.profile)?.isReferrer ?? false) {
                return '/not-found';
              }
              return state.fullPath;
            },
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AppointmentsPage(),
            ),
          ),
          GoRoute(
            path: '/appointment/:id',
            redirect: (context, state) async {
              if ((await needsAuthRedirect(context, state)) != state.fullPath) {
                return '/auth';
              }
              if ((await _profileService.profile)?.isReferrer ?? false) {
                return '/not-found';
              }
              return null;
            },
            pageBuilder: (context, state) => NoTransitionPage(
              child: AppointmentPage(int.parse(state.pathParameters['id']!)),
            ),
          ),
          GoRoute(
            path: '/doctors',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExplorePage(doctors: true),
            ),
          ),
          GoRoute(
            path: '/imaging-centers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExplorePage(doctors: false),
            ),
          ),
          GoRoute(
            path: '/create-appointment',
            redirect: (context, state) async {
              final params = state.uri.queryParameters;

              if ((params['doctor'] ?? params['imaging-center']) == null) {
                return '/not-found';
              }
              if ((await needsAuthRedirect(context, state)) != state.fullPath) {
                return '/auth';
              }
              final profile = await _profileService.profile;
              if (profile!.isPatient) {
                if (profile.isIncomplete) {
                  final toast = FToast();
                  toast.init(context);
                  toast.showToast(
                    child: const CustomToast(
                      text: 'Your profile is incomplete!',
                      toastType: ToastType.warning,
                    ),
                    gravity: ToastGravity.BOTTOM_LEFT,
                  );
                  return '/profile';
                }
                return null;
              }
              return '/not-found';
            },
            pageBuilder: (context, state) {
              final params = state.uri.queryParameters;
              if (params['doctor'] != null) {
                return NoTransitionPage(
                  child: CreateAppointmentPage(
                    doctorSsid: params['doctor']!,
                  ),
                );
              }
              return NoTransitionPage(
                child: CreateAppointmentPage(
                  imagingCenterId: params['imaging-center']!,
                ),
              );
            },
          ),
          GoRoute(
            path: '/dashboard',
            redirect: needsAuthRedirect,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/services/:appointment',
            redirect: (context, state) async {
              if ((await needsAuthRedirect(context, state)) != state.fullPath) {
                return '/auth';
              }
              if (!((await _profileService.profile)?.isDoctor ?? false) ||
                  state.pathParameters['appointment'] == null) {
                return '/not-found';
              }
              return null;
            },
            pageBuilder: (context, state) => NoTransitionPage(
              child: ServicesPage(
                int.parse(state.pathParameters['appointment']!),
              ),
            ),
          ),
          GoRoute(
            path: '/not-found',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotFoundPage(),
            ),
          ),
        ],
      )
    ],
  );

  TahlilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: FToastBuilder(),
    );
  }

  static FutureOr<String?> needsAuthRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    if (await _authService.isLoggedIn()) return state.fullPath;
    return '/auth';
  }

  static FutureOr<String?> needsNoAuthRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    if (!(await _authService.isLoggedIn())) return state.fullPath;
    return '/';
  }

  static NoTransitionPage DefaultTransitionPageBuilder<T>(GoRouterState state,
      {required Widget child}) {
    return NoTransitionPage<T>(
      key: state.pageKey,
      child: child,
    );
  }
}
