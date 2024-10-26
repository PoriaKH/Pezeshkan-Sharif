import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tahlil_front/enums/toast_type.dart';
import 'package:tahlil_front/enums/user_type.dart';
import 'package:tahlil_front/extensions/string_ext.dart';
import 'package:tahlil_front/main.dart';
import 'package:tahlil_front/services/auth.dart';
import 'package:tahlil_front/services/router.dart';
import 'package:tahlil_front/utils/pair.dart';
import 'package:tahlil_front/widgets/text_field.dart';
import 'package:tahlil_front/widgets/toast.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _authService = AuthService.instance;

  bool _isLogin = true, _passwordShown = false;
  UserType _userType = UserType.referrer;
  final _ssidController = TextEditingController();
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _referrerController = TextEditingController();
  final _medicalIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2)],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: SizedBox(
              width: _isLogin ? 350 : 475,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          _isLogin ? 'Login' : 'Register',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<UserType>(
                    segments: (_isLogin
                            ? [UserType.referrer, UserType.imaging_center]
                            : UserType.values)
                        .map((ut) => ButtonSegment(
                              value: ut,
                              label: FittedBox(
                                child: Text(
                                  _isLogin && ut == UserType.referrer
                                      ? 'User'
                                      : '$ut',
                                ),
                              ),
                            ))
                        .toList(),
                    showSelectedIcon: false,
                    selected: <UserType>{_userType},
                    onSelectionChanged: (newUserType) =>
                        setState(() => _userType = newUserType.last),
                  ),
                  const SizedBox(height: 10),
                  if (_userType == UserType.imaging_center)
                    CustomTextField(
                      icon: const FaIcon(FontAwesomeIcons.idCard),
                      label: 'Name',
                      required: true,
                      controller: _nameController,
                    )
                  else
                    CustomTextField(
                      icon: const FaIcon(FontAwesomeIcons.idCard),
                      label: 'SSID',
                      required: true,
                      controller: _ssidController,
                    ),
                  if (!_isLogin && _userType != UserType.imaging_center) ...[
                    CustomTextField(
                      icon: const Icon(Icons.abc),
                      label: 'First Name',
                      required: true,
                      controller: _firstNameController,
                    ),
                    CustomTextField(
                      icon: const Icon(Icons.abc),
                      label: 'Last Name',
                      required: true,
                      controller: _lastNameController,
                    ),
                  ],
                  CustomTextField(
                    icon: const Icon(Icons.password),
                    label: 'Password',
                    required: true,
                    controller: _passwordController,
                    obscureText: !_passwordShown,
                    toggleObscureText: () =>
                        setState(() => _passwordShown = !_passwordShown),
                    helperText: 'At least 8 characters',
                  ),
                  if (!_isLogin) ...[
                    CustomTextField(
                      icon: const Icon(Icons.password),
                      label: 'Repeat Password',
                      required: true,
                      controller: _repeatPasswordController,
                      obscureText: !_passwordShown,
                      toggleObscureText: () =>
                          setState(() => _passwordShown = !_passwordShown),
                    ),
                    if (_userType != UserType.referrer)
                      CustomTextField(
                        icon: const Icon(Icons.verified_user),
                        label: 'Referrer',
                        required: true,
                        controller: _referrerController,
                      ),
                    if (_userType == UserType.doctor)
                      CustomTextField(
                        icon: const Icon(Icons.medical_information),
                        label: 'Medical ID',
                        required: true,
                        controller: _medicalIdController,
                        hint: 'e.g. 12345',
                      )
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _isLogin
                            ? 'Don\'t have an account?'
                            : 'Already have an account?',
                      ),
                      const SizedBox(width: 5),
                      TextButton(
                        onPressed: () => setState(() {
                          if (_userType != UserType.imaging_center) {
                            _userType = UserType.referrer;
                          }
                          _isLogin = !_isLogin;
                        }),
                        child: Text(_isLogin ? 'Register Here!' : 'Login Here!'),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  FilledButton(
                    onPressed: _isLogin ? _login : _register,
                    child: Text(_isLogin ? 'Login' : 'Register'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() async => _postSubmit(
        await _authService.login(
          ssid: _userType == UserType.referrer ? _ssidController.text : null,
          name: _userType != UserType.referrer ? _nameController.text : null,
          password: _passwordController.text,
        ),
      );

  Future<void> _register() async => _postSubmit(
        await _authService.register(
          ssid: _ssidController.text.nullIfEmpty,
          name: _nameController.text.nullIfEmpty,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          password: _passwordController.text,
          repeatPassword: _repeatPasswordController.text,
          referrer: _referrerController.text,
          userType: _userType,
          medicalId: _medicalIdController.text,
        ),
      );

  void _postSubmit(Pair<bool, String> response) {
    final toast = FToast();
    toast.init(rootNavigatorKey.currentContext!);
    toast.showToast(
      child: CustomToast(
        text: response.second,
        toastType: response.first ? ToastType.success : ToastType.error,
      ),
      gravity: ToastGravity.BOTTOM_LEFT,
    );
    if (response.first) RouterService.go('/');
  }
}
