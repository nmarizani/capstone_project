import 'dart:async';
import 'dart:math';
import '../../domain/entities/ppg_sample.dart';
import '../../domain/services/ppg_data_source.dart';

class MockPpgDataSource implements PpgDataSource {
  StreamController<PpgSample>? _controller;
  Timer? _timer;
  double _t = 0;

  @override
  Stream<PpgSample> startStream() {
    _controller?.close();
    _controller = StreamController<PpgSample>.broadcast();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      _t += 0.04;
      final noise = (Random().nextDouble() - 0.5) * 0.05;
      final signal = 0.5 + 0.35 * sin(2 * pi * 1.6 * _t) + noise;

      _controller?.add(
        PpgSample(
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          value: signal,
          channel: 'ppg_ir',
          source: 'mock',
        ),
      );
    });

    return _controller!.stream;
  }

  @override
  Future<void> stopStream() async {
    _timer?.cancel();
    _timer = null;
    await _controller?.close();
    _controller = null;
  }

  @override
  Future<double?> getSignalQuality() async => 0.88;
}