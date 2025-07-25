// lib/app/models/rekap_absensi_model.dart

class RekapAbsensiSiswaModel {
  final String idSiswa;
  final String namaSiswa;
  final int sakitCount;
  final int izinCount;
  final int alfaCount;

  RekapAbsensiSiswaModel({
    required this.idSiswa,
    required this.namaSiswa,
    required this.sakitCount,
    required this.izinCount,
    required this.alfaCount,
  });
}