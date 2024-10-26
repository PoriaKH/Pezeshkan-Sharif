extension NullableStringExt on String? {
  String? operator +(String? other) {
    if (this == null || other == null) return null;
    return '$this$other';
  }

  int? toInt() => this == null ? null : int.tryParse(this!);

  double? toDouble() => this == null ? null : double.tryParse(this!);
}

extension StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
