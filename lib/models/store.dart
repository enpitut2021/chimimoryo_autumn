import 'package:chimimoryo_autumn/models/pay.dart';

class Store {
  final List<Pay> pays;
  final String name;
  final double? distance;

  Store({required this.name, required this.pays, this.distance});
}
