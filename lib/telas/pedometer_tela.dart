import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:async';
import 'package:daily_pedometer2/daily_pedometer2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:miocardio_app/repos/pedometer_repository.dart';
import 'package:provider/provider.dart';

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

class PedometerTela extends StatefulWidget {
  const PedometerTela({super.key});

  @override
  State<PedometerTela> createState() => _PedometerTelaState();
}

class _PedometerTelaState extends State<PedometerTela> {
  late Stream<StepCount> _dailyStepCountStream;
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  StreamSubscription<StepCount>? _dailyStepCountSubscription;
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  String _status = ' ', _steps = '0', _dailySteps = '0';
  String _dailyDistance = '0';

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

    setState(() {
      _dailySteps = event.steps.toString();
      double distance = event.steps.toDouble() * (1.7 * 0.415);
      _dailyDistance = distance.toInt().toString();
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
      _status = event.status;
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.02),

             /* IconButton(
                icon: Icon(Icons.bug_report, color: Colors.orange),
                onPressed: () async {
                  await context.read<pedometerRepository>().testarSalvamento();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Aferições de teste adicionadas!')),
                  );
                },
              ),*/

              // Container circular principal
              Container(
                width: screenWidth * 0.7,
                height: screenWidth * 0.7,
                padding: EdgeInsets.all(screenWidth * 0.08),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xff161616),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Image.asset(
                              'assets/images/footsteps.png',
                              color: Color.fromARGB(255, 226, 21, 65),
                              width: screenWidth * 0.1,
                            ),
                            SizedBox(height: 2),
                            Text("Hoje", style: TextStyle(fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      _dailySteps,
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    _status == 'walking'
                        ? Text(
                      "Movendo-se",
                      style: TextStyle(fontSize: 20),
                    )
                        : Text(
                      "Parado",
                      style: TextStyle(fontSize: 20),
                    )
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Card Distância
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.02,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  color: Color(0xff161616),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Distância", style: TextStyle(fontSize: 16)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _dailyDistance,
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text("m", style: TextStyle(fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/distance.png',
                      height: screenHeight * 0.13,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // ✅ Card Ritmo Atual - agora usa Consumer
              Consumer<pedometerRepository>(
                builder: (context, repository, child) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.02,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      color: Color(0xff161616),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Rítmo atual",
                                  style: TextStyle(fontSize: 16)),
                              Text(
                                repository.ritmoAtual,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/images/instrucoes.png',
                          height: screenHeight * 0.08,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
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
}