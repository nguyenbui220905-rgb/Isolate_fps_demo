import 'dart:convert';

import '../models/product.dart';

/// Tạo JSON lớn.
/// Hàm này được gọi bằng compute() từ giao diện.
String generateJson(int count) {
  final list = List.generate(
    count,
    (i) => {
      'id': i,
      'name': 'Product $i',
      'price': (i % 1000) * 1.25,
      'tags': ['flutter', 'dart', 'isolate'],
      'description':
          ('Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
              'mo ta san pham so $i ') *
          5,
    },
  );

  return jsonEncode(list);
}

/// Parse JSON và chuyển thành danh sách Product.
List<Product> parseProducts(String json) {
  final raw = jsonDecode(json) as List<dynamic>;

  return raw
      .map(
        (item) => Product.fromJson(item as Map<String, dynamic>),
      )
      .toList();
}

/// Tính dung lượng JSON thực tế theo byte UTF-8, đơn vị MiB.
double getJsonSizeMiB(String json) {
  return utf8.encode(json).length / (1024 * 1024);
}