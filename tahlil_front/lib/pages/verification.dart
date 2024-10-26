import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tahlil_front/classes/doctor.dart';
import 'package:tahlil_front/classes/imaging_center.dart';
import 'package:tahlil_front/classes/patient.dart';
import 'package:tahlil_front/classes/user.dart';
import 'package:tahlil_front/enums/user_type.dart';
import 'package:tahlil_front/extensions/string_ext.dart';
import 'package:tahlil_front/services/verification.dart';
import 'package:tahlil_front/widgets/empty.dart' as empty;
import 'package:tahlil_front/widgets/error.dart' as error;

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  static final _verificationService = VerificationService.instance;
  bool showAccepted = false, showDeclined = false;
  List<UserType> showUserTypes = [
    UserType.doctor,
    UserType.patient,
    UserType.imaging_center
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelSmall = textTheme.labelSmall
        ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white);
    final titleMedium =
        textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final bodyMedium =
        textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 50,
            right: 50,
            top: 30,
            bottom: 10,
          ),
          child: Material(
            elevation: 1,
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Text('Show Accepted?', style: bodyMedium),
                  const SizedBox(width: 5),
                  Switch(
                    value: showAccepted,
                    onChanged: (v) => setState(() => showAccepted = v),
                  ),
                  const SizedBox(width: 20),
                  Text('Show Declined?', style: bodyMedium),
                  const SizedBox(width: 5),
                  Switch(
                    value: showDeclined,
                    onChanged: (v) => setState(() => showDeclined = v),
                  ),
                  Expanded(child: Container()),
                  ...[
                    UserType.doctor,
                    UserType.patient,
                    UserType.imaging_center,
                  ]
                      .map((ut) => [
                            Text('Show ${ut}s?', style: bodyMedium),
                            const SizedBox(width: 5),
                            Switch(
                              value: showUserTypes.contains(ut),
                              onChanged: (v) => setState(() => (v
                                  ? showUserTypes.add
                                  : showUserTypes.remove)(ut)),
                            ),
                            if (ut != UserType.imaging_center)
                              const SizedBox(width: 20),
                          ])
                      .expand((w) => w),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<User>>(
            future: _verificationService.verifyList(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return error.ErrorWidget(
                  msg: 'list of verifiable users.',
                  refresh: () => setState(() {}),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final users = snapshot.data!.where((u) {
                if (!showAccepted && u.isVerified) return false;
                if (!showDeclined && u.isDeclined) return false;
                return showUserTypes.contains(u.userType);
              }).toList();

              if (users.isEmpty) {
                return empty.EmptyWidget(
                  msg: 'No Users found.',
                  refresh: () => setState(() {}),
                );
              }

              return GridView.builder(
                itemCount: users.length,
                padding: const EdgeInsets.only(
                  bottom: 30,
                  left: 50,
                  right: 50,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500,
                  mainAxisExtent: 200,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                ),
                itemBuilder: (context, i) {
                  final user = users[i];

                  return Material(
                    elevation: 2,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Badge(
                                  label: Text(
                                    '${user.userType}',
                                    style: labelSmall,
                                  ),
                                  offset: const Offset(15, -4),
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  child: Text(
                                    user is ImagingCenter
                                        ? user.name
                                        : '${user.firstName} ${user.lastName}',
                                    style: titleMedium,
                                  ),
                                ),
                                Expanded(child: Container()),
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: user.isDeclined
                                          ? Colors.grey.shade300
                                          : Colors.red.shade900,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: IconButton(
                                      color: Colors.white,
                                      icon: const Icon(Icons.cancel_outlined),
                                      onPressed: user.isDeclined
                                          ? null
                                          : () => _verificationService
                                              .decline(user)
                                              .then((_) => setState(() {})),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: user.isVerified
                                        ? Colors.grey.shade300
                                        : Colors.green.shade900,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: IconButton(
                                    color: Colors.white,
                                    icon: const Icon(Icons.check),
                                    onPressed: user.isVerified
                                        ? null
                                        : () => _verificationService
                                            .accept(user)
                                            .then((_) => setState(() {})),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const FaIcon(FontAwesomeIcons.idCard),
                                      const SizedBox(width: 10),
                                      Text(
                                          '${user is ImagingCenter ? user.id : user.ssid}',
                                          style: bodyMedium),
                                    ],
                                  ),
                                ),
                                if (user is Doctor)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.medical_information),
                                        const SizedBox(width: 10),
                                        Text(user.medicalId, style: bodyMedium),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone),
                                      const SizedBox(width: 10),
                                      Text(user.phoneNumber ?? '-',
                                          style: bodyMedium),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.email),
                                      const SizedBox(width: 10),
                                      Text(user.emailAddress ?? '-',
                                          style: bodyMedium),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            if (user is! ImagingCenter) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (user is Patient)
                                    const Icon(Icons.calendar_month)
                                  else
                                    const FaIcon(FontAwesomeIcons.userDoctor),
                                  const SizedBox(width: 10),
                                  Text(
                                    ((user is Patient)
                                            ? user.birthDate
                                            : (user as Doctor).specialty) ??
                                        '-',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.pin_drop),
                                const SizedBox(width: 10),
                                Text(
                                  // ignore: prefer_interpolation_to_compose_strings
                                  ((user.province as String?) +
                                          ', ' +
                                          user.city +
                                          ', ' +
                                          user.street) ??
                                      '-',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
