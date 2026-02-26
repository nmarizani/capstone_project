class PpgSample {
  final int timestampMs;
  final double value;
  final String channel;
  final String source;

  PpgSample({
    required this.timestampMs,
    required this.value,
    required this.channel,
    required this.source,
  });
}