import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:tahlil_front/classes/appointment.dart';
import 'package:tahlil_front/classes/service.dart';
import 'package:tahlil_front/services/appointment.dart';
import 'package:tahlil_front/utils/service_data_source.dart';

class ServicesPage extends StatefulWidget {
  final int appointment;

  const ServicesPage(this.appointment, {super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _appointmentService = AppointmentService.instance;

  final _widths = <String, double>{};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 50,
        horizontal: 30,
      ),
      child: FutureBuilder<List<Service>>(
        future: _appointmentService.getServices(),
        builder: (context, snapshot) {
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Container();
          }

          final allServices = snapshot.data!;

          return FutureBuilder<List<Service>>(
            future: _appointmentService
                .getAppointment(widget.appointment)
                .then((a) => (a as DoctorAppointment).services),
            builder: (context, snapshot) {
              final selected = snapshot.data ?? [];
              final totalCost = selected.totalCost;
              // final totalCost = NumberFormat('###,###,### IRR').format(
              //     selected.isEmpty
              //         ? 0
              //         : selected
              //             .map((s) => s.finalCostIRR)
              //             .reduce((e, v) => e + v));

              final source = ServiceDataSource(
                services: allServices,
                selected: selected.map((s) => s.code).toList(),
                onToggleSelect: (service, newSelected) async {
                  final newList = selected.map((s) => s.code).toList();
                  (newSelected ? newList.add : newList.remove)(service);
                  await _appointmentService.updateServices(
                    widget.appointment,
                    newList,
                  );
                  setState(() {});
                },
              );

              return Material(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
                elevation: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SfDataGrid(
                    allowSorting: true,
                    allowMultiColumnSorting: true,
                    showSortNumbers: true,
                    footerFrozenRowsCount: 1,
                    footer: Center(
                      child: Text(
                        'Total Cost of Appointment: $totalCost',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    allowColumnsResizing: true,
                    onColumnResizeUpdate: (details) {
                      _widths[details.column.columnName] = details.width;
                      setState(() {});
                      return true;
                    },
                    columnWidthMode: ColumnWidthMode.fitByColumnName,
                    source: source,
                    columns: [
                      GridColumn(
                        columnName: 'selected',
                        label: const Center(child: Text('Selected')),
                        width: _widths['selected'] ?? double.nan,
                      ),
                      GridColumn(
                        columnName: 'code',
                        label: const Center(child: Text('Code')),
                        width: _widths['code'] ?? double.nan,
                      ),
                      GridColumn(
                        columnName: 'professional_component',
                        label:
                            const Center(child: Text('Professional Component')),
                        width: _widths['professional_component'] ?? double.nan,
                      ),
                      GridColumn(
                        columnName: 'technical_component',
                        label: const Center(child: Text('Technical Component')),
                        width: _widths['technical_component'] ?? double.nan,
                      ),
                      GridColumn(
                        columnName: 'material_consumable_component',
                        label: const Center(
                          child: Text('Material and Consumable Component'),
                        ),
                        width: _widths['material_consumable_component'] ??
                            double.nan,
                      ),
                      GridColumn(
                        columnName: 'details',
                        label: const Center(child: Text('Details')),
                        width: _widths['details'] ?? double.nan,
                        columnWidthMode: ColumnWidthMode.fill,
                        allowSorting: false,
                      ),
                      GridColumn(
                        columnName: 'final_cost',
                        label: const Center(child: Text('Final Cost (IRR)')),
                        width: _widths['final_cost'] ?? double.nan,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
