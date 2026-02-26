import 'dart:async';
import '../entities/ppg_sample.dart';

abstract class PpgDataSource {
  Stream<PpgSample> startStream();
  Future<void> stopStream();
  Future<double?> getSignalQuality();
}