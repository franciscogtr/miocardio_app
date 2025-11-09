import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:heart_image/heart_image.dart';

/// Class to store one sample data point
class SensorValue {
  /// timestamp of datapoint
  final DateTime time;

  /// value of datapoint
  final num value;

  SensorValue({required this.time, required this.value});

  /// Returns JSON mapped data point
  Map<String, dynamic> toJSON() => {'time': time, 'value': value};

  /// Map a list of data samples to a JSON formatted array.
  ///
  /// Map a list of [data] samples to a JSON formatted array. This is
  /// particularly useful to store [data] to database.
  static List<Map<String, dynamic>> toJSONArray(List<SensorValue> data) =>
      List.generate(data.length, (index) => data[index].toJSON());
}

/// Obtains heart beats per minute using camera sensor
///
/// Using the smartphone camera, the widget estimates the skin tone variations
/// over time. These variations are due to the blood flow in the arteries
/// present below the skin of the fingertips.
// ignore: must_be_immutable
class HeartBPMDialog extends StatefulWidget {
  /// This is the Loading widget, A developer has to customize it.
  final Widget? centerLoadingWidget;
  final double? cameraWidgetHeight;
  final double? cameraWidgetWidth;
  bool? showTextValues = false;
  final double? borderRadius;

  /// Callback used to notify the caller of updated BPM measurement
  ///
  /// Should be non-blocking as it can affect
  final void Function(int) onBPM;
  final Function(bool)? onFingerDetected; // 🔹 callback para dedo

  final Function(String)? onFingerState; // 🔹 callback para dedo
  /// Callback used to notify the caller of updated raw data sample
  ///
  /// Should be non-blocking as it can affect
  final void Function(SensorValue)? onRawData;

  /// Camera sampling rate in milliseconds
  final int sampleDelay;

  /// Parent context
  final BuildContext context;

  /// Smoothing factor
  ///
  /// Factor used to compute exponential moving average of the realtime data
  /// using the formula:
  /// ```
  /// $y_n = alpha * x_n + (1 - alpha) * y_{n-1}$
  /// ```
  double alpha = 0.6;

  /// Additional child widget to display
  final Widget? child;

  /// Use only green channel for better accuracy
  final bool useGreenChannel;

  /// Obtains heart beats per minute using camera sensor
  ///
  /// Using the smartphone camera, the widget estimates the skin tone variations
  /// over time. These variations are due to the blood flow in the arteries
  /// present below the skin of the fingertips.
  ///
  /// This is a [Dialog] widget and hence needs to be displayer using [showDialog]
  /// function. For example:
  /// ```
  /// await showDialog(
  ///   context: context,
  ///   builder: (context) => HeartBPMDialog(
  ///     onData: (value) => print(value),
  ///   ),
  /// );
  /// ```
  HeartBPMDialog({
    Key? key,
    required this.context,
    this.sampleDelay = 2000 ~/ 30,
    required this.onBPM,
    this.onRawData,
    this.alpha = 0.6,
    this.child,
    this.centerLoadingWidget,
    this.cameraWidgetHeight,
    this.cameraWidgetWidth,
    this.showTextValues,
    this.borderRadius,
    this.useGreenChannel = true,
    this.onFingerDetected,
    this.onFingerState,
  });

  /// Set the smoothing factor for exponential averaging
  ///
  /// the scaling factor [alpha] is used to compute exponential moving average of the
  /// realtime data using the formula:
  /// ```
  /// $y_n = alpha * x_n + (1 - alpha) * y_{n-1}$
  /// ```
  void setAlpha(double a) {
    if (a <= 0)
      throw Exception(
        "$HeartBPMDialog: smoothing factor cannot be 0 or negative",
      );
    if (a > 1)
      throw Exception(
        "$HeartBPMDialog: smoothing factor cannot be greater than 1",
      );
    alpha = a;
  }

  @override
  _HeartBPPView createState() => _HeartBPPView();
}

class _HeartBPPView extends State<HeartBPMDialog> {
  /// Camera controller
  CameraController? _controller;

