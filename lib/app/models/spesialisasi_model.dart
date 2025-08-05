// File: lib/app/modules/admin_manajemen/models/spesialisasi_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SpesialisasiModel {
  String id;
  String namaSpesialisasi;
  String status; // "Aktif" atau "Dihapus"
  Timestamp dibuatPada;
  Timestamp diubahPada;

  SpesialisasiModel({
    required this.id,
    required this.namaSpesialisasi,
    required this.status,
    required this.dibuatPada,
    required this.diubahPada,
  });

  factory SpesialisasiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SpesialisasiModel(
      id: doc.id,
      namaSpesialisasi: data['namaSpesialisasi'] ?? '',
      status: data['status'] ?? 'Aktif',
      dibuatPada: data['dibuatPada'] ?? Timestamp.now(),
      diubahPada: data['diubahPada'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'namaSpesialisasi': namaSpesialisasi,
      'status': status,
      'dibuatPada': dibuatPada,
      'diubahPada': diubahPada,
    };
  }
}