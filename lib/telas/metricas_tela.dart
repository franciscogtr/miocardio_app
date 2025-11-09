import 'package:flutter/material.dart';
import 'package:miocardio_app/bargraph/activity_graph.dart';
import 'package:miocardio_app/bargraph/bpm_graph.dart';
import 'package:miocardio_app/repos/pedometer_repository.dart';
import 'package:miocardio_app/repos/cardio_repository.dart';

import 'package:provider/provider.dart';

class MetricasTela extends StatefulWidget {
  const MetricasTela({super.key});

  @override
  State<MetricasTela> createState() => _MetricasTelaState();
}

class _MetricasTelaState extends State<MetricasTela> {
  @override
  void initState() {
    super.initState();
    // Carrega os dados ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<pedometerRepository>().getUltimasSeteHoras();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Cabeçalho da tela
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suas Métricas',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hoje',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  // Botão de atualizar
                  IconButton(
                    icon: Icon(Icons.refresh, size: 28),
                    onPressed: () {
                      context.read<pedometerRepository>().getUltimasSeteHoras();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dados atualizados!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.03),

              // ✅ Cards de estatísticas resumidas
              Consumer<pedometerRepository>(
                builder: (context, repository, child) {
                  int totalPassos = repository.ultimasSeteHoras
                      .fold(0, (sum, atividade) => sum + atividade.passos);

                  int horasAtivas = repository.ultimasSeteHoras.length;

                  double mediaPassos = horasAtivas > 0
                      ? totalPassos / horasAtivas
                      : 0;

                  return Row(
                    children: [
                      // Card Total
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total',
                          value: totalPassos.toString(),
                          subtitle: 'passos hoje',
                          icon: Icons.directions_walk,
                          color: Color.fromARGB(255, 226, 21, 65),
                          screenHeight: screenHeight,
                        ),
                      ),
                      SizedBox(width: 12),
                      // Card Média
                      Expanded(
                        child: _buildStatCard(
                          title: 'Média',
                          value: mediaPassos.toInt().toString(),
                          subtitle: 'passos/hora',
                          icon: Icons.trending_up,
                          color: Colors.blue,
                          screenHeight: screenHeight,
                        ),
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: screenHeight * 0.03),

              // ✅ Título do gráfico
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/footsteps.png',
                      color: Color.fromARGB(255, 226, 21, 65),
                      width: screenWidth * 0.06,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Últimas 7 horas",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // ✅ Gráfico
              Container(
                height: screenHeight * 0.35,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xff161616),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: MyActivityGraph(),
              ),

              // Adicione esta seção após o gráfico de passos na MetricasTela

              SizedBox(height: screenHeight * 0.03),

// ✅ Título do gráfico de BPM
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Color.fromARGB(255, 226, 21, 65),
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Aferições hoje",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

// ✅ Cards de estatísticas de BPM
              Consumer<cardioRepository>(
                builder: (context, cardioRepo, child) {
                  if (cardioRepo.afericoesHoje.isEmpty) {
                    return Container(
                      height: screenHeight * 0.15,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xff161616),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Nenhuma aferição hoje',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  int menorBpm = cardioRepo.afericoesHoje
                      .map((a) => a.bpm)
                      .reduce((a, b) => a < b ? a : b);

                  int maiorBpm = cardioRepo.afericoesHoje
                      .map((a) => a.bpm)
                      .reduce((a,b) => a > b ? a : b);

                  double medioBpm = cardioRepo.afericoesHoje
                      .map((a) => a.bpm)
                      .reduce((a, b) => a + b) / cardioRepo.afericoesHoje.length;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Menor',
                          value: menorBpm.toString(),
                          subtitle: 'bpm',
                          icon: Icons.arrow_downward,
                          color: Colors.blue,
                          screenHeight: screenHeight,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Médio',
                          value: medioBpm.toInt().toString(),
                          subtitle: 'bpm',
                          icon: Icons.favorite,
                          color: Colors.green,
                          screenHeight: screenHeight,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Maior',
                          value: maiorBpm.toString(),
                          subtitle: 'bpm',
                          icon: Icons.arrow_upward,
                          color: Color.fromARGB(255, 226, 21, 65),
                          screenHeight: screenHeight,
                        ),
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: screenHeight * 0.02),

// ✅ Gráfico de BPM
              Container(
                height: screenHeight * 0.35,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xff161616),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: BpmLineGraph(),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Substituir a seção de "Lista detalhada de horas"
                // ✅ Lista detalhada de TODAS as horas do dia
              Consumer<pedometerRepository>(
                builder: (context, repository, child) {
                  // ✅ MUDANÇA: Usa atividadesHoje em vez de ultimasSeteHoras
                  if (repository.atividadesHoje.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma atividade hoje',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Detalhes Hora a Hora',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${repository.atividadesHoje.length} horas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: repository.atividadesHoje.length,
                        itemBuilder: (context, index) {
                          final atividade = repository.atividadesHoje[index];

                          return _buildActivityListItem(
                            atividade: atividade,
                            screenWidth: screenWidth,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Widget para cards de estatísticas
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double screenHeight,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xff161616),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget para item da lista de atividades
  Widget _buildActivityListItem({
    required atividade,
    required double screenWidth,
  }) {
    // Determina intensidade com base nos passos
    String intensidade;
    Color corIntensidade;

    if (atividade.passos < 300) {
      intensidade = 'Leve';
      corIntensidade = Colors.green;
    } else if (atividade.passos < 600) {
      intensidade = 'Moderado';
      corIntensidade = Colors.orange;
    } else {
      intensidade = 'Intenso';
      corIntensidade = Color.fromARGB(255, 226, 21, 65);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xff161616),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Hora
          Container(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${atividade.data.hour}h',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${atividade.data.minute.toString().padLeft(2, '0')}m',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16),

          // Barra de progresso visual
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${atividade.passos} passos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        intensidade,
                        style: TextStyle(
                          fontSize: 12,
                          color: corIntensidade,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (atividade.passos / 1000).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(corIntensidade),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}