// lib/app/modules/tambah_kelompok_mengaji/controllers/tambah_kelompok_mengaji_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';

class TambahKelompokMengajiController extends GetxController {
  
  // --- STATE MANAGEMENT ---
  final RxBool isGroupCreated = false.obs;
  final RxBool isProcessing = false.obs;
  final Rx<Map<String, dynamic>?> createdGroupData = Rx(null);

  // --- TEXT CONTROLLERS ---
  final TextEditingController faseC = TextEditingController();
  final TextEditingController pengampuC = TextEditingController();
  final TextEditingController tempatC = TextEditingController();
  final TextEditingController kelasSiswaC = TextEditingController();

  // --- FIREBASE & DEPENDENCIES ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late final String idUser;
  late final String emailAdmin;
  final String idSekolah = '20404148';
  final HomeController homeController = Get.find<HomeController>();

  @override
  void onInit() {
    super.onInit();
    final user = auth.currentUser;
    if (user != null) {
      idUser = user.uid;
      emailAdmin = user.email!;
    } else {
      Get.offAllNamed('/login');
      idUser = '';
      emailAdmin = '';
    }
  }

  //========================================================================
  // --- FUNGSI UTAMA YANG DIPANGGIL DARI VIEW ---
  //========================================================================

  Future<void> createGroupAndContinue() async {
    if (faseC.text.isEmpty || pengampuC.text.isEmpty || tempatC.text.isEmpty) {
      Get.snackbar('Peringatan', 'Fase, Pengampu, dan Tempat wajib diisi.');
      return;
    }
    isProcessing.value = true;
    try {
      final tahunajaranya = await getTahunAjaranTerakhir();
      final idTahunAjaran = tahunajaranya.replaceAll("/", "-");

      final checkSnapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelompokmengaji').doc(faseC.text).collection('pengampu').doc(pengampuC.text).get();
      if (checkSnapshot.exists) {
        throw Exception('Pengampu ini sudah memiliki kelompok di fase yang dipilih.');
      }

      final querySnapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').where('alias', isEqualTo: pengampuC.text).get();
      if (querySnapshot.docs.isEmpty) throw Exception("Data Pengampu tidak ditemukan!");
      final idPengampu = querySnapshot.docs.first.data()['uid'];

      await _runComplexGroupCreationWrites(idTahunAjaran, tahunajaranya, idPengampu);

      createdGroupData.value = {
        'tahunajaran': tahunajaranya, 'idTahunAjaran': idTahunAjaran,
        'fase': faseC.text, 'namapengampu': pengampuC.text,
        'idpengampu': idPengampu, 'tempatmengaji': tempatC.text,
      };

      isGroupCreated.value = true;
      Get.snackbar('Sukses', 'Kelompok berhasil dibuat. Sekarang tambahkan anggota.');
    } catch (e) {
      Get.snackbar('Error Membuat Kelompok', e.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> addSiswaToGroup(String namaSiswa, String nisnSiswa) async {
    final groupData = createdGroupData.value;
    if (groupData == null) return;
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      await _runComplexSiswaAdditionWrites(namaSiswa, nisnSiswa, groupData);
      await ubahStatusSiswa(nisnSiswa, 'aktif');
      Get.back();
      Get.snackbar('Berhasil', '$namaSiswa telah ditambahkan.');
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Gagal menambahkan siswa: $e');
    }
  }

  Future<void> deleteSiswaFromGroup(String nisnSiswa, String namaSiswa) async {
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Anda yakin ingin menghapus $namaSiswa dari kelompok ini?",
      textConfirm: "Ya, Hapus", textCancel: "Batal",
      onConfirm: () async {
        Get.back();
        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
        try {
          await _runComplexSiswaDeletionWrites(nisnSiswa);
          await ubahStatusSiswa(nisnSiswa, 'baru');
          Get.back();
          Get.snackbar("Berhasil", "$namaSiswa telah dihapus dari kelompok.");
        } catch (e) {
          Get.back();
          Get.snackbar("Error", "Gagal menghapus siswa: $e");
        }
      },
    );
  }

  Future<void> cancelEmptyGroup() async {
    Get.defaultDialog(
      title: "Konfirmasi Pembatalan",
      middleText: "Anda yakin ingin membatalkan dan menghapus kelompok ini? Aksi ini tidak bisa diurungkan.",
      textConfirm: "Ya, Batalkan & Hapus", textCancel: "Tidak",
      buttonColor: Colors.red, confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _performCancellation();
      },
    );
  }

