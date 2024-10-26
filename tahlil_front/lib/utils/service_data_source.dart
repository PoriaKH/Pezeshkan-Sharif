import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:tahlil_front/classes/service.dart';
import 'package:tahlil_front/utils/comparable.dart';

class ServiceDataSource extends DataGridSource {
  void Function(String, bool) onToggleSelect;

  ServiceDataSource({
    required List<Service> services,
    required List<String> selected,
    required this.onToggleSelect,
  }) {
    _services = services
        .map(
          (e) => DataGridRow(
            cells: [
              DataGridCell(
                columnName: 'selected',
                value: BoolComparable(selected.contains(e.code)),
              ),
              DataGridCell(columnName: 'code', value: e.code),
              DataGridCell(
                columnName: 'professional_component',
                value: DoubleComparable(e.professionalComponent),
              ),
              DataGridCell(
                columnName: 'technical_component',
                value: DoubleComparable(e.technicalComponent),
              ),
              DataGridCell(
                columnName: 'material_consumable_component',
                value: DoubleComparable(e.materialConsumableComponent),
              ),
              DataGridCell(columnName: 'details', value: e.details),
              DataGridCell(
                columnName: 'final_cost',
                value: IntComparable(e.finalCostIRR),
              ),
            ],
          ),
        )
        .toList();
  }

  List<DataGridRow> _services = [];

  @override
  List<DataGridRow> get rows => _services;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map(
      (cell) {
        final value = cell.value;

        return Container(
          alignment: (cell.value is String || cell.value is BoolComparable)
              ? Alignment.centerLeft
              : Alignment.centerRight,
          padding: const EdgeInsets.all(5),
          child: cell.columnName == 'selected'
              ? Checkbox(
                  value: value is Comparable ? value.value : value,
                  onChanged: (newSelected) {
                    onToggleSelect(
                      row.getCells()[1].value,
                      newSelected!,
                    );
                  },
                )
              : Text(cell.columnName == 'final_cost'
                  ? NumberFormat('###,###,### IRR')
                      .format((cell.value as IntComparable).value)
                  : '${cell.value}'),
        );
      },
    ).toList());
  }
}
