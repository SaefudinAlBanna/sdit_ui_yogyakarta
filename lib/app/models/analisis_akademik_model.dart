// lib/app/models/analisis_akademik_model.dart

/// Model ini mewakili hasil analisis keseluruhan untuk satu kelas.
class KelasAkademikModel {
  final double rataRataKelas;
  final List<SiswaAkademikModel> daftarSiswa;

  KelasAkademikModel({
    required this.rataRataKelas,
    required this.daftarSiswa,
  });
}

/// Model ini mewakili data akademik untuk satu siswa di dalam daftar.
class SiswaAkademikModel {
  final String idSiswa;
  final String namaSiswa;
  final double? rataRataNilai; // Rata-rata nilai akhir dari semua mapel

  SiswaAkademikModel({
    required this.idSiswa,
    required this.namaSiswa,
    this.rataRataNilai,
  });
}