import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tahlil_front/classes/appointment.dart' as ap;
import 'package:tahlil_front/services/appointment.dart';
import 'package:tahlil_front/services/router.dart';
import 'package:tahlil_front/utils/appointment_data_source.dart';
import 'package:tahlil_front/widgets/empty.dart' as empty;
import 'package:tahlil_front/widgets/error.dart' as error;

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final _appointmentService = AppointmentService.instance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: FutureBuilder<List<ap.Appointment>>(
        future: _appointmentService.getAppointments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return error.ErrorWidget(
              msg: 'your appointments.',
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
              msg: 'You don\'t have any appointment.',
              refresh: () => setState(() {}),
            );
          }

          final appointments = snapshot.data!;
          final times = appointments.map((a) => a.time.dateTime).toList();
          times.add(DateTime.now());

          final minDate =
              times.reduce((val, elem) => val.isBefore(elem) ? val : elem);
          final maxDate =
              times.reduce((val, elem) => val.isAfter(elem) ? val : elem);

          return SfCalendar(
            view: CalendarView.schedule,
            firstDayOfWeek: 6,
            showDatePickerButton: true,
            showTodayButton: true,
            showWeekNumber: true,
            showNavigationArrow: true,
            allowViewNavigation: true,
            allowedViews: const [
              CalendarView.schedule,
              CalendarView.day,
              CalendarView.week,
              CalendarView.month,
            ],
            minDate: minDate,
            maxDate: maxDate,
            dataSource: AppointmentDataSource(
              appointments,
              showAppointmentInfo: true,
            ),
            onTap: (details) {
              // if (details.targetElement == CalendarElement.appointment) {
              final appointment =
                  details.appointments?.cast<ap.Appointment>().firstOrNull;
              if (appointment != null) {
                RouterService.go('/appointment/${appointment.id}');
              }
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
    );
  }
}
