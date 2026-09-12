import 'package:cloud_firestore/cloud_firestore.dart';

class ShopCategory {
  final String id;
  final String name;
  final String imageBase64;
  final Timestamp? createdAt;
  final List<String> countries;

  const ShopCategory({
    required this.id,
    required this.name,
    this.imageBase64 = '',
    this.countries = const [],
    this.createdAt,
  });

  factory ShopCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ShopCategory(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      imageBase64: (data['imageBase64'] ?? '') as String,
      countries: (data['countries'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'imageBase64': imageBase64, 'countries': countries};
  }

  bool visibleTo(String userCountry) {
    if (countries.isEmpty) return true;
    if (userCountry.trim().isEmpty) return true;
    return countries.contains(userCountry);
  }
}
