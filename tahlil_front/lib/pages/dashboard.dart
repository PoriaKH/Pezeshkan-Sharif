import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:tahlil_front/classes/statistics.dart';
import 'package:tahlil_front/enums/month.dart';
import 'package:tahlil_front/services/profile.dart';
import 'package:tahlil_front/widgets/error.dart' as error;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _profileService = ProfileService.instance;

  late final TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      animationDuration: 100,
      duration: 500
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Statistics?>(
      future: _profileService.getStatistics(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return error.ErrorWidget(
            msg: 'dashboard.',
            refresh: () => setState(() {}),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final stats = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 2)
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(50),
              child: stats is ReferrerStatistics
                  ? Center(child: ReferrerPieChart(stats))
                  : Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (stats is DoctorStatistics) ...[
                                Expanded(child: AgesBarChart(stats)),
                                Expanded(
                                  child: RepeatingCustomerPieChart(stats),
                                ),
                              ],
                              if (stats is DoctorImagingCenterStatistics)
                                Expanded(child: RatingsPieChart(stats)),
                              if (stats is ReferrerStatistics)
                                Expanded(child: ReferrerPieChart(stats))
                            ],
                          ),
                        ),
                        if (stats is DoctorImagingCenterStatistics)
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: AppointmentDateChart(
                                    stats.groupedAppointmentsByYear.map(
                                      (k, v) => MapEntry('$k', v),
                                    ),
                                    interval: 'All time',
                                    xTitle: 'Year',
                                  ),
                                ),
                                Expanded(
                                  child: AppointmentDateChart(
                                    stats.groupedAppointmentsThisYearByMonth
                                        .map(
                                      (k, v) => MapEntry(
                                        Month.values[k - 1].name
                                            .substring(0, 3)
                                            .toUpperCase(),
                                        v,
                                      ),
                                    ),
                                    interval: 'Current year',
                                    xTitle: 'Month',
                                  ),
                                ),
                                Expanded(
                                  child: AppointmentDateChart(
                                    stats.groupedAppointmentsThisMonth.map(
                                      (k, v) => MapEntry('$k', v),
                                    ),
                                    interval: 'Current Month',
                                    xTitle: 'Day',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget ReferrerPieChart(ReferrerStatistics stats) {
    return PieChart(
      stats.refereePercentages,
      title: 'Verification Status',
      colors: {
        'verified': Colors.green.shade300,
        'declined': Colors.redAccent.shade100,
        'waiting': Colors.amber.shade200,
      },
    );
  }

  Widget RatingsPieChart(DoctorImagingCenterStatistics stats) {
    final data = stats.groupedRating;
    final count = data.values.reduce((v, e) => v + e);
    return PieChart(
      data.map((k, v) => MapEntry('$k⭐️', v)),
      title:
          'Ratings (Rating Count: $count, Average: ${stats.avgRating.toStringAsFixed(1)})',
      colors: {
        '1⭐️': Colors.red,
        '2⭐️': Colors.redAccent.shade100,
        '3⭐️': Colors.amber,
        '4⭐️': Colors.lightGreen.shade400,
        '5⭐️': Colors.green,
      },
    );
  }

  Widget RepeatingCustomerPieChart(DoctorStatistics stats) {
    final data = stats.groupedRepeatCount;
    const maxCount = 4;
    if (data.entries.where((e) => e.key > maxCount).length > 1) {
      for (final e in Map.fromEntries(data.entries).entries) {
        if (e.key <= maxCount) continue;
        data.update(
          maxCount + 1,
          (v) => (v + e.value).toInt(),
          ifAbsent: () => 0,
        );
      }
    }
    final total = data.values.reduce((v, e) => v + e);
    return PieChart(
      data.map((k, v) =>
          MapEntry('${k <= maxCount ? '$k' : '>$maxCount'} Times', v)),
      title: 'Patient Loyalty (Total Patients: $total)',
      colors: {
        '1 Times': Colors.red,
        '2 Times': Colors.redAccent.shade100,
        '3 Times': Colors.amber,
        '4 Times': Colors.lightGreen.shade400,
        '>4 Times': Colors.green,
      },
    );
  }

  Widget AgesBarChart(DoctorStatistics stats) => BarChart(
        stats.groupedPatientsByAge.map((k, v) => MapEntry('$k', v)),
        title: 'Patients\' age distribution',
        xTitle: 'Age',
        yTitle: 'Count',
      );

  Widget AppointmentDateChart(
    Map<String, int> data, {
    required String interval,
    required String xTitle,
  }) {
    return LineChart(
      data,
      title: 'Appointments ($interval)',
      xTitle: xTitle,
      yTitle: 'Number of appointments',
    );
  }

  Widget PieChart(
    Map<String, int> map, {
    required String title,
    required Map<String, Color> colors,
  }) {
    final sum = map.values.reduce((v, e) => v + e);

    return SfCircularChart(
      title: ChartTitle(text: title),
      tooltipBehavior: _tooltipBehavior,
      series: [
        PieSeries(
          explode: true,
          animationDuration: 500,
          dataSource:
              map.entries.map((e) => _PieChartData(e.key, e.value)).toList(),
          xValueMapper: (data, _) => data.xData,
          yValueMapper: (data, _) => data.yData,
          pointColorMapper: (data, _) => colors[data.xData],
          dataLabelMapper: (data, idx) => data.yData == 0
              ? ''
              : '${data.xData}\n(${(data.yData / sum * 100).toStringAsFixed(1)}%)',
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget BarChart<T>(
    Map<T, int> map, {
    required String title,
    required String xTitle,
    required String yTitle,
  }) {
    return SfCartesianChart(
      tooltipBehavior: _tooltipBehavior,
      primaryXAxis: T == DateTime
          ? DateTimeAxis(title: AxisTitle(text: xTitle))
          : CategoryAxis(title: AxisTitle(text: xTitle)),
      primaryYAxis: NumericAxis(title: AxisTitle(text: yTitle)),
      title: ChartTitle(text: title),
      series: [
        ColumnSeries<_BarChartData<T>, String>(
          animationDuration: 500,
          dataSource:
              map.entries.map((e) => _BarChartData(e.key, e.value)).toList(),
          xValueMapper: (data, _) => '${data.xData}',
          yValueMapper: (data, _) => data.yData,
          color: Get.theme.primaryColor,
        ),
      ],
    );
  }

  Widget LineChart<T>(
    Map<T, int> map, {
    required String title,
    required String xTitle,
    required String yTitle,
  }) {
    return SfCartesianChart(
      tooltipBehavior: _tooltipBehavior,
      primaryXAxis: T == DateTime
          ? DateTimeAxis(title: AxisTitle(text: xTitle))
          : CategoryAxis(title: AxisTitle(text: xTitle)),
      primaryYAxis: NumericAxis(title: AxisTitle(text: yTitle)),
      title: ChartTitle(text: title),
      series: [
        LineSeries<_BarChartData<T>, String>(
          enableTooltip: true,
          animationDuration: 500,
          dataSource:
              map.entries.map((e) => _BarChartData(e.key, e.value)).toList(),
          xValueMapper: (data, _) => '${data.xData}',
          yValueMapper: (data, _) => data.yData,
          color: Get.theme.primaryColor,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            borderWidth: 3,
          ),
        ),
      ],
    );
  }
}

class _PieChartData {
  _PieChartData(this.xData, this.yData);

  final String xData;
  final num yData;
}

class _BarChartData<T> {
  final T xData;
  final num yData;

  _BarChartData(this.xData, this.yData);
}
