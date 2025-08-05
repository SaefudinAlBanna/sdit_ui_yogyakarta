// File: lib/app/modules/admin_manajemen/models/master_ekskul_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MasterEkskulModel {
  String id;
  String namaMaster;
  String kategori;
  String deskripsiDefault;
  String status; // "Aktif" atau "Dihapus"
  Timestamp dibuatPada;
  Timestamp diubahPada;

  MasterEkskulModel({
    required this.id,
    required this.namaMaster,
    required this.kategori,
    required this.deskripsiDefault,
    required this.status,
    required this.dibuatPada,
    required this.diubahPada,
  });

  factory MasterEkskulModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MasterEkskulModel(
      id: doc.id,
      namaMaster: data['namaMaster'] ?? '',
      kategori: data['kategori'] ?? '',
      deskripsiDefault: data['deskripsiDefault'] ?? '',
      status: data['status'] ?? 'Aktif',
      dibuatPada: data['dibuatPada'] ?? Timestamp.now(),
      diubahPada: data['diubahPada'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'namaMaster': namaMaster,
      'kategori': kategori,
      'deskripsiDefault': deskripsiDefault,
      'status': status,
      'dibuatPada': dibuatPada,
      'diubahPada': diubahPada,
    };
  }
}