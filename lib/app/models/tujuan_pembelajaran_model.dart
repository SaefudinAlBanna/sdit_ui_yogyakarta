import 'package:cloud_firestore/cloud_firestore.dart';

class TujuanPembelajaranModel {
  final String id;
  final String deskripsi;
  // Anda bisa menambahkan properti lain seperti 'kode', 'bab', dll.
  
  TujuanPembelajaranModel({required this.id, required this.deskripsi});

  factory TujuanPembelajaranModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TujuanPembelajaranModel(
      id: doc.id,
      deskripsi: data['deskripsi'] ?? 'Deskripsi tidak ditemukan',
    );
  }
}