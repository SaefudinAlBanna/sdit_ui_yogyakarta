// File: lib/app/modules/admin_manajemen/models/pegawai_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PegawaiModel {
  String uid;
  String nama;
  String role;
  String? profileImageUrl;
  List<Map<String, dynamic>> ekskulYangDiampu;

  PegawaiModel({
    required this.uid,
    required this.nama,
    required this.role,
    this.profileImageUrl,
    required this.ekskulYangDiampu,
  });

  factory PegawaiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PegawaiModel(
      uid: doc.id,
      nama: data['nama'] ?? 'Tanpa Nama',
      role: data['role'] ?? 'Tidak ada role',
      profileImageUrl: data['profileImageUrl'],
      ekskulYangDiampu: List<Map<String, dynamic>>.from(data['ekskulYangDiampu'] ?? []),
    );
  }
}