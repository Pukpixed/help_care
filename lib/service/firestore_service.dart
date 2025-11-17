import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _notesCol =>
      _db.collection('users').doc(_uid).collection('notes');

  Future<void> addNote(String text) async {
    await _notesCol.add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotes() {
    return _notesCol.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateNote(String id, String newText) async {
    await _notesCol.doc(id).update({
      'text': newText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String id) async {
    await _notesCol.doc(id).delete();
  }
}
