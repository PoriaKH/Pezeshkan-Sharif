class Triple<F, S, T> {
  F first;
  S second;
  T third;

  Triple(this.first, this.second, this.third);

  @override
  String toString() => 'Triple($first, $second, $third)';
}
