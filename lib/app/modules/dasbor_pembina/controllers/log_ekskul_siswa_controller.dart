import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/home/controllers/home_controller.dart';
import 'package:uuid/uuid.dart';
import '../../../models/catatan_prestasi_model.dart';
import '../../../models/siswa_model.dart';

class LogEkskulSiswaController extends GetxController {
  final String instanceEkskulId;
  final SiswaModel siswa;
  LogEkskulSiswaController({required this.instanceEkskulId, required this.siswa});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final Uuid _uuid = const Uuid();

  late final CollectionReference _catatanRef;
  
  final RxBool isLoading = false.obs;
  final RxList<CatatanPrestasiModel> daftarCatatan = <CatatanPrestasiModel>[].obs;

  // Form State
  final TextEditingController deskripsiC = TextEditingController();
  final Rxn<String> selectedKategori = Rxn<String>();
  final Rxn<DateTime> selectedTanggal = Rxn<DateTime>(DateTime.now());

  final List<String> kategoriOptions = ['Prestasi', 'Keaktifan', 'Sikap', 'Pelanggaran', 'Umum'];

  @override
  void onInit() {
    super.onInit();
    final idSekolah = homeC.idSekolah;
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    
    _catatanRef = _firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('ekstrakurikuler').doc(instanceEkskulId)
        .collection('catatan_prestasi');
        
    fetchCatatan();
  }

  Future<void> fetchCatatan() async {
    isLoading.value = true;
    try {
      final snapshot = await _catatanRef
          .where('uidSiswa', isEqualTo: siswa.nisn) // Hanya ambil catatan milik siswa ini
          .orderBy('tanggal', descending: true)
          .get();
      daftarCatatan.value = snapshot.docs
          .map((doc) => CatatanPrestasiModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print(e);
      Get.snackbar("Error", "Gagal memuat catatan: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveCatatan({String? catatanId}) async {
    if (deskripsiC.text.isEmpty || selectedKategori.value == null) {
      Get.snackbar("Peringatan", "Kategori dan Deskripsi wajib diisi.");
      return;
    }
    
    final isUpdate = catatanId != null;
    final id = catatanId ?? _uuid.v4();
    
    final user = await _firestore.collection('Sekolah').doc(homeC.idSekolah).collection('pegawai').doc(homeC.idUser).get();
    final namaPembina = user.data()?['nama'] ?? 'Pembina';

    final data = {
      'uidSiswa': siswa.nisn,
      'namaSiswa': siswa.nama,
      'tanggal': Timestamp.fromDate(selectedTanggal.value!),
      'deskripsiCatatan': deskripsiC.text,
      'kategoriCatatan': selectedKategori.value,
      'dibuatOlehUid': homeC.idUser,
      'dibuatOlehNama': namaPembina,
    };
    
    try {
      await _catatanRef.doc(id).set(data, SetOptions(merge: true));
      Get.back(); // Tutup dialog
      fetchCatatan();
      Get.snackbar("Berhasil", "Catatan berhasil disimpan.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan catatan: $e");
    }
  }

  Future<void> deleteCatatan(String catatanId) async {
    try {
      await _catatanRef.doc(catatanId).delete();
      // Hapus item dari list di UI secara instan untuk responsivitas
      daftarCatatan.removeWhere((c) => c.id == catatanId);
      Get.snackbar("Berhasil", "Catatan telah dihapus.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus catatan: $e");
    }
  }

  void fillFormForEdit(CatatanPrestasiModel catatan) {
    deskripsiC.text = catatan.deskripsiCatatan;
    selectedKategori.value = catatan.kategoriCatatan;
    selectedTanggal.value = catatan.tanggal.toDate();
  }
}