// lib/bargraph/weekly_steps_data.dart
import 'package:miocardio_app/bargraph/activity_data.dart';
import 'package:miocardio_app/model/atividade.dart';

class WeeklyStepsData {
  final List<Atividade> atividades;

  WeeklyStepsData({required this.atividades});

  List<IndividualBar> barData = [];

  void initializeBarData() {
    barData = List.generate(7, (index) {
      // Preenche com dados reais ou 0 se não houver dados
      int passos = 0;
      DateTime diaReferencia = DateTime.now().subtract(Duration(days: 6 - index));
      DateTime diaInicio = DateTime(diaReferencia.year, diaReferencia.month, diaReferencia.day);

      // Busca atividade correspondente ao dia
      for (var atividade in atividades) {
        DateTime atividadeDia = DateTime(
          atividade.data.year,
          atividade.data.month,
          atividade.data.day,
        );

        if (atividadeDia.isAtSameMomentAs(diaInicio)) {
          passos = atividade.passos;
          break;
        }
      }

      return IndividualBar(x: index.toDouble(), y: passos.toDouble());
    });
  }
}