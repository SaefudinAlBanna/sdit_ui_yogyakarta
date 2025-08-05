import 'package:cloud_firestore/cloud_firestore.dart';

class PengumumanModel {
  String id;
  String judul;
  String isi;
  String dibuatOlehUid;
  String dibuatOlehNama;
  Timestamp tanggalDibuat;
  Timestamp? tanggalDiubah;

  PengumumanModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.dibuatOlehUid,
    required this.dibuatOlehNama,
    required this.tanggalDibuat,
    this.tanggalDiubah,
  });

  factory PengumumanModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PengumumanModel(
      id: doc.id,
      judul: data['judul'] ?? '',
      isi: data['isi'] ?? '',
      dibuatOlehUid: data['dibuatOlehUid'] ?? '',
      dibuatOlehNama: data['dibuatOlehNama'] ?? '',
      tanggalDibuat: data['tanggalDibuat'] ?? Timestamp.now(),
      tanggalDiubah: data['tanggalDiubah'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'judul': judul,
      'isi': isi,
      'dibuatOlehUid': dibuatOlehUid,
      'dibuatOlehNama': dibuatOlehNama,
      'tanggalDibuat': tanggalDibuat,
      'tanggalDiubah': tanggalDiubah,
    };
  }
}