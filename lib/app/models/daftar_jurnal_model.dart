// lib/app/data/models/jurnal_model.dart (contoh path)

import 'package:cloud_firestore/cloud_firestore.dart';

// Model untuk data Jurnal yang akan ditampilkan di daftar
class JurnalModel {
  final String id;
  final String jamPelajaran;
  final String kelas;
  final String namaMapel;
  final String materi;
  final String? catatan;
  final String namaGuru;

  JurnalModel({
    required this.id,
    required this.jamPelajaran,
    required this.kelas,
    required this.namaMapel,
    required this.materi,
    this.catatan,
    required this.namaGuru,
  });

  // Factory constructor untuk membuat instance JurnalModel dari dokumen Firestore
  factory JurnalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return JurnalModel(
      id: doc.id,
      jamPelajaran: data['jampelajaran'] ?? 'Tanpa Jam',
      kelas: data['kelas'] ?? 'Tanpa Kelas',
      namaMapel: data['namamapel'] ?? 'Tanpa Mapel',
      materi: data['materipelajaran'] ?? 'Materi tidak diisi',
      catatan: data['catatanjurnal'],
      namaGuru: data['namapenginput'] ?? 'Guru tidak diketahui',
    );
  }
}

// Model untuk data Kelas yang akan ditampilkan di dropdown
class KelasModel {
  final String id; // Misal: "1A"
  final String nama; // Misal: "Kelas 1A"

  KelasModel({required this.id, required this.nama});

  factory KelasModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return KelasModel(
      id: doc.id,
      nama: data['namakelas'] ?? doc.id, // Fallback ke ID jika namakelas null
    );
  }
}