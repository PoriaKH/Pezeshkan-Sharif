import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tahlil_front/classes/doctor.dart';
import 'package:tahlil_front/classes/imaging_center.dart';
import 'package:tahlil_front/classes/patient.dart';
import 'package:tahlil_front/classes/user.dart';
import 'package:tahlil_front/dialogs/work_hours.dart';
import 'package:tahlil_front/enums/toast_type.dart';
import 'package:tahlil_front/enums/user_type.dart';
import 'package:tahlil_front/extensions/string_ext.dart';
import 'package:tahlil_front/main.dart';
import 'package:tahlil_front/services/auth.dart';
import 'package:tahlil_front/services/profile.dart';
import 'package:tahlil_front/utils/triple.dart';
import 'package:tahlil_front/widgets/error.dart' as error;
import 'package:tahlil_front/widgets/profile_picture.dart';
import 'package:tahlil_front/widgets/text_field.dart';
import 'package:tahlil_front/widgets/toast.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService.instance;
  final _profileService = ProfileService.instance;

  bool isEditMode = false;

  final TextEditingController firstNameController = TextEditingController(),
      lastNameController = TextEditingController(),
      phoneNumberController = TextEditingController(),
      emailAddressController = TextEditingController(),
      provinceController = TextEditingController(),
      cityController = TextEditingController(),
      streetController = TextEditingController(),
      specialtyController = TextEditingController(),
      birthdateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _profileService.profile,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return error.ErrorWidget(
            msg: 'profile.',
            refresh: () => setState(() {}),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final profile = snapshot.data!;
        firstNameController.text = profile.firstName;
        lastNameController.text = profile.lastName;
        phoneNumberController.text = profile.phoneNumber ?? '';
        emailAddressController.text = profile.emailAddress ?? '';
        provinceController.text = profile.province ?? '';
        cityController.text = profile.city ?? '';
        streetController.text = profile.street ?? '';
        if (profile is Doctor) {
          specialtyController.text = profile.specialty ?? '';
        } else if (profile is Patient) {
          birthdateController.text = profile.birthDate ?? '';
        }

        return Center(
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 2),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 20, bottom: 20, left: 40, right: 20),
                    child: isEditMode
                        ? SizedBox(
                            width: 400,
                            child: ProfileEditBody(
                              profile,
                              firstNameController: firstNameController,
                              lastNameController: lastNameController,
                              phoneNumberController: phoneNumberController,
                              emailAddressController: emailAddressController,
                              provinceController: provinceController,
                              cityController: cityController,
                              streetController: streetController,
                              specialtyController: specialtyController,
                              birthdateController: birthdateController,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.fill,
                            child: ProfileViewBody(profile),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 20, bottom: 20, right: 40, left: 20),
                    child: SizedBox(
                      width: 250,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: isEditMode
                            ? [
                                if (profile.userType != UserType.imaging_center)
                                  _ProfilePictureWidget(profile),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('Save Changes'),
                                    onPressed: _editProfile,
                                    // onPressed: _editProfile,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Discard Changes'),
                                    onPressed: () =>
                                        setState(() => isEditMode = false),
                                  ),
                                ),
                              ]
                            : [
                                if (profile.userType != UserType.imaging_center)
                                  _ProfilePictureWidget(profile),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit Profile'),
                                    onPressed: () =>
                                        setState(() => isEditMode = true),
                                  ),
                                ),
                                if (profile is Doctor ||
                                    profile is ImagingCenter)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.work),
                                      label: const Text('Manage Work Hours'),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) =>
                                            WorkHoursDialog(profile),
                                      ).then((_) => setState(() {})),
                                    ),
                                  ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: TextButton.icon(
                                    icon: const FaIcon(
                                        FontAwesomeIcons.rightFromBracket),
                                    label: const Text('Logout'),
                                    onPressed: _logout,
                                  ),
                                ),
                              ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editProfile() async {
    final profile = _profileService.profileCached!;
    final response = await _profileService.editProfile({
      if (!profile.isImagingCenter)
        'first_name': firstNameController.text.nullIfEmpty,
      if (!profile.isImagingCenter)
        'last_name': lastNameController.text.nullIfEmpty,
      'phone_number': phoneNumberController.text.nullIfEmpty,
      'email_address': emailAddressController.text.nullIfEmpty,
      'province': provinceController.text.nullIfEmpty,
      'city': cityController.text.nullIfEmpty,
      'street': streetController.text.nullIfEmpty,
      if (profile.isDoctor) 'specialty': specialtyController.text.nullIfEmpty,
      if (profile.isPatient) 'birth_date': birthdateController.text.nullIfEmpty,
    });
    final toast = FToast();
    toast.init(rootNavigatorKey.currentContext!);
    toast.showToast(
      child: CustomToast(
        text: response.second,
        toastType: response.first ? ToastType.success : ToastType.error,
      ),
      gravity: ToastGravity.BOTTOM_LEFT,
    );
    if (response.first) setState(() => isEditMode = false);
  }

  Future<void> _logout() async {
    if ((await _authService.logout()).first) {
      GoRouter.of(shellNavigatorKey.currentContext!).go('/');
    }
  }

  Widget _ProfilePictureWidget(User user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30, left: 10, right: 10),
      child: Stack(
        children: [
          ProfilePictureWidget(user, editPFP: _editPFP),
          if (user.pfp != null)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  color: Theme.of(context).colorScheme.onError,
                  onPressed: _deletePFP,
                  icon: Icon(Icons.delete),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editPFP() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if ((result?.files.length ?? 0) > 0) {
      final file = result!.files.first;
      final response =
          await _profileService.uploadProfilePicture(file.name, file.bytes!);
      if (response.first) setState(() {});

      final toast = FToast();
      toast.init(rootNavigatorKey.currentContext!);
      toast.showToast(
        child: CustomToast(
          text: response.second,
          toastType: response.first ? ToastType.success : ToastType.error,
        ),
        gravity: ToastGravity.BOTTOM_LEFT,
      );
    }
  }

  Future<void> _deletePFP() async {
    final response = await _profileService.deleteProfilePicture();
    if (response.first) setState(() {});

    final toast = FToast();
    toast.init(rootNavigatorKey.currentContext!);
    toast.showToast(
      child: CustomToast(
        text: response.second,
        toastType: response.first ? ToastType.success : ToastType.error,
      ),
      gravity: ToastGravity.BOTTOM_LEFT,
    );
  }
}

