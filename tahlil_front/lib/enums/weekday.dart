enum Weekday {
  saturday,
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday;

  static Weekday find(String name) =>
      Weekday.values.where((wd) => '$wd' == name).first;

  @override
  String toString() => super.toString().split('.')[1];
}
