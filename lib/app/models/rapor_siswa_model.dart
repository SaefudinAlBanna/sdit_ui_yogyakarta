// lib/app/models/rapor_siswa_model.dart

// Model ini adalah "bungkus" utama untuk satu mata pelajaran di rapor.
class RaporMapelModel {
  final String namaMapel;
  final String guruPengajar;
  final double? nilaiAkhir;
  final List<UnitCapaian> daftarCapaian; // Daftar capaian yang sudah dikelompokkan per Bab/Unit

  RaporMapelModel({
    required this.namaMapel,
    required this.guruPengajar,
    this.nilaiAkhir,
    required this.daftarCapaian,
  });
}

// Model ini merepresentasikan satu "Bab" atau "Unit Pembelajaran" di rapor.
class UnitCapaian {
  final String namaUnit; // Contoh: "Unit 1: Mengenal Rukun Iman"
  final List<String> tpTercapai; // Daftar TP yang statusnya "Tercapai"
  final List<String> tpPerluBimbingan; // Daftar TP yang statusnya "Perlu Bimbingan"

  UnitCapaian({
    required this.namaUnit,
    required this.tpTercapai,
    required this.tpPerluBimbingan,
  });
}