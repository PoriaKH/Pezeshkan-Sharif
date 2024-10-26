import 'dart:js' as js;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tahlil_front/classes/appointment.dart';
import 'package:tahlil_front/classes/doctor.dart';
import 'package:tahlil_front/classes/imaging_center.dart';
import 'package:tahlil_front/classes/patient.dart';
import 'package:tahlil_front/classes/service.dart';
import 'package:tahlil_front/classes/user.dart';
import 'package:tahlil_front/enums/toast_type.dart';
import 'package:tahlil_front/extensions/string_ext.dart';
import 'package:tahlil_front/main.dart';
import 'package:tahlil_front/services/appointment.dart';
import 'package:tahlil_front/services/profile.dart';
import 'package:tahlil_front/services/router.dart';
import 'package:tahlil_front/utils/pair.dart';
import 'package:tahlil_front/widgets/accordion_item.dart';
import 'package:tahlil_front/widgets/empty.dart' as empty;
import 'package:tahlil_front/widgets/error.dart' as error;
import 'package:tahlil_front/widgets/profile_picture.dart';
import 'package:tahlil_front/widgets/toast.dart';

class AppointmentPage extends StatefulWidget {
  final int id;

  const AppointmentPage(this.id, {super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _appointmentService = AppointmentService.instance;
  final _profileService = ProfileService.instance;

  final height = 750.0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Appointment?>(
      future: _appointmentService.getAppointment(widget.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return error.ErrorWidget(
            msg: 'appointment information.',
            refresh: () => setState(() {}),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final appointment = snapshot.data!;

        return FutureBuilder<User?>(
            future: _profileService.profile,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();
              final profile = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 50,
                  horizontal: 30,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.isPatient)
                      if (appointment is DoctorAppointment)
                        _GeneralInfoWidget(profile, appointment, doctor: true)
                      else
                        _GeneralInfoWidget(
                          profile,
                          appointment,
                          imagingCenter: true,
                        )
                    else
                      _GeneralInfoWidget(profile, appointment, patient: true),
                    const SizedBox(width: 20),
                    if (profile.isPatient)
                      if (appointment is DoctorAppointment)
                        _DetailedInfoWidget(profile, appointment, doctor: true)
                      else
                        _DetailedInfoWidget(
                          profile,
                          appointment,
                          imagingCenter: true,
                        )
                    else
                      _DetailedInfoWidget(profile, appointment, patient: true)
                  ],
                ),
              );
            });
      },
    );
  }

  Widget _GeneralInfoWidget(
    User profile,
    Appointment appointment, {
    bool imagingCenter = false,
    bool doctor = false,
    bool patient = false,
  }) {
    User? user;
    if (patient) {
      user = appointment.patient;
    } else if (doctor) {
      user = (appointment as DoctorAppointment).doctor;
    } else if (imagingCenter) {
      user = (appointment as ImagingCenterAppointment).imagingCenter;
    }

    final theme = Theme.of(context).textTheme;
    final titleLarge = theme.titleLarge?.copyWith(fontWeight: FontWeight.w900);
    final bodyLarge = theme.bodyLarge?.copyWith(fontWeight: FontWeight.w900);

    return SplitWidget(
      child: SingleChildScrollView(
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user is! ImagingCenter)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 50,
                    right: 50,
                    top: 50,
                    bottom: 30,
                  ),
                  child: ProfilePictureWidget(user!),
                ),
              Text(
                (user!.isImagingCenter
                        ? (user as ImagingCenter).name
                        : user.fullName)
                    .capitalize!,
                textAlign: TextAlign.center,
                style: titleLarge,
              ),
              ...[
                Pair(const Icon(Icons.person), user.userType),
                if (user is Doctor)
                  Pair(const Icon(Icons.medical_information), user.medicalId)
                else if (user is Patient)
                  Pair(const Icon(Icons.calendar_month), user.birthDate ?? '-'),
                Pair(const Icon(Icons.phone), user.phoneNumber ?? '-'),
                Pair(const Icon(Icons.email), user.emailAddress ?? '-'),
                if (user is Doctor)
                  Pair(
                    const FaIcon(FontAwesomeIcons.userDoctor),
                    user.specialty ?? '-',
                  ),
                Pair(
                    const Icon(Icons.pin_drop),
                    // ignore: prefer_interpolation_to_compose_strings
                    (user.province + ', ' + user.city + ', ' + user.street) ??
                        '-'),
              ].map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: p.first,
                      ),
                      Text('${p.second}', style: bodyLarge)
                    ],
                  ),
                );
              }),
              if (profile.isPatient)
                Center(
                  child: RatingBar.builder(
                    wrapAlignment: WrapAlignment.center,
                    initialRating: appointment.rating ?? 0,
                    allowHalfRating: true,
                    itemCount: 5,
                    glowRadius: 1,
                    itemBuilder: (context, index) {
                      return Icon(
                          [
                            Icons.sentiment_very_dissatisfied,
                            Icons.sentiment_dissatisfied,
                            Icons.sentiment_neutral,
                            Icons.sentiment_satisfied,
                            Icons.sentiment_very_satisfied
                          ][index],
                          color: [
                            Colors.red,
                            Colors.redAccent,
                            Colors.amber,
                            Colors.lightGreen,
                            Colors.green
                          ][index]);
                    },
                    onRatingUpdate: (rating) async {
                      if (await _appointmentService.rate(appointment, rating)) {
                        setState(() {});
                      }
                    },
                  ),
                )
              else if (patient && profile.isDoctor) ...[
                Expanded(
                  child: FutureBuilder<List<Service>>(
                    future: (appointment as DoctorAppointment).services,
                    builder: (context, snapshot) {
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: SingleChildScrollView(
                          child: ServicesWidget(snapshot.data ?? []),
                        ),
                      );
                    },
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.medication),
                  label: const Text('Edit Services'),
                  onPressed: () =>
                      RouterService.go('/services/${appointment.id}'),
                ),
              ] else
                Expanded(child: Container()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _DetailedInfoWidget(
    User profile,
    Appointment appointment, {
    bool imagingCenter = false,
    bool doctor = false,
    bool patient = false,
  }) {
    final theme = Theme.of(context).textTheme;
    final titleLarge = theme.titleLarge?.copyWith(fontWeight: FontWeight.w900);
    return SplitWidget(
      flex: 4,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${appointment.time}'.capitalize!, style: titleLarge),
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 20),
              child: Divider(),
            ),
            if (patient) ...[
              if (profile.isDoctor)
                PatientHistoryWidget(appointment)
              else ...[
                CurrentAppointmentImages(appointment),
                SizedBox(height: 50),
                TextButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Images'),
                  onPressed: () => _uploadImages(appointment),
                )
              ],
            ] else ...[
              // todo show doctor or imaging center statistics
            ],
          ],
        ),
      ),
    );
  }

  Widget ImageItemWidget(Appointment appointment, String link) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        height: 60,
        child: Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(50),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image(
                        fit: BoxFit.cover,
                        image: CachedNetworkImageProvider(link),
                      ),
                    ),
                  ),
                ),
                Expanded(child: Container()),
                if (_profileService.profileCached!.isImagingCenter)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Image'),
                      onPressed: () => _deleteImage(appointment, link),
                    ),
                  ),
                FilledButton.icon(
                  icon: const Icon(Icons.remove_red_eye),
                  label: const Text('View Image'),
                  onPressed: () => js.context.callMethod('open', [link]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget CurrentAppointmentImages(Appointment appointment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: FutureBuilder<List<String>>(
          future: _appointmentService.getAppointmentImages(appointment.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return error.ErrorWidget(
                msg: 'appointment images.',
                refresh: () => setState(() {}),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.data!.isEmpty) {
              return empty.EmptyWidget(
                msg: 'This Patient doesn\'t have any images.',
                refresh: () => setState(() {}),
              );
            }

            final images = snapshot.data ?? [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: images
                  .map((link) => ImageItemWidget(appointment, link))
                  .toList(),
            );
          }),
    );
  }

  Widget PatientHistoryWidget(Appointment appointment) {
    return FutureBuilder<Map<Appointment, List<String>>>(
      future: _appointmentService
          .getAppointments(patient: appointment.patient.ssid)
          .then(
            (list) => Future.wait(
              list.map(
                (a) async => MapEntry(
                  a,
                  await _appointmentService.getAppointmentImages(a.id),
                ),
              ),
            ),
          )
          .then((list) => Map.fromEntries(list)),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return error.ErrorWidget(
            msg: 'patient history.',
            refresh: () => setState(() {}),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final appointments =
            snapshot.data!.entries.where((a2) => a2.key.id != appointment.id);

        if (appointments.isEmpty) {
          return empty.EmptyWidget(
            msg: 'This Patient doesn\'t have any history.',
            refresh: () => setState(() {}),
          );
        }

        return Column(
          children: appointments.map((e) {
            final appointment = e.key;
            final images = e.value;

            return AccordionItemWidget(
              title: '${appointment.time}',
              badge: appointment.type,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: (appointment is ImagingCenterAppointment)
                      ? images
                          .map((link) => ImageItemWidget(appointment, link))
                          .toList()
                      : [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: FutureBuilder<List<Service>>(
                              future:
                                  (appointment as DoctorAppointment).services,
                              builder: (context, snapshot) {
                                if (snapshot.hasError ||
                                    !snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Container();
                                }
                                final services = snapshot.data!;

                                return ServicesWidget(services);
                              },
                            ),
                          )
                        ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget SplitWidget({int flex = 1, Widget? child}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 2),
          ],
        ),
        child: child,
      ),
    );
  }

  Future<void> _uploadImages(Appointment appointment) async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: true);

    if ((result?.files.length ?? 0) > 0) {
      final response = await _appointmentService.uploadImages(
        appointment: appointment.id,
        files: result!.files,
      );
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

  Future<void> _deleteImage(Appointment appointment, String link) async {
    final response = await _appointmentService.deleteImage(
      appointment: appointment.id,
      image: link,
    );
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

  Widget ServicesWidget(List<Service> services) {
    final theme = Theme.of(context).textTheme;

    final bodySmall = theme.bodySmall;
    final bodyMedium = theme.bodyMedium;

    final notesStyleBoldest = bodyMedium?.copyWith(fontWeight: FontWeight.w900);
    final notesStyleBolder = bodySmall?.copyWith(fontWeight: FontWeight.w900);
    final notesStyleBold = bodySmall?.copyWith(fontWeight: FontWeight.bold);
    final notesStyle = bodySmall;

    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: 'Services (Total cost: ${services.totalCost}): \n',
          style: notesStyleBoldest,
        ),
        if (services.isEmpty) TextSpan(text: '  -\n', style: notesStyleBolder),
        ...services
            .map(
              (s) => [
                TextSpan(text: '  ${s.code}:\n', style: notesStyleBolder),
                ...{
                  'Details': s.details,
                  'Professional Component': s.professionalComponent,
                  'Technical Component': s.technicalComponent,
                  'Material & Consumable Component':
                      s.materialConsumableComponent,
                  'Final Cost':
                      NumberFormat('###,###,### IRR').format(s.finalCostIRR)
                }
                    .entries
                    .map(
                      (e) => [
                        TextSpan(text: '    ${e.key}: ', style: notesStyleBold),
                        TextSpan(text: '${e.value}\n', style: notesStyle),
                      ],
                    )
                    .expand((i) => i),
              ],
            )
            .expand((i) => i),
      ]),
    );
  }
}
