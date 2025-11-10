import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:async';
import 'package:daily_pedometer2/daily_pedometer2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:miocardio_app/repos/pedometer_repository.dart';
import 'package:provider/provider.dart';
import 'package:miocardio_app/bargraph/activity_graph.dart';
import 'package:miocardio_app/repos/cardio_repository.dart';

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

class AtividadeTela extends StatefulWidget {
  const AtividadeTela({super.key});

  @override
  State<AtividadeTela> createState() => _AtividadeTelaState();
}

class _AtividadeTelaState extends State<AtividadeTela> {
  late Stream<StepCount> _dailyStepCountStream;
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  StreamSubscription<StepCount>? _dailyStepCountSubscription;
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  String _status = 'parado', _steps = '0', _dailySteps = '0';
  String _dailyDistance = '0';
  String _ritmoAtual = 'Indefinido';
  Color _colorRitmoAtual = Colors.blue;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onDailyStepCount(StepCount event) {
    if (!mounted) return;

    // ✅ Chama métodos do repository
    final repository = context.read<pedometerRepository>();
    repository.calcRitmo(event);
    repository.agrupaHora(event);

    int totalPassos = repository.atividadesHoje.fold(0, (sum, atividade) => sum + atividade.passos);
    String ritmo = repository.ritmoAtual;

    setState(() {
      //_dailySteps = event.steps.toString();
      _dailySteps = totalPassos.toString();
      double distance = totalPassos * (1.7 * 0.415);
      _dailyDistance = distance.toInt().toString();
      _ritmoAtual = ritmo;
      if(_ritmoAtual == 'Leve'){
        _colorRitmoAtual = Colors.blue;
      }
      if(_ritmoAtual == 'Moderado'){
        _colorRitmoAtual = Colors.orange;
      }
      if(_ritmoAtual == 'Intenso'){
        _colorRitmoAtual = Color.fromARGB(255, 226, 21, 65);
      }
    });
  }

  void onStepCount(StepCount event) {
    if (!mounted) return;
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    if (!mounted) return;
    setState(() {
      if(event.status == 'walking') {
        _status = 'em movimento';
      }
      else{
        _status = 'parado';
      }
    });
  }

  void onPedestrianStatusError(error) {
    if (!mounted) return;
    setState(() {
      _status = 'Status do Pedestre não disponível';
    });
  }

  void onStepCountError(error) {
    if (!mounted) return;
    setState(() {
      _steps = 'Pedometro não disponível';
    });
  }

  void onDailyStepCountError(error) {
    if (!mounted) return;
    setState(() {
      _dailySteps = '????';
    });
  }


  void initPlatformState() async {
    log('INITIALIZING THE STREAMS');

    if (await Permission.activityRecognition.isDenied) {
      await Permission.activityRecognition.request();
    }
    if (!await Permission.activityRecognition.isGranted) return;

    _pedestrianStatusStream = DailyPedometer2.pedestrianStatusStream;
    _pedestrianStatusSubscription = _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
      ..onError(onPedestrianStatusError);

    _stepCountStream = DailyPedometer2.stepCountStream;
    _stepCountSubscription = _stepCountStream
        .listen(onStepCount)
      ..onError(onStepCountError);

    _dailyStepCountStream = DailyPedometer2.dailyStepCountStream;
    _dailyStepCountSubscription = _dailyStepCountStream
        .listen(onDailyStepCount)
      ..onError(onDailyStepCountError);

    if (!mounted) return;
  }

  @override
  void dispose() {
    _dailyStepCountSubscription?.cancel();
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    super.dispose();
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

              /* IconButton(
                icon: Icon(Icons.bug_report, color: Colors.orange),
                onPressed: () async {
                  await context.read<pedometerRepository>().limparTodosDados();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passos de teste adicionados!')),
                  );
                },
              ),*/

              // ✅ Cabeçalho da tela
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, Francisco!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Minhas Métricas',
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

              /*Row(
                children: [
                  // Card Distância
                  Expanded(
                    child: _buildStatCard(
                      title: 'Passos',
                      value: _dailySteps,
                      subtitle: 'hoje',
                      icon: Icons.directions_walk,
                      color: Color.fromARGB(255, 226, 21, 65),
                      screenHeight: screenHeight,
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.0125),*/

              Row(
                    children: [
                      // Card Distância
                      Expanded(
                        child: _buildStatCard(
                          title: 'Distância',
                          value: _dailyDistance,
                          subtitle: 'metros',
                          icon: Icons.directions_walk,
                          color: Color.fromARGB(255, 226, 21, 65),
                          screenHeight: screenHeight,
                        ),
                      ),
                      SizedBox(width: 12),
                      // Card Ritmo atual
                      Expanded(
                        child: _buildStatCard(
                          title: 'Ritmo Atual',
                          value: _ritmoAtual,
                          subtitle: _status,
                          icon: Icons.trending_up,
                          color: _colorRitmoAtual,
                          screenHeight: screenHeight,
                        ),
                      ),
                    ],
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
                      "Passos por Hora",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

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
                      SizedBox(height: screenHeight * 0.03),
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

    if (atividade.passos < 1600) {
      intensidade = 'Leve';
      corIntensidade = Colors.green;
    } else if (atividade.passos < 3000) {
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
                    value: (atividade.passos / 3000).clamp(0.0, 1.0),
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
