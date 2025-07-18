// pengampu_info.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PengampuInfo {
  final String namaPengampu;
  final String fase;
  final String idPengampu;
  final String namaTempat; // <-- FIELD BARU DITAMBAHKAN
  final String? profileImageUrl;
  final int jumlahSiswa;

  PengampuInfo({
    required this.namaPengampu,
    required this.fase,
    required this.idPengampu,
    required this.namaTempat, // <-- TAMBAHKAN DI CONSTRUCTOR
    this.profileImageUrl,
    this.jumlahSiswa = 0, // Beri nilai default 0
  });

  // Factory ini TIDAK BISA LAGI DIGUNAKAN secara langsung,
  // karena 'namaTempat' berasal dari sub-koleksi.
  // Kita akan membuat objek ini secara manual di controller.
  factory PengampuInfo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, {required String namaTempat}) {
    final data = doc.data() ?? {};
    return PengampuInfo(
      namaPengampu: data['namapengampu'] ?? 'Tanpa Nama',
      fase: data['fase'] ?? '',
      idPengampu: data['idpengampu'] ?? '',
      namaTempat: namaTempat, // <-- ISI DARI PARAMETER
      // jumlahSiswa & profileImageUrl diisi nanti via copyWith
    );
  }

  // Update method 'copyWith'
  PengampuInfo copyWith({
    String? namaPengampu,
    String? fase,
    String? idPengampu,
    String? namaTempat, // <-- TAMBAHKAN DI COPYWITH
    String? profileImageUrl,
    int? jumlahSiswa,
  }) {
    return PengampuInfo(
      namaPengampu: namaPengampu ?? this.namaPengampu,
      fase: fase ?? this.fase,
      idPengampu: idPengampu ?? this.idPengampu,
      namaTempat: namaTempat ?? this.namaTempat, // <-- TAMBAHKAN DI COPYWITH
      jumlahSiswa: jumlahSiswa ?? this.jumlahSiswa,
      profileImageUrl: profileImageUrl, // Jangan gunakan '?? this.profileImageUrl' agar bisa di-set jadi null
    );
  }
}