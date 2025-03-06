import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> fetchDishes({
    String? region,
    String? flavorProfile,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('dishes');

      if (region != null && region.isNotEmpty) {
        query = query.where('region', isEqualTo: region);
      }

      if (flavorProfile != null && flavorProfile.isNotEmpty) {
        query = query.where('flavor_profile', isEqualTo: flavorProfile);
      }

      QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching dishes: $e');
    }
  }
}