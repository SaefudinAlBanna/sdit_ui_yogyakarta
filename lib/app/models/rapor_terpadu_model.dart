// File: lib/app/modules/rapor_terpadu/models/rapor_terpadu_model.dart

// --- PERBAIKAN UTAMA DI SINI ---
// Impor dari sumber asli, bukan mendefinisikan ulang
import 'package:sdit_ui_yogyakarta/app/models/rapor_siswa_model.dart';
// ---------------------------------

import 'package:sdit_ui_yogyakarta/app/models/rekap_absensi_model.dart';

import 'siswa_model.dart';

// Model untuk menampung data ekskul yang sudah diolah untuk rapor
class RaporEkskulItem {
  String namaEkskul;
  String? predikat;
  String? keterangan;
  RaporEkskulItem({required this.namaEkskul, this.predikat, this.keterangan});
}

// Model untuk menampung data halaqoh yang sudah diolah untuk rapor
class RaporHalaqohItem {
  String jenis; // "Tahsin" atau "Tahfidz"
  int? nilaiAkhir;
  String? keterangan;
  RaporHalaqohItem({required this.jenis, this.nilaiAkhir, this.keterangan});
}

// Model "SUPER" yang akan menampung semua data untuk satu rapor lengkap
class RaporTerpaduModel {
  SiswaModel dataSiswa;
  String tahunAjaran;
  String semester;
  
  List<RaporMapelModel> dataAkademik;
  List<RaporEkskulItem> dataEkskul;
  List<RaporHalaqohItem> dataHalaqoh;
  RekapAbsensiSiswaModel dataAbsensi;
  String catatanWaliKelas;
  String namaWaliKelas;
  String namaKepalaSekolah;

  RaporTerpaduModel({
    required this.dataSiswa,
    required this.tahunAjaran,
    required this.semester,
    required this.dataAkademik,
    required this.dataEkskul,
    required this.dataHalaqoh,
    required this.dataAbsensi,
    required this.catatanWaliKelas,
    required this.namaWaliKelas,
    required this.namaKepalaSekolah,
  });
}