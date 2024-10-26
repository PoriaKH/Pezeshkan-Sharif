import 'package:get/get.dart';

enum Province {
  alborz,
  ardabil,
  azerbaijan_east,
  azerbaijan_west,
  bushehr,
  chaharmahal_and_bakhtiari,
  fars,
  gilan,
  golestan,
  hamadan,
  hormozgan,
  ilam,
  isfahan,
  kerman,
  kermanshah,
  khorasan_north,
  khorasan_razavi,
  khorasan_south,
  khuzestan,
  kohgiluyeh_and_boyer_ahmad,
  kurdistan,
  lorestan,
  markazi,
  mazandaran,
  qazvin,
  qom,
  semnan,
  sistan_and_baluchestan,
  tehran,
  yazd,
  zanjan;

  @override
  String toString() =>
      super.toString().split('.')[1].replaceAll('_', ' ').capitalize!;
}
