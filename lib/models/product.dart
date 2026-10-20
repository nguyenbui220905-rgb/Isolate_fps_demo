class Product {
  final int id;
  final String name;
  final double price;

  const Product(this.id, this.name, this.price);

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      json['id'] as int,
      json['name'] as String,
      (json['price'] as num).toDouble(),
    );
  }
}