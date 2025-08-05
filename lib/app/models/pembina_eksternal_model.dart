// File: lib/app/modules/admin_manajemen/models/pembina_eksternal_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PembinaEksternalModel {
  String id;
  String namaLengkap;
  String kontak;
  List<String> spesialisasiRefs; // List of IDs from master_spesialisasi
  String status; // "Aktif" atau "Non-Aktif"
  List<Map<String, dynamic>> ekskulYangDiampu;
  Timestamp dibuatPada;

  PembinaEksternalModel({
    required this.id,
    required this.namaLengkap,
    required this.kontak,
    required this.spesialisasiRefs,
    required this.status,
    required this.ekskulYangDiampu,
    required this.dibuatPada,
  });

  factory PembinaEksternalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PembinaEksternalModel(
      id: doc.id,
      namaLengkap: data['namaLengkap'] ?? '',
      kontak: data['kontak'] ?? '',
      spesialisasiRefs: List<String>.from(data['spesialisasiRefs'] ?? []),
      status: data['status'] ?? 'Aktif',
      ekskulYangDiampu: List<Map<String, dynamic>>.from(data['ekskulYangDiampu'] ?? []),
      dibuatPada: data['dibuatPada'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'namaLengkap': namaLengkap,
      'kontak': kontak,
      'spesialisasiRefs': spesialisasiRefs,
      'status': status,
      'ekskulYangDiampu': ekskulYangDiampu,
      'dibuatPada': dibuatPada,
    };
  }
}