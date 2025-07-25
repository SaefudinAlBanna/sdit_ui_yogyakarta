// lib/app/models/nilai_harian_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NilaiHarian {
  final String id;
  final String kategori;
  final int nilai;
  final String catatan;
  final DateTime tanggal;

  NilaiHarian({
    required this.id,
    required this.kategori,
    required this.nilai,
    required this.catatan,
    required this.tanggal,
  });

  factory NilaiHarian.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NilaiHarian(
      id: doc.id,
      kategori: data['kategori'] ?? 'Lainnya',
      nilai: data['nilai'] ?? 0,
      catatan: data['catatan'] ?? '',
      tanggal: (data['tanggal'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}