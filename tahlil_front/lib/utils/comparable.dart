class Comparable<T> {
  final T value;

  Comparable(this.value);

  int compareTo(Comparable<T> other) => 0;

  @override
  String toString() => '$value';
}

class BoolComparable extends Comparable<bool> {
  BoolComparable(super.value);

  @override
  int compareTo(Comparable<bool> other) {
    if (value == other.value) return 0;
    if (!value && other.value) return -1;
    return 1;
  }
}

class IntComparable extends Comparable<int> {
  IntComparable(super.value);

  @override
  int compareTo(Comparable<int> other) {
    if (value == other.value) return 0;
    if (value < other.value) return -1;
    return 1;
  }
}

class DoubleComparable extends Comparable<double> {
  DoubleComparable(super.value);

  @override
  int compareTo(Comparable<double> other) {
    if (value == other.value) return 0;
    if (value < other.value) return -1;
    return 1;
  }
}
