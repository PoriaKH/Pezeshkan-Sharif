enum UserType {
  patient,
  doctor,
  referrer,
  imaging_center;

  @override
  String toString() {
    switch(this) {
      case UserType.patient: return 'Patient';
      case UserType.doctor: return 'Doctor';
      case UserType.referrer: return 'Referrer';
      case UserType.imaging_center: return 'Imaging Center';
    }
  }
}
