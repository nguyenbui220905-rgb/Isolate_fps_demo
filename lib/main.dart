// Demo: Đa luồng với Isolates - so sánh FPS giữa Main Thread và Isolate
// Chạy: flutter run --profile
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const MaterialApp(home: IsolateDemo()));

// ───────────────────────── Model & hàm top-level ─────────────────────────
class Product {
  final int id;
  final String name;
  final double price;
  Product(this.id, this.name, this.price);
  factory Product.fromJson(Map<String, dynamic> j) =>
      Product(j['id'] as int, j['name'] as String, (j['price'] as num).toDouble());
}

/// Sinh chuỗi JSON lớn (~15+ MB). Chạy trong compute để không đứng UI.
String generateJson(int count) {
  final list = List.generate(
    count,
    (i) => {
      'id': i,
      'name': 'Product $i',
      'price': (i % 1000) * 1.25,
      'tags': ['flutter', 'dart', 'isolate'],
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, mô tả sản phẩm số $i',
    },
  );
  return jsonEncode(list);
}

/// Việc nặng: parse JSON + map sang model. Dùng chung cho cả 3 cách.
List<Product> parseProducts(String json) {
  final raw = jsonDecode(json) as List<dynamic>;
  return raw.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
}

// ── Isolate thủ công: giao tiếp qua SendPort / ReceivePort ──
class _Request {
  final SendPort replyTo;
  final String json;
  _Request(this.replyTo, this.json);
}

void _isolateEntry(_Request req) {
  try {
    req.replyTo.send(parseProducts(req.json)); // gửi kết quả về main
  } catch (e) {
    req.replyTo.send('ERROR: $e');
  }
}

Future<List<Product>> parseWithIsolate(String json) async {
  final receivePort = ReceivePort(); // "hộp thư" của main isolate
  final isolate = await Isolate.spawn(_isolateEntry, _Request(receivePort.sendPort, json));
  final result = await receivePort.first; // chờ tin nhắn đầu tiên
  receivePort.close();
  isolate.kill(priority: Isolate.immediate);
  if (result is String) throw Exception(result);
  return result as List<Product>;
}

// ───────────────────────── Đo FPS ─────────────────────────
class FpsMonitor {
  final live = ValueNotifier<double>(0);
  final _sw = Stopwatch()..start();
  int _frames = 0, _windowFrames = 0;
  int _windowStartUs = 0, _lastUs = 0, _maxGapUs = 0;
  bool _session = false;

  void start() => SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);

  void _onFrame(Duration _) {
    final now = _sw.elapsedMicroseconds;
    if (_session && _lastUs != 0) {
      final gap = now - _lastUs;
      if (gap > _maxGapUs) _maxGapUs = gap;
      _frames++;
    }
    _lastUs = now;
    _windowFrames++;
    if (now - _windowStartUs >= 500000) {
      live.value = _windowFrames * 1e6 / (now - _windowStartUs);
      _windowFrames = 0;
      _windowStartUs = now;
    }
  }

  void beginSession() {
    _frames = 0;
    _maxGapUs = 0;
    _lastUs = _sw.elapsedMicroseconds;
    _session = true;
  }

  /// Trả về (FPS trung bình, khoảng đứng hình dài nhất tính bằng ms)
  (double, double) endSession(int elapsedUs) {
    _session = false;
    return (_frames * 1e6 / elapsedUs, _maxGapUs / 1000);
  }
}

// ───────────────────────── UI ─────────────────────────
class BenchResult {
  final String label;
  final int ms;
  final double avgFps, maxGapMs;
  final int count;
  BenchResult(this.label, this.ms, this.avgFps, this.maxGapMs, this.count);
}

class IsolateDemo extends StatefulWidget {
  const IsolateDemo({super.key});
  @override
  State<IsolateDemo> createState() => _IsolateDemoState();
}

class _IsolateDemoState extends State<IsolateDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  final _fps = FpsMonitor();
  String? _json;
  bool _busy = false;
  String _status = 'Bấm "Tạo JSON" trước.';
  final List<BenchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _fps.start();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _status = 'Đang tạo JSON (trong isolate)...';
    });
    final json = await compute(generateJson, 130000);
    setState(() {
      _json = json;
      _busy = false;
      _status = 'JSON: ${(json.length / 1024 / 1024).toStringAsFixed(1)} MB. Sẵn sàng.';
    });
  }

  Future<void> _run(String label, Future<List<Product>> Function(String) task) async {
    if (_json == null || _busy) return;
    setState(() {
      _busy = true;
      _status = 'Đang chạy: $label ...';
    });
    // Chờ 1 frame để UI kịp hiển thị trạng thái trước khi (có thể) bị chặn
    await WidgetsBinding.instance.endOfFrame;

    _fps.beginSession();
    final sw = Stopwatch()..start();
    final data = await task(_json!);
    await WidgetsBinding.instance.endOfFrame; // ghi nhận frame đầu tiên sau khi xong
    sw.stop();
    final (avg, gap) = _fps.endSession(sw.elapsedMicroseconds);

    setState(() {
      _results.insert(0, BenchResult(label, sw.elapsedMilliseconds, avg, gap, data.length));
      _busy = false;
      _status = 'Xong: $label';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isolate vs Main Thread')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            RotationTransition(
              turns: _spin,
              child: const Icon(Icons.autorenew, size: 56, color: Colors.indigo),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _fps.live,
              builder: (_, v, __) => Column(children: [
                Text(v.toStringAsFixed(0),
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: v >= 50 ? Colors.green : (v >= 30 ? Colors.orange : Colors.red))),
                const Text('FPS (live)'),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          Text(_status),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonal(onPressed: _busy ? null : _generate, child: const Text('0. Tạo JSON ~15MB')),
            FilledButton(
                onPressed: _busy ? null : () => _run('Main Thread', (s) async => parseProducts(s)),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('1. Main Thread')),
            FilledButton(
                onPressed: _busy ? null : () => _run('compute()', (s) => compute(parseProducts, s)),
                child: const Text('2. compute()')),
            FilledButton(
                onPressed: _busy ? null : () => _run('Isolate.spawn + Port', parseWithIsolate),
                child: const Text('3. Isolate + Port')),
          ]),
          const Divider(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final r = _results[i];
                return Card(
                  child: ListTile(
                    title: Text(r.label),
                    subtitle: Text('Thời gian: ${r.ms} ms  •  ${r.count} bản ghi\n'
                        'FPS TB: ${r.avgFps.toStringAsFixed(1)}  •  '
                        'Đứng hình dài nhất: ${r.maxGapMs.toStringAsFixed(0)} ms'),
                    isThreeLine: true,
                    leading: Icon(r.avgFps >= 40 ? Icons.check_circle : Icons.warning,
                        color: r.avgFps >= 40 ? Colors.green : Colors.red),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}