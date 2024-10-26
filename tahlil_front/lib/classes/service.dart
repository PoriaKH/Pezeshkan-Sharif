import 'package:intl/intl.dart';

class Service {
  final String code, details;
  final double professionalComponent,
      technicalComponent,
      materialConsumableComponent;
  final int finalCostIRR;

  Service({
    required this.code,
    required this.details,
    required this.professionalComponent,
    required this.technicalComponent,
    required this.materialConsumableComponent,
    required this.finalCostIRR,
  });

  Service.fromJson(json)
      : this(
          code: json['code'],
          details: json['details'],
          professionalComponent: double.parse(json['professional_component']),
          technicalComponent: double.parse(json['technical_component']),
          materialConsumableComponent:
              double.parse(json['material_consumable_component']),
          finalCostIRR: int.parse(json['final_cost']),
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

extension ServiceListExt on List<Service> {
  String get totalCost => NumberFormat('###,###,### IRR')
      .format(isEmpty ? 0 : map((s) => s.finalCostIRR).reduce((e, v) => e + v));
}
