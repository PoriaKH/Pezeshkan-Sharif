import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tahlil_front/classes/appointment.dart' as ap;
import 'package:tahlil_front/classes/doctor.dart';
import 'package:tahlil_front/classes/imaging_center.dart';
import 'package:tahlil_front/classes/time.dart';
import 'package:tahlil_front/classes/user.dart';
import 'package:tahlil_front/classes/work_time.dart';
import 'package:tahlil_front/enums/toast_type.dart';
import 'package:tahlil_front/extensions/string_ext.dart';
import 'package:tahlil_front/main.dart';
import 'package:tahlil_front/services/appointment.dart';
import 'package:tahlil_front/services/doctor.dart';
import 'package:tahlil_front/services/imaging_center.dart';
import 'package:tahlil_front/services/router.dart';
import 'package:tahlil_front/utils/appointment_data_source.dart';
import 'package:tahlil_front/utils/pair.dart';
import 'package:tahlil_front/utils/triple.dart';
import 'package:tahlil_front/widgets/empty.dart' as empty;
import 'package:tahlil_front/widgets/error.dart' as error;
import 'package:tahlil_front/widgets/toast.dart';

class CreateAppointmentPage extends StatefulWidget {
  final String? doctorSsid, imagingCenterId;

  const CreateAppointmentPage({
    super.key,
    this.doctorSsid,
    this.imagingCenterId,
  }) : assert((doctorSsid ?? imagingCenterId) != null);

  @override
  State<CreateAppointmentPage> createState() => _CreateAppointmentPageState();
}

class _CreateAppointmentPageState extends State<CreateAppointmentPage> {
  final _doctorService = DoctorService.instance;
  final _imagingCenterService = ImagingCenterService.instance;
  final _appointmentService = AppointmentService.instance;

