import 'package:flutter/material.dart';

enum Month {
  january,
  february,
  march,
  april,
  may,
  june,
  july,
  august,
  september,
  october,
  november,
  december;

  int get daysInMonth => DateTimeRange(
        start: DateTime(DateTime.now().year, index + 1, 1),
        end: DateTime(DateTime.now().year, index + 2),
      ).duration.inDays;

  static Month find(String name) =>
      Month.values.where((wd) => '$wd' == name).first;

  @override
  String toString() => super.toString().split('.')[1];
}
