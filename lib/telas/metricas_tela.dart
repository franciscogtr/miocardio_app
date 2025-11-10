import 'package:flutter/material.dart';
import 'package:miocardio_app/bargraph/weekly_activity_graph.dart';
import 'package:miocardio_app/bargraph/weekly_bpm_graph.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosSemanais();
    });
  }

  void _carregarDadosSemanais() {
    context.read<pedometerRepository>().getAtividadesSemanais();
    context.read<cardioRepository>().getAfericoesSemanais();
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
              // ✅ Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minhas Métricas',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Últimos 7 dias',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, size: 28),
                    onPressed: () {
                      _carregarDadosSemanais();
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

              // ✅ Cards de estatísticas - Passos
              Consumer<pedometerRepository>(
                builder: (context, repository, child) {
                  int totalPassos = repository.getTotalPassosSemana();
                  double mediaPassos = repository.getMediaPassosDia();
                  double distanciaTotal = repository.getDistanciaTotalSemana();

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total',
                              value: totalPassos.toString(),
                              subtitle: 'passos',
                              icon: Icons.directions_walk,
                              color: Color.fromARGB(255, 226, 21, 65),
                              screenHeight: screenHeight,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Distância',
                              value: '${(distanciaTotal / 1000).toStringAsFixed(1)} km',
                              subtitle: 'percorridos',
                              icon: Icons.location_on,
                              color: Color.fromARGB(255, 226, 21, 65),
                              screenHeight: screenHeight,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Média Diária',
                              value: mediaPassos.toInt().toString(),
                              subtitle: 'passos/dia',
                              icon: Icons.analytics_outlined,
                              color: Colors.blue,
                              screenHeight: screenHeight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: screenHeight * 0.03),

              // ✅ Gráfico de passos semanais
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
                      "Passos Diários",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              Container(
                height: screenHeight * 0.35,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xff161616),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: WeeklyStepsGraph(),
              ),

              SizedBox(height: screenHeight * 0.03),

              // ✅ Detalhes dia a dia - Passos
              Consumer<pedometerRepository>(
                builder: (context, repository, child) {
                  if (repository.atividadesSemanais.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma atividade esta semana',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
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
                              'Detalhes Diários',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${repository.atividadesSemanais.length} dias',
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
                        itemCount: repository.atividadesSemanais.length,
                        itemBuilder: (context, index) {
                          final atividade = repository.atividadesSemanais[index];
                          return _buildDailyActivityItem(
                            atividade: atividade,
                            screenWidth: screenWidth,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: screenHeight * 0.03),

              // ✅ Cards de estatísticas - BPM
              Consumer<cardioRepository>(
                builder: (context, cardioRepo, child) {
                  if (cardioRepo.afericoesSemanais.isEmpty) {
                    return Container(
                      height: screenHeight * 0.15,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xff161616),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Nenhuma aferição esta semana',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  int menorBpm = cardioRepo.getMenorBpmSemana();
                  int maiorBpm = cardioRepo.getMaiorBpmSemana();
                  double medioBpm = cardioRepo.getBpmMedioSemana();

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
                      "Aferições Semanais",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                child: WeeklyBpmGraph(),
              ),

              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildDailyActivityItem({
    required atividade,
    required double screenWidth,
  }) {
    String intensidade;
    Color corIntensidade;

    // Meta diária: 10.000 passos
    if (atividade.passos < 5000) {
      intensidade = 'Baixo';
      corIntensidade = Colors.blue;
    } else if (atividade.passos < 10000) {
      intensidade = 'Moderado';
      corIntensidade = Colors.orange;
    } else {
      intensidade = 'Excelente';
      corIntensidade = Colors.green;
    }

    final dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    String diaSemana = dias[atividade.data.weekday % 7];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xff161616),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diaSemana,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${atividade.data.day}/${atividade.data.month}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
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
                    Text(
                      intensidade,
                      style: TextStyle(
                        fontSize: 12,
                        color: corIntensidade,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (atividade.passos / 10000).clamp(0.0, 1.0),
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