  //========================================================================
  // --- FUNGSI PRIVATE (LOGIKA INTERNAL) ---
  //========================================================================

  Future<void> _performCancellation() async {
    final groupData = createdGroupData.value;
    if (groupData == null) { Get.snackbar("Error", "Data kelompok tidak ditemukan."); return; }
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final semesterAktif = homeController.semesterAktifId.value;
      final groupRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(groupData['idTahunAjaran']).collection('kelompokmengaji').doc(groupData['fase']).collection('pengampu').doc(groupData['namapengampu']).collection('tempat').doc(groupData['tempatmengaji']).collection('semester').doc(semesterAktif).collection('daftarsiswa');
      final snapshot = await groupRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        Get.back();
        Get.snackbar("Gagal", "Kelompok tidak bisa dibatalkan karena sudah ada anggota.", backgroundColor: Colors.orange);
        return;
      }
      await _runComplexGroupDeletionWrites(groupData);
      Get.back();
      Get.snackbar("Berhasil", "Kelompok telah dibatalkan dan dihapus.", backgroundColor: Colors.green);
      resetPage();
    } catch(e) {
      Get.back();
      Get.snackbar("Error", "Terjadi kesalahan saat membatalkan: $e", backgroundColor: Colors.red);
    }
  }

  /// [DIPERBARUI] Membuat kerangka kelompok dengan struktur semester.
  Future<void> _runComplexGroupCreationWrites(String idTahunAjaran, String tahunajaranya, String idPengampu) async {
    final semesterAktif = homeController.semesterAktifId.value;
    WriteBatch batch = firestore.batch();

    // Path 1: Membuat kerangka umum di /kelompokmengaji. Path ini tidak perlu semester.
    DocumentReference tempatRef = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(faseC.text)
        .collection('pengampu').doc(pengampuC.text)
        .collection('tempat').doc(tempatC.text);
    batch.set(tempatRef, {
      'fase': faseC.text, 'tempatmengaji': tempatC.text,
      'tahunajaran': tahunajaranya, 'namapengampu': pengampuC.text,
      'idpengampu': idPengampu, 'emailpenginput': emailAdmin,
      'idpenginput': idUser, 'tanggalinput': DateTime.now().toIso8601String(),
    });
    
    // Path 2: Menulis referensi kelompok di dokumen pegawai, di dalam folder semester.
    DocumentReference pegawaiTahunAjaranRef = firestore.collection('Sekolah').doc(idSekolah)
        .collection('pegawai').doc(idPengampu)
        .collection('tahunajarankelompok').doc(idTahunAjaran);
        
    batch.set(pegawaiTahunAjaranRef, {'namatahunajaran': tahunajaranya});

    batch.set(pegawaiTahunAjaranRef.collection('semester').doc(semesterAktif).collection('kelompokmengaji').doc(faseC.text), {
        'fase': faseC.text, 'tempatmengaji': tempatC.text, 'namapengampu': pengampuC.text,
    });
    
    await batch.commit();
  }

  /// [DIPERBARUI] Menambahkan siswa ke dalam path semester yang benar.
  Future<void> _runComplexSiswaAdditionWrites(String namaSiswa, String nisnSiswa, Map<String, dynamic> groupData) async {
    final idTahunAjaran = groupData['idTahunAjaran'];
    final semesterAktif = homeController.semesterAktifId.value;
    WriteBatch batch = firestore.batch();

    final dataSiswa = {
      'namasiswa': namaSiswa, 'nisn': nisnSiswa, 'kelas': kelasSiswaC.text, 'fase': groupData['fase'],
      'tempatmengaji': groupData['tempatmengaji'], 'tahunajaran': groupData['tahunajaran'],
      'kelompokmengaji': groupData['namapengampu'], 'namapengampu': groupData['namapengampu'],
      'idpengampu': groupData['idpengampu'], 'emailpenginput': emailAdmin,
      'idpenginput': idUser, 'tanggalinput': DateTime.now().toIso8601String(),
      'idsiswa': nisnSiswa, 'ummi': '0', 'semester': semesterAktif,
    };

    // Path 1: Menambah siswa ke dalam /kelompokmengaji/.../semester/{id}/daftarsiswa
    DocumentReference siswaDiKelompokRef = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(groupData['fase'])
        .collection('pengampu').doc(groupData['namapengampu'])
        .collection('tempat').doc(groupData['tempatmengaji'])
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').doc(nisnSiswa);
    batch.set(siswaDiKelompokRef, dataSiswa);

    // Path 2: Menulis referensi kelompok di /siswa/{nisn}/.../semester/{id}/...
    DocumentReference refDiSiswa = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(nisnSiswa)
        .collection('tahunajarankelompok').doc(idTahunAjaran);
    
    batch.set(refDiSiswa, {'namatahunajaran': groupData['tahunajaran']});
    
    batch.set(refDiSiswa.collection('semester').doc(semesterAktif).collection('kelompokmengaji').doc(groupData['fase']), {
        'fase': groupData['fase'], 'namapengampu': groupData['namapengampu'], 'tempatmengaji': groupData['tempatmengaji']
    });
    
    await batch.commit();
  }
  
  /// [DIPERBARUI] Menghapus siswa dari path semester yang benar.
  Future<void> _runComplexSiswaDeletionWrites(String nisnSiswa) async {
    final groupData = createdGroupData.value;
    if (groupData == null) return;
    final semesterAktif = homeController.semesterAktifId.value;
    WriteBatch batch = firestore.batch();
    
    DocumentReference siswaDiKelompokRef = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(groupData['idTahunAjaran'])
        .collection('kelompokmengaji').doc(groupData['fase'])
        .collection('pengampu').doc(groupData['namapengampu'])
        .collection('tempat').doc(groupData['tempatmengaji'])
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').doc(nisnSiswa);
    batch.delete(siswaDiKelompokRef);

    DocumentReference refDiSiswa = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(nisnSiswa)
        .collection('tahunajarankelompok').doc(groupData['idTahunAjaran']);
    batch.delete(refDiSiswa.collection('semester').doc(semesterAktif).collection('kelompokmengaji').doc(groupData['fase']));
    
    await batch.commit();
  }

  /// [LENGKAP] Menghapus kerangka kelompok, termasuk referensi di pegawai.
  Future<void> _runComplexGroupDeletionWrites(Map<String, dynamic> groupData) async {
    final semesterAktif = homeController.semesterAktifId.value;
    final idTahunAjaran = groupData['idTahunAjaran'];
    final idPengampu = groupData['idpengampu'];
    final fase = groupData['fase'];
    final namaPengampu = groupData['namapengampu'];
    final tempat = groupData['tempatmengaji'];

    WriteBatch batch = firestore.batch();

    // --- Path 1: Hapus kerangka utama di /kelompokmengaji ---
    
    // Definisikan path ke dokumen 'tempat'
    DocumentReference tempatRef = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(fase)
        .collection('pengampu').doc(namaPengampu)
        .collection('tempat').doc(tempat);
        
    // Definisikan path ke dokumen 'pengampu'
    DocumentReference pengampuRef = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(fase)
        .collection('pengampu').doc(namaPengampu);
        
    // Definisikan path ke dokumen 'fase'
    DocumentReference faseRef = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(fase);

    // Tambahkan semua ke batch untuk dihapus
    batch.delete(tempatRef);
    batch.delete(pengampuRef);
    batch.delete(faseRef);

    // --- Path 2: Hapus referensi di dokumen pegawai ---
    DocumentReference refDiPegawai = firestore.collection('Sekolah').doc(idSekolah)
        .collection('pegawai').doc(idPengampu)
        .collection('tahunajarankelompok').doc(idTahunAjaran)
        .collection('semester').doc(semesterAktif)
        .collection('kelompokmengaji').doc(fase);
    batch.delete(refDiPegawai);

    // Commit semua operasi hapus sekaligus
    await batch.commit();
  }
  
  //========================================================================
  // --- FUNGSI HELPER LAINNYA ---
  //========================================================================

   Future<List<String>> getDataPengampu() async {
    List<String> pengampuList = [];
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').where('role', isEqualTo: 'Pengampu').get();
    for (var doc in snapshot.docs) {
      pengampuList.add(doc.data()['alias']);
    }
    return pengampuList;
  }

  Future<List<String>> getDataFase() async => ['Fase A', 'Fase B', 'Fase C'];

  Future<List<String>> getDataTempat() async => ['masjid', 'aula', 'kelas', 'lab', 'dll'];

  Future<List<String>> getDataKelasYangAda() async {
    if (createdGroupData.value == null) return [];
    final idTahunAjaran = homeController.idTahunAjaran.value;
    final fase = createdGroupData.value!['fase'];
    List<String> kelasList = [];
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran')
        .where('fase', isEqualTo: fase).get();
    for (var doc in snapshot.docs) { kelasList.add(doc.id); }
    return kelasList;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAddedSiswa() {
    final groupData = createdGroupData.value;
    if (groupData == null) return const Stream.empty();
    
    return firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(groupData['idTahunAjaran'])
        .collection('kelompokmengaji').doc(groupData['fase'])
        .collection('pengampu').doc(groupData['namapengampu'])
        .collection('tempat').doc(groupData['tempatmengaji'])
        .collection('semester').doc(homeController.semesterAktifId.value)
        .collection('daftarsiswa').orderBy('tanggalinput', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSiswaBaru() {
    if (kelasSiswaC.text.isEmpty) return const Stream.empty();
    final groupData = createdGroupData.value;
    if (groupData == null) return const Stream.empty();

    return firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(groupData['idTahunAjaran'])
        .collection('kelastahunajaran').doc(kelasSiswaC.text)
        .collection('daftarsiswa').where('statuskelompok', isEqualTo: 'baru').snapshots();
  }

  void finishAndGoBack() {
    Get.back();
  }

  Future<String> getTahunAjaranTerakhir() async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').orderBy('namatahunajaran', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) throw Exception("Data tahun ajaran tidak ditemukan.");
    return snapshot.docs.first.data()['namatahunajaran'];
  }
  
  Future<void> ubahStatusSiswa(String nisnSiswa, String newStatus) async {
    // Ambil data yang kita butuhkan dari state controller
    final groupData = createdGroupData.value;
    final kelasId = kelasSiswaC.text;

    // Pengaman: pastikan semua data yang dibutuhkan ada
    if (groupData == null || kelasId.isEmpty) {
      throw Exception("Tidak bisa mengubah status siswa: data kelas tidak lengkap.");
    }
    
    final idTahunAjaran = groupData['idTahunAjaran'];

    // Bangun referensi langsung ke dokumen siswa yang akan di-update
    final DocumentReference siswaRef = firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(kelasId)
        .collection('daftarsiswa').doc(nisnSiswa);

    // Lakukan update
    await siswaRef.update({
      'statuskelompok': newStatus,
    });
  }

  void resetPage() {
    isGroupCreated.value = false;
    createdGroupData.value = null;
    faseC.clear(); pengampuC.clear(); tempatC.clear(); kelasSiswaC.clear();
  }
}