import 'package:cloud_firestore/cloud_firestore.dart';

class CatatanPrestasiModel {
  String id;
  String uidSiswa;
  String namaSiswa;
  Timestamp tanggal;
  String deskripsiCatatan;
  String kategoriCatatan; // cth: "Prestasi", "Keaktifan", "Sikap"
  String dibuatOlehUid;
  String dibuatOlehNama;

  CatatanPrestasiModel({
    required this.id,
    required this.uidSiswa,
    required this.namaSiswa,
    required this.tanggal,
    required this.deskripsiCatatan,
    required this.kategoriCatatan,
    required this.dibuatOlehUid,
    required this.dibuatOlehNama,
  });

  factory CatatanPrestasiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CatatanPrestasiModel(
      id: doc.id,
      uidSiswa: data['uidSiswa'] ?? '',
      namaSiswa: data['namaSiswa'] ?? '',
      tanggal: data['tanggal'] ?? Timestamp.now(),
      deskripsiCatatan: data['deskripsiCatatan'] ?? '',
      kategoriCatatan: data['kategoriCatatan'] ?? 'Umum',
      dibuatOlehUid: data['dibuatOlehUid'] ?? '',
      dibuatOlehNama: data['dibuatOlehNama'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uidSiswa': uidSiswa,
      'namaSiswa': namaSiswa,
      'tanggal': tanggal,
      'deskripsiCatatan': deskripsiCatatan,
      'kategoriCatatan': kategoriCatatan,
      'dibuatOlehUid': dibuatOlehUid,
      'dibuatOlehNama': dibuatOlehNama,
    };
  }
}