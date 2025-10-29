import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miocardio_app/repos/cardio_repository.dart';
import 'package:miocardio_app/telas/instrucoes_tela.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:miocardio_app/packages/heart_bpm.dart';
import 'package:provider/provider.dart';

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
          // ✅ SOLUÇÃO: Remover mainAxisAlignment.spaceEvenly
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Instruction section
              if (!isMeasuring && finalBpm == null) ...[
                SizedBox(height: screenHeight * 0.01),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InstrucoesTela()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.02,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Color(0xff161616),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Instruções",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "de aferição",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Image.asset(
                          'assets/images/coracao.png',
                          height: screenHeight * 0.08,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenHeight * 0.02,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color(0xff161616),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ultima aferição",
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  medition,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.1,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text("bpm", style: TextStyle(fontSize: 15)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/lastmedition.png',
                        height: screenHeight * 0.06,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                GestureDetector(
                  onTap: updateAfericoes,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.02,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Color(0xff161616),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Medição por",
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              "Aparelho",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Image.asset(
                          'assets/images/oximeter.png',
                          height: screenHeight * 0.1,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                GestureDetector(
                  onTap: startMeasurement,
                  child: Container(
                    width: screenWidth * 0.5,
                    height: screenWidth * 0.5,
                    decoration: BoxDecoration(
                      color: Color(0xff161616),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/btnAferir.png',
                          height: screenWidth * 0.15,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Começar",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),
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

              // Buttons section
              if (isMeasuring) ...[

              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Helper methods
String _getBpmCategory(int bpm) {
  if (bpm < 60) return "Bradicardia (Baixo)";
  if (bpm <= 100) return "Normal";
  if (bpm <= 120) return "Levemente Elevado";
  return "Taquicardia (Elevado)";
}

Color _getBpmCategoryColor(int bpm) {
  if (bpm < 60) return Colors.blue;
  if (bpm <= 100) return Colors.green;
  if (bpm <= 120) return Colors.red;
  return const Color.fromARGB(255, 255, 17, 0);
}