  CalendarController calendarController = CalendarController();
  DateTime? selectedDateTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doctor = widget.doctorSsid;
    final imagingCenter = widget.imagingCenterId;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        elevation: 10,
        onPressed: _createAppointment,
        label: Text(
          'Create Appointment for ${selectedDateTime == null ? '-' : DateFormat('yyyy/MMMM/dd HH:mm').format(selectedDateTime!)}',
        ),
        icon: const Icon(Icons.check),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: 1000,
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 2),
                      ],
                    ),
                    child: FutureBuilder<User?>(
                      future: doctor != null
                          ? _doctorService.getDoctorInfo(doctor)
                          : _imagingCenterService
                              .getImagingCenterInfo(imagingCenter!),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        if (user != null) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Triple<String, Widget?, dynamic>>[
                                if (user is Doctor) ...[
                                  Triple('', null, user.fullName),
                                  Triple(
                                      'Medical ID: ',
                                      const Icon(Icons.numbers),
                                      user.medicalId),
                                ] else if (user is ImagingCenter)
                                  Triple('', null, user.name),
                                Triple(
                                    'Phone number: ',
                                    const Icon(Icons.phone),
                                    user.phoneNumber ?? '-'),
                                Triple(
                                    'Email Address: ',
                                    const Icon(Icons.email),
                                    user.emailAddress ?? '-'),
                                if (user is Doctor)
                                  Triple(
                                      'Specialty: ',
                                      const FaIcon(FontAwesomeIcons.userDoctor),
                                      user.specialty ?? '-'),
                                Triple(
                                    'Address: ',
                                    const Icon(Icons.pin_drop),
                                    // ignore: prefer_interpolation_to_compose_strings
                                    (user.province +
                                            ', ' +
                                            user.city +
                                            ', ' +
                                            user.street) ??
                                        '-'),
                                Triple(
                                  'Working Hours: ',
                                  const Icon(Icons.work),
                                  (user is Doctor
                                              ? user.workTimes
                                              : (user as ImagingCenter)
                                                  .workTimes)
                                          .map((wt) => '$wt')
                                          .join(', ')
                                          .capitalize
                                          ?.nullIfEmpty ??
                                      '-',
                                ),
                              ].map((tup) {
                                final label = tup.first;
                                final icon = tup.second;
                                final value = tup.third;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 5),
                                        child: icon ?? Container(),
                                      ),
                                      RichText(
                                        text: TextSpan(children: [
                                          TextSpan(
                                              text: label,
                                              style:
                                                  theme.textTheme.bodyMedium),
                                          TextSpan(
                                            text: '$value',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w900),
                                          ),
                                        ]),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }
                        return Container();
                      },
                    )
                    // todo
                    ),
                const SizedBox(height: 20),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 2),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: FutureBuilder<Pair<List<WorkTime>, List<Time>>>(
                        future: doctor != null
                            ? Future.wait([
                                _doctorService.getWorkTimes(doctor),
                                _doctorService.filledTimesSinceToday(doctor),
                              ]).then((list) => Pair(list[0] as List<WorkTime>,
                                list[1] as List<Time>))
                            : Future.wait([
                                _imagingCenterService
                                    .getWorkTimes(imagingCenter!),
                                _imagingCenterService
                                    .filledTimesSinceToday(imagingCenter),
                              ]).then((list) => Pair(list[0] as List<WorkTime>,
                                list[1] as List<Time>)),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return error.ErrorWidget(
                              msg: 'calendar.',
                              refresh: () => setState(() {}),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final workTimes = snapshot.data!.first;
                          final unavailableTimes = snapshot.data!.second;
                          final dataSource = unavailableTimes
                              .asMap()
                              .map(
                                (i, time) => MapEntry(
                                  i,
                                  ap.Appointment(
                                    id: i,
                                    patientSsid: '',
                                    patientFirstName: '',
                                    patientLastName: '',
                                    time: time,
                                    rating: 0,
                                  ),
                                ),
                              )
                              .values
                              .cast<ap.Appointment>()
                              .toList();

                          if (workTimes.isEmpty) {
                            return empty.EmptyWidget(
                              msg:
                                  'This ${doctor != null ? "Doctor" : "Imaging Center"} '
                                  'doesn\'t have any work hours.',
                              refresh: () => setState(() {}),
                            );
                          }

                          return SfCalendar(
                            controller: calendarController,
                            view: CalendarView.week,
                            firstDayOfWeek: 6,
                            showTodayButton: true,
                            showWeekNumber: true,
                            showNavigationArrow: true,
                            allowViewNavigation: true,
                            showDatePickerButton: true,
                            minDate: DateTime.now(),
                            maxDate:
                                DateTime.now().add(const Duration(days: 100)),
                            dataSource: AppointmentDataSource(dataSource),
                            onTap: (details) {
                              final date = details.date!;
                              final week =
                                  'monday tuesday wednesday thursday friday '
                                          'saturday sunday'
                                      .split(' ');
                              if (workTimes.any((wt) =>
                                      wt.startHour <= date.hour &&
                                      date.hour < wt.endHour &&
                                      '${wt.weekday}' ==
                                          week[date.weekday - 1]) &&
                                  !unavailableTimes
                                      .any((t) => t.dateTime == date)) {
                                selectedDateTime = details.date;
                              } else {
                                calendarController.selectedDate = null;
                                calendarController.displayDate = null;
                                selectedDateTime = null;
                              }
                              setState(() {});
                            },
                            timeSlotViewSettings: const TimeSlotViewSettings(
                              nonWorkingDays: [],
                              minimumAppointmentDuration: Duration(hours: 1),
                              dateFormat: 'dd',
                              dayFormat: 'EEE',
                              timeFormat: 'HH',
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createAppointment() async {
    String msg;
    bool success;
    if (selectedDateTime == null) {
      msg = 'Please Select a valid date and time for the appointment!';
      success = false;
    } else {
      final response = await _appointmentService.createAppointment(
        selectedDateTime!,
        doctor: widget.doctorSsid,
        imagingCenter: widget.imagingCenterId,
      );
      success = response.first;
      msg = response.second;
    }
    final toast = FToast();
    toast.init(rootNavigatorKey.currentContext!);
    toast.showToast(
      child: CustomToast(
        text: msg,
        toastType: success ? ToastType.success : ToastType.error,
      ),
      gravity: ToastGravity.BOTTOM_LEFT,
    );
    if (success) {
      RouterService.go(
        widget.doctorSsid != null ? '/doctors' : '/imaging-centers',
      );
    }
  }
}
