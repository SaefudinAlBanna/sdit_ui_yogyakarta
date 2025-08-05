import 'package:cloud_firestore/cloud_firestore.dart';

class SiswaModel {
  String nisn;
  String nama;
  String idKelas;
  String namaKelas;

  SiswaModel({
    required this.nisn,
    required this.nama,
    required this.idKelas,
    required this.namaKelas,
  });

  factory SiswaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SiswaModel(
      nisn: doc.id, // ID dokumen adalah NISN
      // --- PERBAIKAN DI SINI ---
      // Coba baca dari 'namasiswa', kalau tidak ada coba dari 'nama', kalau tidak ada pakai 'Tanpa Nama'
      nama: data['namasiswa'] ?? data['nama'] ?? 'Tanpa Nama',
      // Cek juga field kelas, mungkin namanya 'kelas' bukan 'namaKelas'
      idKelas: data['idKelas'] ?? '',
      namaKelas: data['namaKelas'] ?? data['kelas'] ?? 'Tanpa Kelas',
      // --- AKHIR PERBAIKAN ---
    );
  }
}