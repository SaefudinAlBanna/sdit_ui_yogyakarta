// lib/app/models/siswa_ujian.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SiswaUjian {
  final String id; // ID dokumen ujian
  final String nisn;
  final String namaSiswa;
  final String capaian;
  final String levelUjian;
  final DocumentReference docRef;

  SiswaUjian({
    required this.id,
    required this.nisn,
    required this.namaSiswa,
    required this.capaian,
    required this.levelUjian,
    required this.docRef,
  });

  // --- FACTORY DIPERBARUI ---
  factory SiswaUjian.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> docUjian, 
    DocumentSnapshot<Map<String, dynamic>> docIndukSiswa
  ) {
    final dataUjian = docUjian.data() ?? {};
    final dataInduk = docIndukSiswa.data() ?? {};
    
    return SiswaUjian(
      id: docUjian.id,
      nisn: docIndukSiswa.id,
      // Ambil nama dari dokumen induk, ini yang paling akurat
      namaSiswa: dataInduk['namasiswa'] ?? 'Nama Tidak Ditemukan', 
      capaian: dataUjian['capaian_saat_didaftarkan'] ?? '-',
      levelUjian: dataUjian['level_ujian'] ?? '-',
      docRef: docUjian.reference,
    );
  }
}