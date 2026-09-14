import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_product.dart';

class ShopService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('shop_products');

  List<ShopProduct> _sortByNewest(List<ShopProduct> products) {
    final sorted = List<ShopProduct>.from(products);
    sorted.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  Stream<List<ShopProduct>> streamActiveProductsByCategory(String category) {
    return _col
        .where('category', isEqualTo: category)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ShopProduct.fromDoc(d))
            .where((p) => p.isActive)
            .toList())
        .map((list) => _sortByNewest(list));
  }

  Stream<List<ShopProduct>> streamAllProductsByCategory(String category) {
    return _col
        .where('category', isEqualTo: category)
        .snapshots()
        .map((s) => s.docs.map((d) => ShopProduct.fromDoc(d)).toList())
        .map((list) => _sortByNewest(list));
  }

  Future<void> addProduct(ShopProduct product) async {
    final data = product.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _col.add(data);
  }

  Future<void> updateProduct(String id, ShopProduct product) async {
    final data = product.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(id).update(data);
  }

  Future<void> toggleActive(String id, bool value) async {
    await _col.doc(id).update({
      'isActive': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String id) async {
    await _col.doc(id).delete();
  }

  Future<List<ShopProduct>> getAllProductsOnce() async {
    final snapshot = await _col.get();
    return snapshot.docs.map((d) => ShopProduct.fromDoc(d)).toList();
  }

  Future<void> applyBulkChanges({
    List<ShopProduct> creates = const [],
    Map<String, ShopProduct> updates = const {},
    List<String> deletes = const [],
  }) async {
    final ops = <void Function(WriteBatch batch)>[];

    for (final product in creates) {
      ops.add((batch) {
        final docRef = _col.doc();
        final data = product.toMap();
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, data);
      });
    }

    updates.forEach((id, product) {
      ops.add((batch) {
        final data = product.toMap();
        data['updatedAt'] = FieldValue.serverTimestamp();
        batch.update(_col.doc(id), data);
      });
    });

    for (final id in deletes) {
      ops.add((batch) => batch.delete(_col.doc(id)));
    }

    if (ops.isEmpty) return;

    const chunkSize = 400;
    for (var i = 0; i < ops.length; i += chunkSize) {
      final chunk = ops.sublist(
        i,
        i + chunkSize > ops.length ? ops.length : i + chunkSize,
      );
      final batch = FirebaseFirestore.instance.batch();
      for (final op in chunk) {
        op(batch);
      }
      await batch.commit();
    }
  }
}
