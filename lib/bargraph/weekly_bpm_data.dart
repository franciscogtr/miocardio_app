// lib/bargraph/weekly_bpm_data.dart
import 'package:miocardio_app/model/afericao.dart';

class IndividualPoint {
  final double x;
  final double y;

  IndividualPoint({required this.x, required this.y});
}

class WeeklyBpmData {
  final List<Afericao> afericoes;

  WeeklyBpmData({required this.afericoes});

  List<IndividualPoint> lineData = [];

  void initializeLineData() {
    lineData = [];

    for (int i = 0; i < afericoes.length; i++) {
      lineData.add(IndividualPoint(
        x: i.toDouble(),
        y: afericoes[i].bpm.toDouble(),
      ));
    }
  }

  double getMaxY() {
    if (lineData.isEmpty) return 120;
    double max = lineData.map((point) => point.y).reduce((a, b) => a > b ? a : b);
    return max + 20;
  }

  double getMinY() {
    if (lineData.isEmpty) return 40;
    double min = lineData.map((point) => point.y).reduce((a, b) => a < b ? a : b);
    return min - 20;
  }
}