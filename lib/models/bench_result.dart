class BenchResult {
  final String label;
  final int ms;
  final double avgFps;
  final double maxGapMs;
  final int count;

  const BenchResult({
    required this.label,
    required this.ms,
    required this.avgFps,
    required this.maxGapMs,
    required this.count,
  });
}