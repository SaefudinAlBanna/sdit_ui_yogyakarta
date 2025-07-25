class PengampuInfo {
  final String namaPengampu;
  final String fase;
  final String idPengampu;
  final String namaTempat;
  final String? profileImageUrl;
  final int jumlahSiswa;
  final int jumlahSiapUjian;

  PengampuInfo({
    required this.namaPengampu,
    required this.fase,
    required this.idPengampu,
    required this.namaTempat,
    this.profileImageUrl,
    required this.jumlahSiswa,
    required this.jumlahSiapUjian,
  });

  // --- FUNGSI COPYWITH YANG SUDAH DIPERBAIKI ---
  PengampuInfo copyWith({
    String? namaPengampu,
    String? fase,
    String? idPengampu,
    String? namaTempat,
    String? profileImageUrl,
    int? jumlahSiswa,
    int? jumlahSiapUjian, // <-- Tambahkan ini
  }) {
    return PengampuInfo(
      namaPengampu: namaPengampu ?? this.namaPengampu,
      fase: fase ?? this.fase,
      idPengampu: idPengampu ?? this.idPengampu,
      namaTempat: namaTempat ?? this.namaTempat,
      jumlahSiswa: jumlahSiswa ?? this.jumlahSiswa,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      jumlahSiapUjian: jumlahSiapUjian ?? this.jumlahSiapUjian, // <-- Bawa nilai lama
    );
  }
}