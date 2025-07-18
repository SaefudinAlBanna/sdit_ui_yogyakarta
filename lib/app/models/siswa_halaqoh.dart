import 'package:cloud_firestore/cloud_firestore.dart';

class SiswaHalaqoh {
  final String nisn;
  final String namaSiswa;
  final String kelas;
  final String ummi;
  final String? profileImageUrl;
  final String capaian;
  // Simpan data mentah untuk fungsi seperti 'pindahkan'
  final Map<String, dynamic> rawData; 
  final String? statusUjian;

  SiswaHalaqoh({
    required this.nisn,
    required this.namaSiswa,
    required this.kelas,
    required this.ummi,
    this.profileImageUrl,
    required this.capaian,
    required this.rawData,
    this.statusUjian,
  });

  factory SiswaHalaqoh.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SiswaHalaqoh(
      nisn: doc.id, // atau data['nisn'] ?? ''
      namaSiswa: data['namasiswa'] ?? 'Tanpa Nama',
      kelas: data['kelas'] ?? 'Tanpa Kelas',
      ummi: data['ummi'] ?? '0',
      profileImageUrl: data['profileImageUrl'],
      capaian: data['capaian_terakhir'] ?? '',
      rawData: data, // Simpan semua data asli
      statusUjian: data['status_ujian'],
    );
  }

  SiswaHalaqoh copyWith({
    String? namaSiswa,
    String? nisn,
    String? kelas,
    String? ummi,
    String? profileImageUrl,
    String? fase,
    String? namapengampu,
    String? tempatmengaji,
    String? capaian,
  }) {
    return SiswaHalaqoh(
      namaSiswa: namaSiswa ?? this.namaSiswa,
      nisn: nisn ?? this.nisn,
      kelas: kelas ?? this.kelas,
      ummi: ummi ?? this.ummi,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      capaian: capaian ?? this.capaian,
      rawData: rawData, // You may want to pass this.rawData or allow rawData as a parameter in copyWith
    );
  }
}
