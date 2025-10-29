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
  // final bool dedoAlinhado;

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
  // double currentValue = 0.0;

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
    this.useGreenChannel = true, // Por padrão usa canal verde
    this.onFingerDetected, // 🔹 callback para dedo
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
    // await _controller.stopImageStream();
    await _controller!.dispose();
    // while (_processing) {}
    // _controller = null;
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

  // static const int windowLength = 50;
  static const int windowLength = 150;

  final Queue<SensorValue> measureWindow = Queue<SensorValue>();

  /// Extract green channel values from YUV420 camera image
  double _extractGreenChannel(CameraImage image) {
    // YUV420 format: Y (luminance) plane contains brightness info
    // For green channel extraction from YUV, we focus on the Y plane
    // and apply a green-weighted filter

    final Uint8List yPlane = image.planes[0].bytes;
    final int width = image.width;
    final int height = image.height;

    // Sample from center region (more stable finger placement area)
    final int centerX = width ~/ 2;
    final int centerY = height ~/ 2;
    final int sampleSize = 65; // Sample 50x50 pixels from center

    double greenSum = 0;
    int pixelCount = 0;

    for (
    int y = centerY - sampleSize ~/ 2;
    y < centerY + sampleSize ~/ 2;
    y++
    ) {
      for (
      int x = centerX - sampleSize ~/ 2;
      x < centerX + sampleSize ~/ 2;
      x++
      ) {
        if (y >= 0 && y < height && x >= 0 && x < width) {
          int index = y * width + x;
          if (index < yPlane.length) {
            // For YUV420, Y plane represents luminance
            // We can approximate green channel contribution
            greenSum += yPlane[index].toDouble();
            pixelCount++;
          }
        }
      }
    }

    return pixelCount > 0 ? greenSum / pixelCount : 0.0;
  }

  /// Extract average brightness from all pixels (original method)
  double _extractAveragePixelValue(CameraImage image) {
    return image.planes.first.bytes.reduce(
          (value, element) => value + element,
    ) /
        image.planes.first.bytes.length;
  }

  final List<bool> _fingerDetectionHistory = [];

  bool isFingerPlaced(Queue<SensorValue> data) {
    if (data.isEmpty) return false;

    const int historyLength = 100; // últimos 50 valores (~1.5s a 30fps)
    const double minAvg = 68; // intensidade mínima para detectar dedo
    const double minVariance = 1.1; // variância mínima para detectar pulsação
    const int requiredPositiveRatio = 5; // número de confirmações no histórico

    // Seleciona últimos valores

    List<SensorValue> listData = data.toList();

    List<SensorValue> window = listData.length > historyLength
        ? listData.sublist(listData.length - historyLength)
        : listData;

    // Média e variância
    double avg =
        window.map((e) => e.value).reduce((a, b) => a + b) / window.length;
    double variance =
        window
            .map((e) => (e.value - avg) * (e.value - avg))
            .reduce((a, b) => a + b) /
            window.length;

    // Limites adaptativos
    double intensityThreshold = max(minAvg, avg * 0.6);
    double varianceThreshold = max(minVariance, variance * 0.4);

    if (variance < varianceThreshold) {
      widget.onFingerState?.call(" Pulsação não Identificada");
    }

    if (avg < intensityThreshold) {
      widget.onFingerState?.call(" Pouca Iluminação Ambiente");
    }

    bool currentDetection =
        avg > intensityThreshold && variance > varianceThreshold;

    // Histórico anti-oscilação
    _fingerDetectionHistory.add(currentDetection);
    if (_fingerDetectionHistory.length > historyLength) {
      _fingerDetectionHistory.removeAt(0);
    }

    int positiveCount = _fingerDetectionHistory.where((x) => x).length;

    return positiveCount >= requiredPositiveRatio;
  }

  List<double> normalizedBuffer = [];
  final int normalizationWindow = 100; // Janela para normalização
  bool fingerDetected = true; // Estado atual da detecção do dedo

  void _scanImage(CameraImage image) async {
    // 1. extrai valor do pixel (verde ou média)
    double pixelValue;
    if (widget.useGreenChannel) {
      pixelValue = _extractGreenChannel(image);
    } else {
      pixelValue = _extractAveragePixelValue(image);
    }

    double normalizeCurrentValue(Queue<SensorValue> data) {
      if (data.length < normalizationWindow) return 0.0;

      // Usa apenas os últimos N valores para normalização
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

      // Threshold mais realista baseado na variação esperada do sinal
      if (range < 3.0) return 0.0;

      return (data.last.value.toDouble() - minVal) / range;
    }

    // 2. adiciona no buffer
    // measureWindow.remove(0);
    // measureWindow.add(SensorValue(time: DateTime.now(), value: pixelValue));

    if (measureWindow.length >= windowLength) {
      measureWindow.removeFirst();
    }

    measureWindow.addLast(SensorValue(time: DateTime.now(), value: pixelValue));

    // Nova normalização melhorada
    if (!isFingerPlaced(measureWindow)) {
      if (widget.onFingerDetected != null) {
        fingerDetected = false;
        widget.onFingerDetected!(fingerDetected);
        // widget.onFingerState!("Dedo não detectado");
      }
      setState(() {
        currentValue = 0;
      });
      widget.onBPM(currentValue);
    } else {
      if (widget.onFingerDetected != null) {
        fingerDetected = true;
        widget.onFingerDetected!(fingerDetected);
        widget.onFingerState?.call(" Aferindo Batimentos...");
      }
      // Normalização com janela deslizante
      double normalizedValue = normalizeCurrentValue(measureWindow);

      // Atualiza buffer normalizado
      if (normalizedBuffer.length >= windowLength) {
        normalizedBuffer.removeAt(0);
      }
      normalizedBuffer.add(normalizedValue);

      _smoothBPM(normalizedValue).then((value) {
        widget.onRawData?.call(
          SensorValue(time: DateTime.now(), value: normalizedValue),
        );
      });
    }

    // 5. libera processamento após o delay configurado
    Future<void>.delayed(Duration(milliseconds: widget.sampleDelay)).then((
        onValue,
        ) {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    });
  }

  /// Smooth the raw measurements using Exponential averaging
  /// the scaling factor [alpha] is used to compute exponential moving average of the
  /// realtime data using the formula:
  /// ```
  /// $y_n = alpha * x_n + (1 - alpha) * y_{n-1}$
  /// ```

  /// Nova função de cálculo de BPM com filtro + detecção de picos
  Future<int> _smoothBPM(double newValue) async {
    // 1. parâmetros de estabilidade
    const int minWindowSize = 150; // ~5s a 30fps
    const int peakMinDistanceMs =
    300; // intervalo mínimo entre batidas (~200 bpm máx)
    const int avgWindowSize = 5; // média móvel simples para suavizar ruído

    // 2. aplica média móvel simples
    double smoothedValue = movingAverage(measureWindow, avgWindowSize);

    // 3. adiciona a nova amostra suavizada
    if (measureWindow.length >= windowLength) {
      measureWindow.removeFirst();
    }
    measureWindow.addLast(
      SensorValue(time: DateTime.now(), value: smoothedValue),
    );

    // só processa se tiver dados suficientes
    if (measureWindow.length < minWindowSize) {
      return currentValue;
    }

    // 4. detecta picos (máximos locais com intervalo mínimo)
    double localMean = movingAverage(measureWindow, avgWindowSize);
    double localStd = stdDeviation(measureWindow, avgWindowSize);

    List<int> peaks = [];
    double threshold = localMean + max(0.8 * localStd, 1.5);

    List<SensorValue> measureWindowList = measureWindow.toList();

    for (int i = 2; i < measureWindowList.length - 2; i++) {
      // Máximo local robusto + threshold
      if (measureWindowList[i].value > threshold &&
          measureWindowList[i].value > measureWindowList[i - 1].value &&
          measureWindowList[i].value > measureWindowList[i + 1].value &&
          measureWindowList[i].value >= measureWindowList[i - 2].value &&
          measureWindowList[i].value >= measureWindowList[i + 2].value) {
        // Distância mínima entre picos
        if (peaks.isEmpty ||
            measureWindowList[i].time.millisecondsSinceEpoch - peaks.last >
                peakMinDistanceMs) {
          peaks.add(measureWindowList[i].time.millisecondsSinceEpoch);
        }
      }
    }

    // precisa de pelo menos 2 picos para calcular intervalos
    if (peaks.length < 2) {
      return currentValue;
    }

    // 5. calcula intervalos RR (distância entre batidas)
    List<int> intervals = [];
    for (int i = 1; i < peaks.length; i++) {
      intervals.add(peaks[i] - peaks[i - 1]);
    }

    // média dos intervalos
    double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    // 6. converte para BPM
    double bpm = 60000 / avgInterval;

    // aplica suavização exponencial (EMA) para evitar oscilações bruscas
    bpm = (1 - widget.alpha) * currentValue + widget.alpha * bpm;

    // atualiza valor atual
    setState(() {
      currentValue = bpm.toInt();
    });

    widget.onBPM(currentValue);

    return currentValue;
  }

  /// Função auxiliar para média móvel simples
  double movingAverage(Queue<SensorValue> data, int windowSize) {
    List<SensorValue> listData = data.toList();

    if (listData.length < windowSize) return listData.last.value.toDouble();
    double sum = 0;
    for (int i = listData.length - windowSize; i < listData.length; i++) {
      sum += listData[i].value;
    }
    return sum / windowSize;
  }

  /// Desvio padrão simples
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
        /// A developer has to customize the loading widget (Implemented by Karl Mathuthu)
        child: widget.centerLoadingWidget != null
            ? widget.centerLoadingWidget
            : CircularProgressIndicator(),
      ),
    );
  }
}
