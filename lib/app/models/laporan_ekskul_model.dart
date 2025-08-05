// File: lib/app/modules/admin_manajemen/models/laporan_ekskul_model.dart

// Model ini TIDAK merepresentasikan dokumen Firestore.
// Ini adalah model untuk menampung data yang sudah diproses di aplikasi.
class LaporanEkskulModel {
  String instanceEkskulId;
  String namaEkskulLengkap;
  List<String> namaPembina;
  int jumlahAnggota;
  // Nanti bisa ditambahkan: Map<String, int> sebaranPerKelas;

  LaporanEkskulModel({
    required this.instanceEkskulId,
    required this.namaEkskulLengkap,
    required this.namaPembina,
    required this.jumlahAnggota,
  });
}