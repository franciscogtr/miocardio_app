// lib/bargraph/bpm_line_data.dart
import 'package:miocardio_app/model/afericao.dart';

class BpmPoint {
  final double x;
  final double y;

  BpmPoint({required this.x, required this.y});
}

class BpmLineData {
  List<Afericao> afericoes;

  BpmLineData({required this.afericoes});

  List<BpmPoint> lineData = [];

  // Inicializa dados da linha
  void initializeLineData() {
    lineData.clear();

    for (int i = 0; i < afericoes.length; i++) {
      lineData.add(BpmPoint(
        x: i.toDouble(),
        y: afericoes[i].bpm.toDouble(),
      ));
    }
  }

  // Retorna valor máximo para escala do gráfico
  double getMaxY() {
    if (afericoes.isEmpty) return 120;

    double max = afericoes
        .map((a) => a.bpm.toDouble())
        .reduce((a, b) => a > b ? a : b);

    // Adiciona 20% de margem
    return max * 1.2;
  }

  // Retorna valor mínimo para escala do gráfico
  double getMinY() {
    if (afericoes.isEmpty) return 40;

    double min = afericoes
        .map((a) => a.bpm.toDouble())
        .reduce((a, b) => a < b ? a : b);

    // Remove 10% para margem inferior
    return (min * 0.9).clamp(40, double.infinity);
  }
}