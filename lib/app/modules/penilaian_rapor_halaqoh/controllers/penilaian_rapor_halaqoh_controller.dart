// File: lib/app/modules/penilaian_rapor_halaqoh/controllers/penilaian_rapor_halaqoh_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/base/base_penilaian_controller.dart';

import '../../../models/siswa_model.dart';

class PenilaianRaporHalaqohController extends BasePenilaianController<int> {
  // Terima satu Map argumen yang fleksibel
  final Map<String, dynamic> argumenNavigasi;
  PenilaianRaporHalaqohController({required this.argumenNavigasi});

  // Properti yang akan diekstrak dari argumen
  late final String jenisHalaqoh;
  late final String idKelas;
  Map<String, dynamic>? infoKelompokTahsin;

  late final String _semesterField;

  @override
  void onInit(){
    // "Bongkar" argumen untuk mengisi properti
    jenisHalaqoh = argumenNavigasi['jenisHalaqoh'];
    idKelas = argumenNavigasi['idKelas'];
    infoKelompokTahsin = argumenNavigasi['infoKelompok'];
    
    _semesterField = jenisHalaqoh == 'Tahsin' ? 'nilai_tahsin' : 'nilai_tahfidz';
    super.onInit();
  }

  // --- IMPLEMENTASI KONTRAK DARI BASE CONTROLLER ---

  // @override
  // Future<List<SiswaModel>> getSiswaList() async {
  //   // Di sini, Anda akan mengambil daftar siswa yang relevan untuk dinilai
  //   // Contoh: mengambil semua siswa di `idKelas`
  //   final idTahunAjaran = homeC.idTahunAjaran.value!;
  //   final semester = homeC.semesterAktifId.value;
  //   final snapshot = await firestore
  //       .collection('Sekolah').doc(homeC.idSekolah)
  //       .collection('tahunajaran').doc(idTahunAjaran)
  //       .collection('kelastahunajaran').doc(idKelas)
  //       .collection('semester').doc(semester)
  //       .collection('daftarsiswa').orderBy('namasiswa').get();

  //   return snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList();
  // }

  @override
  Future<List<SiswaModel>> getSiswaList() async {
    if (jenisHalaqoh == 'Tahsin') {
      return _getSiswaListForTahsin();
    } else { // Tahfidz
      return _getSiswaListForTahfidz();
    }
  }

  /// [LOGIKA KHUSUS TAHSIN] Mengambil siswa dari kelompok halaqoh spesifik.
  Future<List<SiswaModel>> _getSiswaListForTahsin() async {
    final kelompok = infoKelompokTahsin!;
    final refSiswa = firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelompokmengaji').doc(kelompok['fase'])
        .collection('pengampu').doc(homeC.idUser)
        .collection('tempat').doc(kelompok['tempatmengaji'])
        .collection('semester').doc(homeC.semesterAktifId.value)
        .collection('daftarsiswa');
    
    final snapshot = await refSiswa.orderBy('namasiswa').get();
    return snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList();
  }

  /// [LOGIKA KHUSUS TAHFIDZ] Mengambil siswa berdasarkan peran (Wali Kelas / Pendamping).
  Future<List<SiswaModel>> _getSiswaListForTahfidz() async {
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    final semester = homeC.semesterAktifId.value;
    final kelasDocRef = firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(idKelas);

    final kelasDoc = await kelasDocRef.get();
    if (!kelasDoc.exists) return [];

    final delegasiSiswaMap = Map<String, List<dynamic>>.from(kelasDoc.data()?['tahfidz_info']?['delegasi_siswa'] ?? {});
    final allSiswaRef = kelasDocRef.collection('semester').doc(semester).collection('daftarsiswa');

    // Cek peran pengguna
    if (homeC.walikelas) {
      // WALI KELAS: Ambil siswa yang TIDAK didelegasikan
      final semuaNisnDelegasi = delegasiSiswaMap.values.expand((list) => list).toSet();
      if (semuaNisnDelegasi.isEmpty) {
        // Jika tidak ada delegasi sama sekali, wali kelas mengelola semua
        final snapshot = await allSiswaRef.orderBy('namasiswa').get();
        return snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList();
      }
      // Jika ada delegasi, ambil siswa yang NISN-nya tidak ada di daftar delegasi
      final snapshot = await allSiswaRef.where(FieldPath.documentId, whereNotIn: semuaNisnDelegasi.toList()).get();
      return snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList();
    } else {
      // PENDAMPING: Ambil hanya siswa yang didelegasikan kepadanya
      final nisnBinaanSaya = delegasiSiswaMap[homeC.idUser];
      if (nisnBinaanSaya == null || nisnBinaanSaya.isEmpty) {
        return []; // Tidak punya siswa binaan
      }
      final snapshot = await allSiswaRef.where(FieldPath.documentId, whereIn: nisnBinaanSaya).get();
      return snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList();
    }
  }

  @override
  Future<Map<String, dynamic>?> getExistingPenilaian(String nisn) async {
    final doc = await getFirestoreDocRef(nisn).get();
    return doc.data() as Map<String, dynamic>?;
  }
  
  @override
  int? parseNilai(Map<String, dynamic> data) {
    final nilaiData = data[_semesterField] as Map<String, dynamic>?;
    return (nilaiData?['nilaiAkhir'] as num?)?.toInt();
  }

  @override
  String? parseKeterangan(Map<String, dynamic> data) {
    final nilaiData = data[_semesterField] as Map<String, dynamic>?;
    return nilaiData?['deskripsi'];
  }

  @override
  Map<String, dynamic> buildUpdateData(int? nilai, String keterangan) {
    // Membangun struktur Map yang akan disimpan di Firestore
    return {
      _semesterField: {
        'nilaiAkhir': nilai,
        'deskripsi': keterangan,
      }
    };
  }
  
  @override
  DocumentReference getFirestoreDocRef(String nisn) {
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    final semester = homeC.semesterAktifId.value;
    // Path ke dokumen siswa di mana nilai rapornya disimpan
    return firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('semester').doc(semester)
        .collection('daftarsiswa').doc(nisn);
  }
}