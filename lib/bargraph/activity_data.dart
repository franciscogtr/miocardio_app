import 'package:miocardio_app/model/atividade.dart';

import 'package:flutter/cupertino.dart';

class IndividualBar {
  final double x; //position on horizontal axis
  final double y;//position on vertical axis

  IndividualBar({required this.x, required this.y});
}


class BarData {
  List<Atividade> atividades;

  BarData({required this.atividades});

  List<IndividualBar> barData = [];

  // Inicializa barras com dados reais das últimas 7 horas
  void initializedBarData() {
    barData.clear();

    // Se não tiver 7 horas de dados, preenche com zeros
    for (int i = 0; i < 7; i++) {
      if (i < atividades.length) {
        barData.add(IndividualBar(
            x: i.toDouble(),
            y: atividades[i].passos.toDouble()
        ));
      } else {
        barData.add(IndividualBar(x: i.toDouble(), y: 0));
      }
    }

    print("📊 Gráfico inicializado com ${barData.length} barras");
  }

  // Retorna o valor máximo para ajustar a escala do gráfico
  double getMaxY() {
    if (atividades.isEmpty) return 1000;

    double max = atividades
        .map((a) => a.passos.toDouble())
        .reduce((a, b) => a > b ? a : b);

    // Adiciona 20% de margem superior
    return max * 1.2;
  }
}