class ProfileViewBody extends StatefulWidget {
  final User user;

  const ProfileViewBody(this.user, {super.key});

  @override
  State<ProfileViewBody> createState() => _ProfileViewBodyState();
}

class _ProfileViewBodyState extends State<ProfileViewBody> {
  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Triple(
          'Hello ',
          null,
          user.isImagingCenter
              ? (user as ImagingCenter).name
              : '${user.firstName} ${user.lastName}',
        ),
        Triple('You are a ', const Icon(Icons.person), user.userType),
        if (user is Doctor)
          Triple('Your Medical ID is ', const Icon(Icons.medical_information),
              user.medicalId)
        else if (user is Patient)
          Triple('You were born on ', const Icon(Icons.calendar_month),
              user.birthDate ?? '-'),
        // Triple('You were verified by ', const Icon(Icons.person),
        //     user.referrerName ?? '-'),
        Triple('Your Phone number is ', const Icon(Icons.phone),
            user.phoneNumber ?? '-'),
        Triple('Your Email Address is ', const Icon(Icons.email),
            user.emailAddress ?? '-'),
        if (user is Doctor)
          Triple('You are a ', const FaIcon(FontAwesomeIcons.userDoctor),
              user.specialty ?? '-'),
        Triple(
            'Your Address is ',
            const Icon(Icons.pin_drop),
            // ignore: prefer_interpolation_to_compose_strings
            (user.province + ', ' + user.city + ', ' + user.street) ?? '-'),
      ].map((tup) {
        final label = tup.first;
        final icon = tup.second;
        final value = tup.third;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: icon ?? Container(),
              ),
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: label, style: theme.textTheme.bodyMedium),
                  TextSpan(
                    text: '$value',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class ProfileEditBody extends StatefulWidget {
  final User user;
  final TextEditingController firstNameController,
      lastNameController,
      phoneNumberController,
      emailAddressController,
      provinceController,
      cityController,
      streetController;
  final TextEditingController? specialtyController, birthdateController;

  const ProfileEditBody(
    this.user, {
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneNumberController,
    required this.emailAddressController,
    required this.provinceController,
    required this.cityController,
    required this.streetController,
    this.specialtyController,
    this.birthdateController,
  });

  @override
  State<ProfileEditBody> createState() => _ProfileEditBodyState();
}

class _ProfileEditBodyState extends State<ProfileEditBody> {
  late final TextEditingController _firstNameController,
      _lastNameController,
      _phoneNumberController,
      _emailAddressController,
      _provinceController,
      _cityController,
      _streetController;
  late final TextEditingController? _specialtyController, _birthdateController;

  @override
  void initState() {
    super.initState();
    _firstNameController = widget.firstNameController;
    _lastNameController = widget.lastNameController;
    _phoneNumberController = widget.phoneNumberController;
    _emailAddressController = widget.emailAddressController;
    _provinceController = widget.provinceController;
    _cityController = widget.cityController;
    _streetController = widget.streetController;
    _specialtyController = widget.specialtyController;
    _birthdateController = widget.birthdateController;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!user.isImagingCenter) ...[
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
          icon: const Icon(Icons.phone),
          label: 'Phone Number',
          required: true,
          controller: _phoneNumberController,
        ),
        CustomTextField(
          icon: const Icon(Icons.email),
          label: 'Email Address',
          required: true,
          hint: 'e.g. abc@email.com',
          controller: _emailAddressController,
        ),
        if (user.isDoctor)
          CustomTextField(
            icon: const FaIcon(FontAwesomeIcons.userDoctor),
            label: 'Specialty',
            required: true,
            controller: _specialtyController!,
          )
        else if (user.isPatient)
          CustomTextField(
            icon: const Icon(Icons.calendar_month),
            label: 'BirthDate',
            required: true,
            controller: _birthdateController!,
            hint: 'yyyy-MM-dd',
          ),
        CustomTextField(
          icon: const Icon(Icons.pin_drop),
          label: 'Province',
          required: true,
          controller: _provinceController,
        ),
        CustomTextField(
          icon: const Icon(Icons.pin_drop),
          label: 'City',
          required: true,
          controller: _cityController,
        ),
        CustomTextField(
          icon: const Icon(Icons.pin_drop),
          label: 'Street',
          required: true,
          controller: _streetController,
        ),
      ],
    );
  }
}
