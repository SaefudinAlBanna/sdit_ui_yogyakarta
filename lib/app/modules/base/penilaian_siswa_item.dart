// File: lib/app/modules/base/penilaian_siswa_item.dart

import 'package:get/get.dart';

import '../../models/siswa_model.dart';

/// Model reaktif untuk satu baris di halaman penilaian.
/// Menggunakan generic type <T> untuk nilai (bisa int, String, dll).
class PenilaianSiswaItem<T> {
  final SiswaModel siswa;
  final T? nilaiAwal;
  final String keteranganAwal;

  final Rxn<T> nilai;
  final RxString keterangan;
  final RxBool isSelected;

  PenilaianSiswaItem({
    required this.siswa,
    this.nilaiAwal,
    required this.keteranganAwal,
  })  : nilai = Rxn<T>(nilaiAwal),
        keterangan = RxString(keteranganAwal),
        isSelected = false.obs;

  /// Cek apakah ada perubahan dari data awal.
  bool get isChanged => nilai.value != nilaiAwal || keterangan.value != keteranganAwal;
}