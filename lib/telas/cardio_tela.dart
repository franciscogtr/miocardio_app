import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miocardio_app/repos/cardio_repository.dart';
import 'package:miocardio_app/telas/instrucoes_tela.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:miocardio_app/packages/heart_bpm.dart';
import 'package:provider/provider.dart';
import 'package:miocardio_app/bargraph/bpm_graph.dart';


class CardioTela extends StatefulWidget {
  const CardioTela({super.key});

  @override
  State<CardioTela> createState() => _CardioTelaState();
}

class _CardioTelaState extends State<CardioTela> {
  List<SensorValue> data = [];
  int? bpmValue;
  int? finalBpm;
  bool isMeasuring = false;
  List<int> bpmValues = [];
  bool useGreenChannel = true;
  List<int> recentBpmValues = [];
  bool fingerDetected = false;
  double percent = 0.0;
  String fingerState = 'Dedo não detectado';
  String medition = '80';
  bool control = false;

  void startMeasurement() {
    setState(() {
      isMeasuring = true;
      fingerDetected = false;
      bpmValues.clear();
      finalBpm = null;
      data.clear();
      bpmValue = null;
      percent = 0.0;
      recentBpmValues.clear();
    });
  }

  void stopMeasurement() {
    setState(() {
      isMeasuring = false;
      finalBpm = null;
    });
  }

  updateAfericoes() async {
    final form = GlobalKey<FormState>();
    final bpm = TextEditingController();
    final afericoes = context.read<cardioRepository>();

    AlertDialog dialog = AlertDialog(
      backgroundColor: Color(0xff161616),
      title: Text('Inserir aferição'),
      content: Form(
        key: form,
        child: TextFormField(
          controller: bpm,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+$')),
          ],
          validator: (bpm) {
            if (bpm!.isEmpty) return 'Informe o valor da aferição';

            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancelar", style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              afericoes.setAfericao(int.parse(bpm.text), DateTime.now());
              Navigator.pop(context);
            }
          },
          child: Text("Salvar", style: TextStyle(color: Colors.white)),
        ),
      ],
    );

    showDialog(context: context, builder: (context) => dialog);
  }

  @override
  Widget build(BuildContext context) {
    final afericoes = context.watch<cardioRepository>();
    medition = afericoes.ultimaAfericao.toString();

    // ✅ Obter dimensões da tela
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    return SafeArea(
      // ✅ SOLUÇÃO: Adicionar SingleChildScrollView
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Instruction section
              if (!isMeasuring && finalBpm == null) ...[

                /*IconButton(
                  icon: Icon(Icons.bug_report, color: Colors.orange),
                  onPressed: () async {
                    await context.read<cardioRepository>().limparHistorico();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Aferições de teste adicionadas!')),
                    );
                  },
                ),*/
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoramento',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cardíaco',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    // Botão de instruções
                    IconButton(
                      icon: Icon(Icons.info_outline, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => InstrucoesTela()),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.03),

                // ✅ Cards de estatísticas (igual à AtividadeTela)
                if (!isMeasuring && finalBpm == null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Última Aferição',
                          value: medition,
                          subtitle: 'bpm',
                          icon: Icons.favorite,
                          color: Color.fromARGB(255, 226, 21, 65),
                          screenHeight: screenHeight,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Status',
                          value: _getBpmCategoryShort(int.tryParse(medition) ?? 0),
                          subtitle: 'cardíaco',
                          icon: Icons.monitor_heart,
                          color: _getBpmCategoryColor(int.tryParse(medition) ?? 0),
                          screenHeight: screenHeight,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // ✅ Botões de ação em cards
                  _buildActionCard(
                    title: 'Medição por',
                    subtitle: 'Câmera',
                    icon: Icons.camera_alt,
                    color: Color.fromARGB(255, 226, 21, 65),
                    onTap: startMeasurement,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  _buildActionCard(
                    title: 'Inserir medição',
                    subtitle: 'Manual',
                    icon: Icons.edit,
                    color: Colors.blue,
                    onTap: updateAfericoes,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                  ),
                ],

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

                SizedBox(height: screenHeight * 0.03),

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


                SizedBox(height: screenHeight * 0.015),


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


              ],

              // Display section
              if (isMeasuring && finalBpm == null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(height: screenHeight * 0.06),

                    CircularPercentIndicator(
                      backgroundColor: Color(0xff161616),
                      progressColor: Color.fromARGB(255, 226, 21, 65),
                      radius: screenWidth * 0.32,
                      lineWidth: screenWidth * 0.025,
                      percent: percent.clamp(0.0, 1.0),
                      center: Stack(
                        alignment: Alignment.center,
                        children: [
                          HeartBPMDialog(
                            context: context,
                            onRawData: (value) {
                              setState(() {
                                if (data.length >= 100) {
                                  data.removeAt(0);
                                }
                                data.add(value);
                              });
                            },
                            onBPM: (value) => setState(() {
                              if (value < 200 && value > 40) {
                                bpmValues.add(value);
                                recentBpmValues.add(value);

                                bpmValue =
                                    (recentBpmValues.reduce((a, b) => a + b) /
                                        recentBpmValues.length)
                                        .round();

                                percent = bpmValues.length / 150.0;
                              }

                              if (bpmValues.length >= 150) {
                                setState(() {
                                  isMeasuring = false;

                                  if (bpmValues.isNotEmpty) {
                                    finalBpm = bpmValue;
                                    afericoes.setAfericao(finalBpm!, DateTime.now());
                                    finalBpm = null;
                                    isMeasuring = false;
                                  }
                                });
                              }
                            }),
                            onFingerDetected: (detected) {
                              setState(() {
                                fingerDetected = detected;
                              });
                            },
                            onFingerState: (state) {
                              fingerState = state;
                            },
                          ),
                          if (bpmValue != null)
                            Positioned(
                              child: Text(
                                "$bpmValue",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    if (bpmValues.isEmpty)
                      Text(
                        "Calibrando câmera...",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                    if (bpmValues.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            fingerDetected ? Icons.fingerprint : Icons.error_outline,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            fingerState,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                    SizedBox(height: screenHeight * 0.12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color.fromARGB(255, 226, 21, 65),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.1,
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: stopMeasurement,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stop, size: screenWidth * 0.05),
                          SizedBox(width: 8),
                          Text(
                            "Cancelar",
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),

            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Widget de card de estatística (igual à AtividadeTela)
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

// ✅ Widget de card de ação
Widget _buildActionCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
  required double screenHeight,
  required double screenWidth,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xff161616),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    ),
  );
}


// Helper methods
String _getBpmCategory(int bpm) {
  if (bpm < 60) return "Bradicardia (Baixo)";
  if (bpm <= 100) return "Normal";
  if (bpm <= 120) return "Levemente Elevado";
  return "Taquicardia (Elevado)";
}

String _getBpmCategoryShort(int bpm) {
  if (bpm < 60) return "Baixo";
  if (bpm <= 100) return "Normal";
  if (bpm <= 120) return "Elevado";
  return "Muito Alto";
}

Color _getBpmCategoryColor(int bpm) {
  if (bpm < 60) return Colors.blue;
  if (bpm <= 100) return Colors.green;
  if (bpm <= 120) return Colors.orange;
  return Color.fromARGB(255, 226, 21, 65);
}
