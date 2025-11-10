import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:miocardio_app/bargraph/activity_data.dart';
import 'package:miocardio_app/repos/pedometer_repository.dart';
import 'package:provider/provider.dart';

class MyActivityGraph extends StatelessWidget {
  const MyActivityGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<pedometerRepository>(
      builder: (context, repository, child) {
        // Se não tiver dados, mostra mensagem
        if (repository.ultimasSeteHoras.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma atividade registrada',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Comece a caminhar para ver seus dados',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        // Inicializa BarData com dados reais
        BarData myBarData = BarData(atividades: repository.ultimasSeteHoras);
        myBarData.initializedBarData();

        return BarChart(
          BarChartData(
            maxY: myBarData.getMaxY(),
            minY: 0,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // Mostra a hora de cada barra
                    int index = value.toInt();
                    if (index >= 0 && index < repository.ultimasSeteHoras.length) {
                      int hora = repository.ultimasSeteHoras[index].data.hour;
                      return Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          '${hora}h',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return Text('');
                  },
                ),
              ),
            ),
            barGroups: myBarData.barData
                .map((data) => BarChartGroupData(
              x: data.x.toInt(),
              barRods: [
                BarChartRodData(
                  toY: data.y,
                  color: Color.fromARGB(255, 226, 21, 65),
                  width: 25,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            )).toList(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} passos',
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