// lib/bargraph/weekly_bpm_graph.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:miocardio_app/bargraph/weekly_bpm_data.dart';
import 'package:miocardio_app/model/afericao.dart';
import 'package:miocardio_app/repos/cardio_repository.dart';
import 'package:provider/provider.dart';

class WeeklyBpmGraph extends StatelessWidget {
  const WeeklyBpmGraph({super.key});

  Color _getBpmColor(double bpm) {
    if (bpm < 60) return Colors.blue;
    if (bpm <= 100) return Colors.green;
    if (bpm <= 120) return Colors.orange;
    return Color.fromARGB(255, 226, 21, 65);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<cardioRepository>(
      builder: (context, repository, child) {
        List<Afericao> afericoesParaGrafico = repository.afericoesSemanais;

        if (afericoesParaGrafico.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma aferição esta semana',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Faça sua primeira medição',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        WeeklyBpmData lineData = WeeklyBpmData(afericoes: afericoesParaGrafico);
        lineData.initializeLineData();

        double bpmMedio = repository.getBpmMedioSemana();

        return LineChart(
          LineChartData(
            maxY: lineData.getMaxY(),
            minY: lineData.getMinY(),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: lineData.lineData
                    .map((point) => FlSpot(point.x, point.y))
                    .toList(),
                isCurved: true,
                color: Color.fromARGB(255, 226, 21, 65),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: _getBpmColor(spot.y),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 226, 21, 65).withOpacity(0.3),
                      Color.fromARGB(255, 226, 21, 65).withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Linha de referência - BPM médio
              if (bpmMedio > 0)
                LineChartBarData(
                  spots: [
                    FlSpot(0, bpmMedio),
                    FlSpot(lineData.lineData.length - 1.0, bpmMedio),
                  ],
                  isCurved: false,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                  dashArray: [5, 5],
                ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    if (spot.x.toInt() >= 0 && spot.x.toInt() < afericoesParaGrafico.length) {
                      DateTime data = afericoesParaGrafico[spot.x.toInt()].dataAfericao;
                      return LineTooltipItem(
                        '${spot.y.toInt()} bpm\n${data.day}/${data.month} ${data.hour}:${data.minute.toString().padLeft(2, '0')}',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}