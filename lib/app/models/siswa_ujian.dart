// lib/app/models/siswa_ujian.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SiswaUjian {
  final String id;
  final String namaSiswa;
  final String capaian;
  final String levelUjian;
  final DocumentReference docRef; // Referensi ke dokumen ini
  SiswaUjian({
    required this.id,
    required this.namaSiswa,
    required this.capaian,
    required this.levelUjian,
    required this.docRef,
  });
  factory SiswaUjian.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SiswaUjian(
      id: doc.id,
      namaSiswa: doc.reference.parent.parent!.id, // Ambil NISN dari path
      capaian: data['capaian_saat_didaftarkan'] ?? '-',
      levelUjian: data['level_ujian'] ?? '-',
      docRef: doc.reference, // Simpan referensi dokumennya
    );
  }
}
