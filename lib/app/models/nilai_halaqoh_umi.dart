// lib/models/nilai_halaqoh_umi.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NilaiHalaqohUmi {
  final String id;
  final DateTime tanggal;
  final String hafalanSurat;
  final String ayatHafalan;
  final String keteranganPengampu;
  final String keteranganOrangTua;
  final String fase;
  final String capaian;
  final String kelas;
  final int nilai;
  final String materi;
  final String tempatMengaji;
  final Timestamp? terakhirDiubah;
  final String? diubahOlehNama;
  final String? diubahOlehUid;

  NilaiHalaqohUmi({
    required this.id,
    required this.tanggal,
    required this.hafalanSurat,
    required this.ayatHafalan,
    required this.keteranganPengampu,
    required this.keteranganOrangTua,
    required this.fase,
    required this.capaian,
    required this.kelas,
    required this.nilai,
    required this.materi,
    required this.tempatMengaji,
    this.terakhirDiubah,
    this.diubahOlehNama,
    this.diubahOlehUid,
  });

  // Factory untuk membuat objek dari data Firestore
  factory NilaiHalaqohUmi.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // Mencoba parse tanggal dari ID dokumen. Jika gagal, gunakan tanggal hari ini.
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(doc.id);
    } catch (e) {
      parsedDate = DateTime.now();
    }

    

    return NilaiHalaqohUmi(
      id: doc.id,
      tanggal: parsedDate,
      hafalanSurat: data['hafalansurat'] ?? '-',
      ayatHafalan: data['ayathafalansurat'] ?? '-',
      keteranganPengampu: data['keteranganpengampu'] ?? 'Tidak ada catatan.',
      // Cek jika keterangan '0' atau null, anggap tidak ada
      keteranganOrangTua: (data['keteranganorangtua'] != null && data['keteranganorangtua'] != '0') 
          ? data['keteranganorangtua'] 
          : 'Belum ada respon.',
      fase: data['fase'] ?? '-',
      capaian: data['capaian'] ?? '-',
      kelas: data['kelas'] ?? '-',
      nilai: data['nilai'] ?? '-',
      materi: data['materi'] ?? '-',
      tempatMengaji: data['tempatmengaji'] ?? 'Tidak tercatat', 
      terakhirDiubah: data['terakhir_diubah'] as Timestamp?,
      diubahOlehNama: data['diubah_oleh_nama'] as String?,
      diubahOlehUid: data['diubah_oleh_uid'] as String?,
    );
  }

  // Helper untuk memformat tanggal dengan cantik
  String get formattedDate {
    return DateFormat('EEEE, d MMMM y', 'id_ID').format(tanggal);
  }

  String get nilaihuruf {
    // Contoh konversi nilai angka ke huruf
    if (nilai >= 90) return 'A';
    if (nilai >= 85) return 'B+';
    if (nilai >= 80) return 'B';
    if (nilai >= 75) return 'B-';
    if (nilai >= 70) return 'C+';
    if (nilai >= 65) return 'C';
    if (nilai >= 60) return 'C-';
    return 'D';
  }
}