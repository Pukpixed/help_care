import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference animeCollection =
      FirebaseFirestore.instance.collection('anime');

  // เพิ่มข้อมูลอนิเมะ
  Future<void> addAnime(String name, int episode, int season, double score) {
    return animeCollection.add({
      'name': name,
      'episode': episode,
      'season': season,
      'score': score,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ดึงข้อมูลอนิเมะทั้งหมด (Stream)
  Stream<QuerySnapshot> getAnimes() {
    return animeCollection.orderBy('createdAt', descending: true).snapshots();
  }

  // ดึงอนิเมะตาม id
  Future<Map<String, dynamic>?> getAnimeById(String id) async {
    DocumentSnapshot doc = await animeCollection.doc(id).get();
    return doc.data() as Map<String, dynamic>?;
  }

  // อัปเดตข้อมูลอนิเมะ
  Future<void> updateAnime(
      String id, String name, int episode, int season, double score) {
    return animeCollection.doc(id).update({
      'name': name,
      'episode': episode,
      'season': season,
      'score': score,
    });
  }

  // ลบอนิเมะ
  Future<void> deleteAnime(String id) {
    return animeCollection.doc(id).delete();
  }
}
