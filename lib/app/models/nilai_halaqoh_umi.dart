// lib/models/nilai_halaqoh_umi.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NilaiHalaqohUmi {
  final String id;
  final DateTime tanggalInput;
  final String hafalanSurat;
  final String ayatHafalan;
  final String capaian;
  final String materi;
  final int nilai;
  final String nilaihuruf;
  final String keteranganPengampu;
  final String keteranganOrangTua;
  final String lokasiSaatInput;
  final Timestamp? terakhirDiubah;
  final String? diubahOlehNama;

  NilaiHalaqohUmi({
    required this.id,
    required this.tanggalInput,
    required this.hafalanSurat,
    required this.ayatHafalan,
    required this.capaian,
    required this.materi,
    required this.nilai,
    required this.nilaihuruf,
    required this.keteranganPengampu,
    required this.keteranganOrangTua,
    required this.lokasiSaatInput,
    this.terakhirDiubah,
    this.diubahOlehNama,
  });

  factory NilaiHalaqohUmi.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // [PERBAIKAN #1] Konversi nilai yang SANGAT AMAN
    dynamic nilaiData = data['nilai'];
    int parsedNilai = 0;
    if (nilaiData is int) {
      parsedNilai = nilaiData;
    } else if (nilaiData is String) {
      parsedNilai = int.tryParse(nilaiData.trim()) ?? 0;
    }

    // [PERBAIKAN #2] Logika pembacaan tanggal yang TANGGUH
    DateTime parsedDate;
    if (data['tanggal_input'] is Timestamp) {
      parsedDate = (data['tanggal_input'] as Timestamp).toDate();
    } else if (data['tanggal'] is Timestamp) { // Fallback untuk field 'tanggal' lama
      parsedDate = (data['tanggal'] as Timestamp).toDate();
    } else {
      try {
        // Fallback terakhir, coba parse dari ID dokumen jika memungkinkan
        parsedDate = DateTime.parse(doc.id);
      } catch (e) {
        parsedDate = DateTime.now(); // Jika semua gagal, gunakan waktu sekarang
      }
    }

    // [PERBAIKAN #3] Penyelarasan Nama Field dari berbagai kemungkinan
    return NilaiHalaqohUmi(
      id: doc.id,
      tanggalInput: parsedDate,
      hafalanSurat: data['surat'] ?? data['hafalansurat'] ?? '-',
      ayatHafalan: data['ayat'] ?? data['ayathafalansurat'] ?? '-',
      capaian: data['capaian'] ?? '-',
      materi: data['materi'] ?? '-',
      keteranganPengampu: data['keterangan'] ?? data['keteranganpengampu'] ?? 'Tidak ada catatan.',
      keteranganOrangTua: data['keterangan_orangtua'] ?? data['keteranganorangtua'] ?? 'Belum ada respon.',
      nilai: parsedNilai,
      nilaihuruf: data['grade'] ?? data['nilaihuruf'] ?? '-',
      lokasiSaatInput: data['lokasi_saat_input'] ?? data['tempatmengaji'] ?? 'N/A',
      terakhirDiubah: data['terakhir_diubah'] as Timestamp?,
      diubahOlehNama: data['diubah_oleh_nama'] as String?,
    );
  }

  // Helper tidak berubah
  String get formattedDate => DateFormat('EEEE, d MMMM y', 'id_ID').format(tanggalInput);
}




// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class NilaiHalaqohUmi {
//   final String id;
//   final DateTime tanggal;
//   final String hafalanSurat;
//   final String ayatHafalan;
//   final String keteranganPengampu;
//   final String keteranganOrangTua;
//   final String fase;
//   final String capaian;
//   final String kelas;
//   final int nilai;
//   final String materi;
//   final String tempatMengaji;
//   final Timestamp? terakhirDiubah;
//   final String? diubahOlehNama;
//   final String? diubahOlehUid;
//   final String lokasiSaatInput;

//   // // Info data edit (opsional)
//   // final DateTime? terakhirDiubah;
//   // final String? diubahOlehNama;

//   NilaiHalaqohUmi({
//     required this.id,
//     required this.tanggal,
//     required this.hafalanSurat,
//     required this.ayatHafalan,
//     required this.keteranganPengampu,
//     required this.keteranganOrangTua,
//     required this.fase,
//     required this.capaian,
//     required this.kelas,
//     required this.nilai,
//     required this.materi,
//     required this.tempatMengaji,
//     this.terakhirDiubah,
//     this.diubahOlehNama,
//     this.diubahOlehUid,
//     required this.lokasiSaatInput,
//   });

//   // Factory untuk membuat objek dari data Firestore
//   factory NilaiHalaqohUmi.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
//     final data = doc.data() ?? {};
    
//     // Mencoba parse tanggal dari ID dokumen. Jika gagal, gunakan tanggal hari ini.
//     DateTime parsedDate;
//     try {
//       parsedDate = DateTime.parse(doc.id);
//     } catch (e) {
//       parsedDate = DateTime.now();
//     }

    

//     return NilaiHalaqohUmi(
//       id: doc.id,
//       tanggal: parsedDate,
//       hafalanSurat: data['hafalansurat'] ?? '-',
//       ayatHafalan: data['ayathafalansurat'] ?? '-',
//       keteranganPengampu: data['keteranganpengampu'] ?? 'Tidak ada catatan.',
//       // Cek jika keterangan '0' atau null, anggap tidak ada
//       keteranganOrangTua: (data['keteranganorangtua'] != null && data['keteranganorangtua'] != '0') 
//           ? data['keteranganorangtua'] 
//           : 'Belum ada respon.',
//       fase: data['fase'] ?? '-',
//       capaian: data['capaian'] ?? '-',
//       kelas: data['kelas'] ?? '-',
//       nilai: data['nilai'] ?? '-',
//       materi: data['materi'] ?? '-',
//       tempatMengaji: data['tempatmengaji'] ?? 'Tidak tercatat', 
//       terakhirDiubah: data['terakhir_diubah'] as Timestamp?,
//       diubahOlehNama: data['diubah_oleh_nama'] as String?,
//       diubahOlehUid: data['diubah_oleh_uid'] as String?,
//       lokasiSaatInput: data['lokasi_saat_input'] ?? data['tempatmengaji'] ?? 'N/A',
//     );
//   }

//   // Helper untuk memformat tanggal dengan cantik
//   String get formattedDate {
//     return DateFormat('EEEE, d MMMM y', 'id_ID').format(tanggal);
//   }

//   String get nilaihuruf {
//     // Contoh konversi nilai angka ke huruf
//     if (nilai >= 90) return 'A';
//     if (nilai >= 85) return 'B+';
//     if (nilai >= 80) return 'B';
//     if (nilai >= 75) return 'B-';
//     if (nilai >= 70) return 'C+';
//     if (nilai >= 65) return 'C';
//     if (nilai >= 60) return 'C-';
//     return 'D';
//   }
// }