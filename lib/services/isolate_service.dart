import 'dart:isolate';

import '../models/product.dart';
import 'json_service.dart';

class IsolateRequest {
  final SendPort replyTo;
  final String json;

  const IsolateRequest(this.replyTo, this.json);
}

/// Hàm chạy bên isolate mới.
void isolateEntry(IsolateRequest request) {
  try {
    final products = parseProducts(request.json);
    request.replyTo.send(products);
  } catch (e) {
    request.replyTo.send('ERROR: $e');
  }
}

/// Tạo isolate, gửi JSON và chờ kết quả trả về.
Future<List<Product>> parseWithIsolate(String json) async {
  final receivePort = ReceivePort();
  Isolate? isolate;

  try {
    isolate = await Isolate.spawn(
      isolateEntry,
      IsolateRequest(receivePort.sendPort, json),
    );

    final result = await receivePort.first;

    if (result is String && result.startsWith('ERROR:')) {
      throw Exception(result);
    }

    if (result is! List<Product>) {
      throw Exception('Kết quả trả về không hợp lệ.');
    }

    return result;
  } finally {
    receivePort.close();
    isolate?.kill(priority: Isolate.immediate);
  }
}