// lib/bargraph/weekly_steps_graph.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:miocardio_app/bargraph/weekly_activity_data.dart';
import 'package:miocardio_app/repos/pedometer_repository.dart';
import 'package:provider/provider.dart';

class WeeklyStepsGraph extends StatelessWidget {
  const WeeklyStepsGraph({super.key});

  String _getDiaDaSemana(int index) {
    final dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    DateTime dataAtual = DateTime.now();
    DateTime dataInicio = dataAtual.subtract(Duration(days: 6));
    DateTime dataIndex = dataInicio.add(Duration(days: index));

    int diaSemana = dataIndex.weekday - 1; // weekday começa em 1 (segunda)
    if (diaSemana < 0) diaSemana = 6; // Domingo

    return dias[diaSemana];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<pedometerRepository>(
      builder: (context, repository, child) {
        WeeklyStepsData myBarData = WeeklyStepsData(
          atividades: repository.atividadesSemanais,
        );
        myBarData.initializeBarData();

        // Encontra valor máximo para ajustar escala
        double maxY = myBarData.barData.isEmpty
            ? 10000
            : myBarData.barData.map((bar) => bar.y).reduce((a, b) => a > b ? a : b).toDouble();

        if (maxY == 0) maxY = 10000;
        maxY = maxY * 1.2; // 20% acima do máximo

        return BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        _getDiaDaSemana(value.toInt()),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: myBarData.barData
                .map(
                  (data) => BarChartGroupData(
                x: data.x.toInt(),
                barRods: [
                  BarChartRodData(
                    toY: data.y.toDouble(),
                    color: Color.fromARGB(255, 226, 21, 65),
                    width: 25,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: false,
                      toY: maxY,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            )
                .toList(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} passos\n${_getDiaDaSemana(group.x.toInt())}',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}