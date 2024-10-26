import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tahlil_front/classes/appointment.dart' as ap;
import 'package:tahlil_front/services/profile.dart';

class AppointmentDataSource extends CalendarDataSource<ap.Appointment> {
  static final colors = Colors.primaries.map((c) => c.shade700).toList();

  bool showAppointmentInfo;

  List<ap.Appointment> _appointments;

  @override
  List<ap.Appointment> get appointments => _appointments;

  AppointmentDataSource(
    List<ap.Appointment> appointments, {
    this.showAppointmentInfo = false,
  }) : _appointments = appointments;

  @override
  DateTime getStartTime(int index) => appointments[index].time.dateTime;

  @override
  DateTime getEndTime(int index) =>
      appointments[index].time.dateTime.add(const Duration(hours: 1));

  @override
  String getSubject(int index) {
    if (!showAppointmentInfo) return '';
    final appointment = appointments[index];
    if (ProfileService.instance.profileCached?.isDoctor ?? false) {
      return appointment.patient.fullName;
    }
    if (appointment is ap.ImagingCenterAppointment) {
      return appointment.patient.fullName;
    }
    if (appointment is ap.DoctorAppointment) return appointment.doctor.fullName;
    return (appointment as ap.ImagingCenterAppointment).imagingCenter.name;
  }

  @override
  bool isAllDay(int index) => false;

  @override
  Color getColor(int index) =>
      showAppointmentInfo ? colors[index % colors.length] : Colors.black12;
}
