import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/bench_result.dart';
import '../models/product.dart';
import '../services/fps_monitor.dart';
import '../services/isolate_service.dart';
import '../services/json_service.dart';

class IsolateDemo extends StatefulWidget {
  const IsolateDemo({super.key});

  @override
  State<IsolateDemo> createState() => _IsolateDemoState();
}

class _IsolateDemoState extends State<IsolateDemo>
    with SingleTickerProviderStateMixin {
  static const int itemCount = 130000;

  late final AnimationController _spin;
  final FpsMonitor _fps = FpsMonitor();

  String? _json;
  double _jsonMiB = 0;
  bool _busy = false;

  String _status = 'Bấm "Tạo JSON" trước.';
  final List<BenchResult> _results = [];

  @override
  void initState() {
    super.initState();

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _fps.start();
  }

  @override
  void dispose() {
    _spin.dispose();
    _fps.dispose();
    super.dispose();
  }

  // Tạo dữ liệu bằng compute để không chặn UI.
  Future<void> _generate() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _status = 'Đang tạo JSON...';
      _results.clear();
    });

    try {
      final json = await compute(generateJson, itemCount);
      final size = getJsonSizeMiB(json);

      if (!mounted) return;

      setState(() {
        _json = json;
        _jsonMiB = size;
        _status = size > 15
            ? 'JSON đã sẵn sàng, lớn hơn 15 MiB.'
            : 'JSON chưa đạt 15 MiB. Hãy tăng itemCount.';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Lỗi tạo JSON: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // Chạy và đo một phương pháp.
  Future<void> _run(
    String label,
    Future<List<Product>> Function(String) task,
  ) async {
    if (_json == null || _busy || _jsonMiB <= 15) return;

    setState(() {
      _busy = true;
      _status = 'Đang chạy $label...';
    });

    final watch = Stopwatch();
    bool sessionEnded = false;

    try {
      // Cho giao diện kịp hiển thị trạng thái.
      await WidgetsBinding.instance.endOfFrame;

      _fps.beginSession();
      watch.start();

      final data = await task(_json!);

      // Chờ frame sau khi tác vụ hoàn tất.
      await WidgetsBinding.instance.endOfFrame;

      watch.stop();

      final (avg, gap) =
          _fps.endSession(watch.elapsedMicroseconds);
      sessionEnded = true;

      if (!mounted) return;

      setState(() {
        _results.insert(
          0,
          BenchResult(
            label: label,
            ms: watch.elapsedMilliseconds,
            avgFps: avg,
            maxGapMs: gap,
            count: data.length,
          ),
        );

        _status = 'Hoàn thành: $label';
      });
    } catch (e) {
      watch.stop();

      if (!sessionEnded) {
        _fps.endSession(watch.elapsedMicroseconds);
      }

      if (mounted) {
        setState(() => _status = 'Lỗi khi chạy $label: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<List<Product>> _runMain(String json) async {
    return parseProducts(json);
  }

  Future<List<Product>> _runCompute(String json) {
    return compute(parseProducts, json);
  }

  Future<List<Product>> _runIsolate(String json) {
    return parseWithIsolate(json);
  }

  @override
  Widget build(BuildContext context) {
    final canTest =
        !_busy && _json != null && _jsonMiB > 15;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Isolate vs Main Thread'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RotationTransition(
                  turns: _spin,
                  child: const Icon(
                    Icons.autorenew,
                    size: 56,
                    color: Colors.indigo,
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _fps.live,
                  builder: (context, value, child) {
                    final color = value >= 50
                        ? Colors.green
                        : value >= 30
                            ? Colors.orange
                            : Colors.red;

                    return Column(
                      children: [
                        Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const Text('FPS hiện tại'),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Dung lượng JSON: ${_jsonMiB.toStringAsFixed(2)} MiB'),
            const SizedBox(height: 8),
            Text(_status),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: _busy ? null : _generate,
                  child: const Text('0. Tạo JSON >15 MiB'),
                ),
                FilledButton(
                  onPressed: canTest
                      ? () => _run('Main Thread', _runMain)
                      : null,
                  child: const Text('1. Main Thread'),
                ),
                FilledButton(
                  onPressed: canTest
                      ? () => _run('compute()', _runCompute)
                      : null,
                  child: const Text('2. compute()'),
                ),
                FilledButton(
                  onPressed: canTest
                      ? () => _run('Isolate.spawn + Port', _runIsolate)
                      : null,
                  child: const Text('3. Isolate + Port'),
                ),
              ],
            ),

            const Divider(height: 24),

            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text('Kết quả kiểm thử sẽ hiển thị ở đây.'),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];

                        return Card(
                          child: ListTile(
                            title: Text(result.label),
                            subtitle: Text(
                              'Thời gian: ${result.ms} ms\n'
                              'Số bản ghi: ${result.count}\n'
                              'FPS trung bình: '
                              '${result.avgFps.toStringAsFixed(1)}\n'
                              'Khoảng ngắt frame lớn nhất: '
                              '${result.maxGapMs.toStringAsFixed(1)} ms',
                            ),
                            isThreeLine: true,
                            leading: Icon(
                              result.avgFps >= 40
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color: result.avgFps >= 40
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}