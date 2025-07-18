// lib/app/models/jurnal_model.dart

class JurnalModel {
  final String? materipelajaran;
  final String? namapenginput;
  final String? jampelajaran;
  final String? catatanjurnal; // <-- TAMBAHAN BARU

  JurnalModel({
    this.materipelajaran,
    this.namapenginput,
    this.jampelajaran,
    this.catatanjurnal, // <-- TAMBAHAN BARU
  });

  factory JurnalModel.fromFirestore(Map<String, dynamic> data) {
    return JurnalModel(
      materipelajaran: data['materipelajaran'] as String?,
      namapenginput: data['namapenginput'] as String?,
      jampelajaran: data['jampelajaran'] as String?,
      // Ambil data 'catatanjurnal' dari Firestore
      catatanjurnal: data['catatanjurnal'] as String?, // <-- TAMBAHAN BARU
    );
  }
}