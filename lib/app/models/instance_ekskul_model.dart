// File: lib/app/modules/admin_manajemen/models/instance_ekskul_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';


class InstanceEkskulModel {
  String id;
  String masterEkskulRef; // Pointer ke /master_ekskul/{id}
  String namaTampilan; // cth: "Tim Inti Basket Putra"
  String idTahunAjaran;
  List<Map<String, dynamic>> pembina;
  /*
    Contoh isi 'pembina':
    [
      {"tipe": "internal", "uid": "uid_guru_A", "nama": "Andi Setiawan, S.Pd."},
      {"tipe": "eksternal", "uid": "uid_pelatih_X", "nama": "John Doe"}
    ]
  */
  String hariJadwal;
  String jamMulai; // Format "HH:mm"
  String jamSelesai; // Format "HH:mm"
  String lokasi;
  String status; // "Aktif" atau "Dibatalkan"

  InstanceEkskulModel({
    required this.id,
    required this.masterEkskulRef,
    required this.namaTampilan,
    required this.idTahunAjaran,
    required this.pembina,
    required this.hariJadwal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.lokasi,
    required this.status,
  });

  factory InstanceEkskulModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return InstanceEkskulModel(
      id: doc.id,
      masterEkskulRef: data['masterEkskulRef'] ?? '',
      namaTampilan: data['namaTampilan'] ?? '',
      idTahunAjaran: data['idTahunAjaran'] ?? '',
      pembina: List<Map<String, dynamic>>.from(data['pembina'] ?? []),
      hariJadwal: data['hariJadwal'] ?? '',
      jamMulai: data['jamMulai'] ?? '',
      jamSelesai: data['jamSelesai'] ?? '',
      lokasi: data['lokasi'] ?? '',
      status: data['status'] ?? 'Aktif',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'masterEkskulRef': masterEkskulRef,
      'namaTampilan': namaTampilan,
      'idTahunAjaran': idTahunAjaran,
      'pembina': pembina,
      'hariJadwal': hariJadwal,
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
      'lokasi': lokasi,
      'status': status,
    };
  }
}