  /// Used to set sampling rate
  bool _processing = false;

  /// Current value
  int currentValue = 0;

  /// to ensure camara was initialized
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void dispose() {
    _deinitController();
    super.dispose();
  }

  /// Deinitialize the camera controller
  void _deinitController() async {
    isCameraInitialized = false;
    if (_controller == null) return;
    await _controller!.dispose();
  }

  /// Initialize the camera controller
  ///
  /// Function to initialize the camera controller and start data collection.
  Future<void> _initController() async {
    if (_controller != null) return;
    try {
      // 1. get list of all available cameras
      List<CameraDescription> _cameras = await availableCameras();
      // 2. assign the preferred camera with low resolution and disable audio
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      // 3. initialize the camera
      await _controller!.initialize();

      // 4. set torch to ON and start image stream
      Future.delayed(
        Duration(milliseconds: 500),
      ).then((value) => _controller!.setFlashMode(FlashMode.torch));

      // 5. register image streaming callback
      _controller!.startImageStream((image) {
        if (!_processing && mounted) {
          _processing = true;
          _scanImage(image);
        }
      });

      setState(() {
        isCameraInitialized = true;
      });
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static const int windowLength = 150;

  final Queue<SensorValue> measureWindow = Queue<SensorValue>();

  /// 🔴 NOVA: Extrai intensidade do canal VERMELHO de YUV420
  double _extractRedChannel(CameraImage image) {
    final Uint8List yPlane = image.planes[0].bytes;
    final Uint8List uPlane = image.planes[1].bytes;
    final Uint8List vPlane = image.planes[2].bytes;

    final int width = image.width;
    final int height = image.height;

    // Amostra da região central (onde o dedo deve estar)
    final int centerX = width ~/ 2;
    final int centerY = height ~/ 2;
    final int sampleSize = 65;

    double redSum = 0;
    int pixelCount = 0;

    for (int y = centerY - sampleSize ~/ 2; y < centerY + sampleSize ~/ 2; y++) {
      for (int x = centerX - sampleSize ~/ 2; x < centerX + sampleSize ~/ 2; x++) {
        if (y >= 0 && y < height && x >= 0 && x < width) {
          int yIndex = y * width + x;

          // UV planes têm metade da resolução (subsampling 4:2:0)
          int uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

          if (yIndex < yPlane.length && uvIndex < uPlane.length && uvIndex < vPlane.length) {
            // Conversão YUV -> RGB (simplificada)
            // R = Y + 1.402 * (V - 128)
            double yVal = yPlane[yIndex].toDouble();
            double vVal = vPlane[uvIndex].toDouble();

            double red = yVal + 1.402 * (vVal - 128);
            red = red.clamp(0, 255);

            redSum += red;
            pixelCount++;
          }
        }
      }
    }

    return pixelCount > 0 ? redSum / pixelCount : 0.0;
  }

  /// Extract green channel values from YUV420 camera image
  double _extractGreenChannel(CameraImage image) {
    final Uint8List yPlane = image.planes[0].bytes;
    final Uint8List uPlane = image.planes[1].bytes;
    final Uint8List vPlane = image.planes[2].bytes;

    final int width = image.width;
    final int height = image.height;

    final int centerX = width ~/ 2;
    final int centerY = height ~/ 2;
    final int sampleSize = 65;

    double greenSum = 0;
    int pixelCount = 0;

    for (int y = centerY - sampleSize ~/ 2; y < centerY + sampleSize ~/ 2; y++) {
      for (int x = centerX - sampleSize ~/ 2; x < centerX + sampleSize ~/ 2; x++) {
        if (y >= 0 && y < height && x >= 0 && x < width) {
          int yIndex = y * width + x;
          int uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

          if (yIndex < yPlane.length && uvIndex < uPlane.length && uvIndex < vPlane.length) {
            // G = Y - 0.344 * (U - 128) - 0.714 * (V - 128)
            double yVal = yPlane[yIndex].toDouble();
            double uVal = uPlane[uvIndex].toDouble();
            double vVal = vPlane[uvIndex].toDouble();

            double green = yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128);
            green = green.clamp(0, 255);

            greenSum += green;
            pixelCount++;
          }
        }
      }
    }

    return pixelCount > 0 ? greenSum / pixelCount : 0.0;
  }

  /// 🔴 NOVA: Detecta dedo baseado na intensidade do canal VERMELHO
  bool isFingerPlacedByRedChannel(double redIntensity) {
    // Threshold para considerar que o dedo está cobrindo a câmera
    // Valores típicos com flash ligado e dedo posicionado: 150-220
    // Sem dedo ou mal posicionado: < 100
    const double minRedIntensity = 130.0;

    if (redIntensity < minRedIntensity) {
      widget.onFingerState?.call(" Posicione o dedo sobre a câmera");
      return false;
    }

    return true;
  }

  List<double> normalizedBuffer = [];
  final int normalizationWindow = 100;
  bool fingerDetected = false;

  // Histórico de detecções para estabilidade
  final List<bool> _fingerDetectionHistory = [];
  static const int detectionHistoryLength = 10; // ~0.3s a 30fps
  static const int requiredPositiveDetections = 7; // 70% de certeza

  void _scanImage(CameraImage image) async {
    // 🔴 1. Extrai canal VERMELHO para detectar dedo
    double redValue = _extractRedChannel(image);

    // 🔴 2. Verifica se dedo está posicionado
    bool currentDetection = isFingerPlacedByRedChannel(redValue);

    // Adiciona ao histórico para estabilizar detecção
    _fingerDetectionHistory.add(currentDetection);
    if (_fingerDetectionHistory.length > detectionHistoryLength) {
      _fingerDetectionHistory.removeAt(0);
    }

    // Conta quantas detecções positivas há no histórico
    int positiveCount = _fingerDetectionHistory.where((x) => x).length;
    bool stableFingerDetection = positiveCount >= requiredPositiveDetections;

    // 3. Se dedo NÃO detectado, reseta e aguarda
    if (!stableFingerDetection) {
      if (fingerDetected) {
        // Mudou de detectado para não detectado
        fingerDetected = false;
        widget.onFingerDetected?.call(false);

        // Limpa buffer de medição
        measureWindow.clear();
        normalizedBuffer.clear();

        setState(() {
          currentValue = 0;
        });
        widget.onBPM(0);
      }

      // Libera processamento
      Future<void>.delayed(Duration(milliseconds: widget.sampleDelay)).then((onValue) {
        if (mounted) {
          setState(() {
            _processing = false;
          });
        }
      });
      return;
    }

    // 🟢 4. Dedo detectado! Notifica se for primeira vez
    if (!fingerDetected) {
      fingerDetected = true;
      widget.onFingerDetected?.call(true);
      widget.onFingerState?.call(" Aferindo Batimentos...");
    }

    // 5. Extrai valor para análise de BPM (verde ou luminância)
    double pixelValue;
    if (widget.useGreenChannel) {
      pixelValue = _extractGreenChannel(image);
    } else {
      // Usa luminância (plano Y)
      pixelValue = image.planes[0].bytes.reduce((a, b) => a + b) / image.planes[0].bytes.length;
    }

    // 6. Adiciona ao buffer de medição
    if (measureWindow.length >= windowLength) {
      measureWindow.removeFirst();
    }
    measureWindow.addLast(SensorValue(time: DateTime.now(), value: pixelValue));

    // 7. Normaliza e calcula BPM
    double normalizedValue = _normalizeCurrentValue(measureWindow);

    if (normalizedBuffer.length >= windowLength) {
      normalizedBuffer.removeAt(0);
    }
    normalizedBuffer.add(normalizedValue);

    _smoothBPM(normalizedValue).then((value) {
      widget.onRawData?.call(
        SensorValue(time: DateTime.now(), value: normalizedValue),
      );
    });

    // 8. Libera processamento após delay
    Future<void>.delayed(Duration(milliseconds: widget.sampleDelay)).then((onValue) {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    });
  }

  double _normalizeCurrentValue(Queue<SensorValue> data) {
    if (data.length < normalizationWindow) return 0.0;

    List<SensorValue> listData = data.toList();
    List<SensorValue> window = listData.sublist(
      data.length - normalizationWindow,
    );

    double minVal = window
        .map((e) => e.value.toDouble())
        .reduce((a, b) => a < b ? a : b);
    double maxVal = window
        .map((e) => e.value.toDouble())
        .reduce((a, b) => a > b ? a : b);
    double range = maxVal - minVal;

    if (range < 3.0) return 0.0;

    return (data.last.value.toDouble() - minVal) / range;
  }

  /// Smooth the raw measurements using Exponential averaging
  /// Nova função de cálculo de BPM com filtro + detecção de picos
  Future<int> _smoothBPM(double newValue) async {
    const int minWindowSize = 150;
    const int peakMinDistanceMs = 300;
    const int avgWindowSize = 5;

    double smoothedValue = movingAverage(measureWindow, avgWindowSize);

    if (measureWindow.length >= windowLength) {
      measureWindow.removeFirst();
    }
    measureWindow.addLast(
      SensorValue(time: DateTime.now(), value: smoothedValue),
    );

    if (measureWindow.length < minWindowSize) {
      return currentValue;
    }

    double localMean = movingAverage(measureWindow, avgWindowSize);
    double localStd = stdDeviation(measureWindow, avgWindowSize);

    List<int> peaks = [];
    double threshold = localMean + max(0.8 * localStd, 1.5);

    List<SensorValue> measureWindowList = measureWindow.toList();

    for (int i = 2; i < measureWindowList.length - 2; i++) {
      if (measureWindowList[i].value > threshold &&
          measureWindowList[i].value > measureWindowList[i - 1].value &&
          measureWindowList[i].value > measureWindowList[i + 1].value &&
          measureWindowList[i].value >= measureWindowList[i - 2].value &&
          measureWindowList[i].value >= measureWindowList[i + 2].value) {
        if (peaks.isEmpty ||
            measureWindowList[i].time.millisecondsSinceEpoch - peaks.last >
                peakMinDistanceMs) {
          peaks.add(measureWindowList[i].time.millisecondsSinceEpoch);
        }
      }
    }

    if (peaks.length < 2) {
      return currentValue;
    }

    List<int> intervals = [];
    for (int i = 1; i < peaks.length; i++) {
      intervals.add(peaks[i] - peaks[i - 1]);
    }

    double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    double bpm = 60000 / avgInterval;

    bpm = (1 - widget.alpha) * currentValue + widget.alpha * bpm;

    setState(() {
      currentValue = bpm.toInt();
    });

    widget.onBPM(currentValue);

    return currentValue;
  }

  double movingAverage(Queue<SensorValue> data, int windowSize) {
    List<SensorValue> listData = data.toList();

    if (listData.length < windowSize) return listData.last.value.toDouble();
    double sum = 0;
    for (int i = listData.length - windowSize; i < listData.length; i++) {
      sum += listData[i].value;
    }
    return sum / windowSize;
  }

  double stdDeviation(Queue<SensorValue> data, int windowSize) {
    if (data.length < windowSize) return 0.0;

    List<SensorValue> listData = data.toList();

    List<SensorValue> slice = listData.sublist(listData.length - windowSize);
    double mean = movingAverage(data, windowSize);

    double sumSq = 0;
    for (var e in slice) {
      sumSq += (e.value - mean) * (e.value - mean);
    }

    return sqrt((sumSq / slice.length).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isCameraInitialized
          ? Center(
        child: ClipPath(
          clipper: HeartClipp(),
          child: SizedBox(
            width: 150,
            height: 75,
            child: _controller!.buildPreview(),
          ),
        ),
      )
          : Center(
        child: widget.centerLoadingWidget != null
            ? widget.centerLoadingWidget
            : CircularProgressIndicator(),
      ),
    );
  }
}