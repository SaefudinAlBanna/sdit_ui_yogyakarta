// lib/app/modules/tambah_kelompok_mengaji/controllers/tambah_kelompok_mengaji_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';

class TambahKelompokMengajiController extends GetxController {
  // --- DEPENDENSI ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final HomeController homeController = Get.find<HomeController>();

  // --- STATE FORM & UI ---
  final RxBool isProcessing = false.obs;
  final RxBool isGroupCreated = false.obs;
  final RxBool isFaseSelected = false.obs;

  final TextEditingController faseC = TextEditingController();
  final TextEditingController tempatC = TextEditingController();
  final TextEditingController pengampuC = TextEditingController();
  final TextEditingController kelasSiswaC = TextEditingController();

  final Rx<Map<String, dynamic>?> selectedPengampuData =
      Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> availablePengampu =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, Map<String, dynamic>> siswaTerpilih =
      <String, Map<String, dynamic>>{}.obs;
  final Rx<Map<String, dynamic>?> createdGroupData = Rx(null);

  // --- STATE MANAGEMENT ---
  final RxString kelasAktifDiSheet = ''.obs;
  final RxList<String> availableKelas = <String>[].obs;
  final RxString searchQueryInSheet = ''.obs;

  late final String idUser;
  late final String emailAdmin;
  final String idSekolah = '20404148';

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

  Future<void> openSiswaPicker(BuildContext context) async {
    siswaTerpilih.clear();
    searchQueryInSheet.value = '';
    availableKelas.clear();
    kelasAktifDiSheet.value = '';
    final kelas = await getDataKelasYangAda();
    availableKelas.assignAll(kelas);
    if (availableKelas.isNotEmpty) {
      kelasAktifDiSheet.value = availableKelas.first;
    }
  }

  Future<void> fetchAvailablePengampu(String fase) async {
    isFaseSelected.value = true;
    isProcessing.value = true;
    availablePengampu.clear();
    selectedPengampuData.value = null;
    try {
      final idTahunAjaran = (await getTahunAjaranTerakhir()).replaceAll("/", "-");

      // --- PERUBAHAN UTAMA DI SINI ---
      // 1. Jalankan dua query secara bersamaan
      final results = await Future.wait([
        firestore.collection('Sekolah').doc(homeController.idSekolah)
                 .collection('pegawai').where('role', isEqualTo: 'Pengampu').get(),

        firestore.collection('Sekolah').doc(homeController.idSekolah)
                 .collection('pegawai').where('tugas', arrayContains: 'Pengampu').get(),
      ]);

      final allPengampuByRole = results[0].docs;
      final allPengampuByTugas = results[1].docs;

      // 2. Gabungkan hasilnya dan hilangkan duplikasi menggunakan Map
      final Map<String, Map<String, dynamic>> pengampuMap = {};
      for (var doc in allPengampuByRole) {
        pengampuMap[doc.id] = {'uid': doc.id, 'alias': doc.data()['alias'] as String};
      }
      for (var doc in allPengampuByTugas) {
        pengampuMap[doc.id] = {'uid': doc.id, 'alias': doc.data()['alias'] as String};
      }
      final List<Map<String, dynamic>> semuaPengampu = pengampuMap.values.toList();
      // --- AKHIR PERUBAHAN ---

      // 3. Filter pengampu yang sudah ditugaskan (logika ini tetap sama)
      final assignedPengampuSnapshot = await firestore
          .collection('Sekolah').doc(homeController.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(fase)
          .collection('pengampu').get();
      
      final Set<String> uidPengampuDitugaskan = assignedPengampuSnapshot.docs.map((doc) => doc.id).toSet();
      final List<Map<String, dynamic>> pengampuTersedia = semuaPengampu
          .where((pengampu) => !uidPengampuDitugaskan.contains(pengampu['uid']))
          .toList();

      availablePengampu.assignAll(pengampuTersedia);

    } catch(e) {
      Get.snackbar("Error", "Gagal memuat daftar pengampu: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  void toggleSiswaSelection(Map<String, dynamic> siswaData) {
    final nisn = siswaData['nisn'];
    if (siswaTerpilih.containsKey(nisn)) {
      siswaTerpilih.remove(nisn);
    } else {
      siswaTerpilih[nisn] = siswaData;
    }
  }

  void gantiKelasDiSheet(String kelasBaru) {
    if (kelasAktifDiSheet.value == kelasBaru) return;
    if (siswaTerpilih.isNotEmpty) {
      Get.defaultDialog(
        title: "Simpan Pilihan?",
        middleText:
            "Anda memiliki ${siswaTerpilih.length} siswa yang sudah dipilih. Simpan sebelum pindah kelas?",
        textConfirm: "Ya, Simpan & Pindah",
        textCancel: "Pindah & Hapus Pilihan",
        onConfirm: () async {
          Get.back();
          await simpanSiswaTerpilih();
          kelasAktifDiSheet.value = kelasBaru;
        },
        onCancel: () {
          siswaTerpilih.clear();
          kelasAktifDiSheet.value = kelasBaru;
        },
      );
    } else {
      kelasAktifDiSheet.value = kelasBaru;
    }
  }

  Future<void> simpanSiswaTerpilih() async {
    final groupData = createdGroupData.value;
    if (groupData == null || siswaTerpilih.isEmpty) return;
    isProcessing.value = true;
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final semesterAktif = homeController.semesterAktifId.value;
      final idTahunAjaran = groupData['idTahunAjaran'];
      WriteBatch batch = firestore.batch();

      for (var siswa in siswaTerpilih.values) {
        _addSiswaToBatch(
          batch,
          siswa['namasiswa'],
          siswa['nisn'],
          siswa['kelas'],
          groupData,
          semesterAktif,
        );
        _updateStatusSiswaInBatch(
          batch,
          siswa['nisn'],
          'aktif',
          idTahunAjaran,
          siswa['kelas'],
          semesterAktif,
        );
      }

      await batch.commit();
      Get.back();
      Get.snackbar(
        "Berhasil",
        "${siswaTerpilih.length} siswa telah ditambahkan.",
      );
      siswaTerpilih.clear();
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Gagal menambahkan siswa: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  // void _addSiswaToBatch(WriteBatch batch, String namaSiswa, String nisnSiswa, String kelasSiswa, Map<String, dynamic> groupData, String semesterAktif) {
  //   final idTahunAjaran = groupData['idTahunAjaran'];
  //   final idPengampu = groupData['idpengampu'];
  //   final namaPengampu = groupData['namapengampu'];
    
  //   final dataSiswa = {
  //     'namasiswa': namaSiswa, 'nisn': nisnSiswa, 'kelas': kelasSiswa, 'fase': groupData['fase'],
  //     'tempatmengaji': groupData['tempatmengaji'], 'tahunajaran': groupData['tahunajaran'],
  //     'namapengampu': namaPengampu, 'idpengampu': idPengampu,
  //     'emailpenginput': homeController.auth.currentUser!.email,
  //     'idpenginput': homeController.auth.currentUser!.uid, 'tanggalinput': DateTime.now().toIso8601String(),
  //     'idsiswa': nisnSiswa, 'ummi': '0', 'semester': semesterAktif,
  //   };

  //   // Path 1: Menambah siswa ke kelompok (tidak berubah)
  //   DocumentReference siswaDiKelompokRef = firestore.collection('Sekolah').doc(homeController.idSekolah)
  //       .collection('tahunajaran').doc(idTahunAjaran)
  //       .collection('kelompokmengaji').doc(groupData['fase'])
  //       .collection('pengampu').doc(idPengampu)
  //       .collection('tempat').doc(groupData['tempatmengaji'])
  //       .collection('semester').doc(semesterAktif)
  //       .collection('daftarsiswa').doc(nisnSiswa);
  //   batch.set(siswaDiKelokRef, dataSiswa);

  //   // Path 2: Membuat "Jalan Pintas" di dokumen SISWA
  //   DocumentReference refDiSiswa = firestore.collection('Sekolah').doc(homeController.idSekolah).collection('siswa').doc(nisnSiswa)
  //       .collection('tahunajarankelompok').doc(idTahunAjaran);
    
  //   batch.set(refDiSiswa, {'namatahunajaran': groupData['tahunajaran']});
    
  //   // --- PERBAIKAN UTAMA DI SINI ---
  //   // Simpan data lengkap di dalam "jalan pintas" siswa
  //   batch.set(refDiSiswa.collection('semester').doc(semesterAktif).collection('kelompokmengaji').doc(groupData['fase']), {
  //       'fase': groupData['fase'],
  //       'tempatmengaji': groupData['tempatmengaji'],
  //       'namapengampu': namaPengampu,
  //       'idpengampu': idPengampu, // <-- FIELD PENTING YANG DITAMBAHKAN
  //   });
  // }

  void _addSiswaToBatch(
    WriteBatch batch,
    String namaSiswa,
    String nisnSiswa,
    String kelasSiswa,
    Map<String, dynamic> groupData,
    String semesterAktif,
   ) {
    final idTahunAjaran = groupData['idTahunAjaran'];
    final idPengampu = groupData['idpengampu']; 
    final namaPengampu = groupData['namapengampu'];

      final dataSiswa = {
      'namasiswa': namaSiswa, 
      'nisn': nisnSiswa, 
      'kelas': kelasSiswa, 
      'fase': groupData['fase'],
      'tempatmengaji': groupData['tempatmengaji'], 
      'tahunajaran': groupData['tahunajaran'],
      'namapengampu': namaPengampu, 
      'idpengampu': idPengampu,
      'emailpenginput': homeController.auth.currentUser!.email,
      'idpenginput': homeController.auth.currentUser!.uid, 
      'tanggalinput': DateTime.now().toIso8601String(),
      'idsiswa': nisnSiswa, 
      'ummi': '0', 
      'semester': semesterAktif,
    };

      DocumentReference siswaDiKelompokRef = firestore.collection('Sekolah').doc(homeController.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(groupData['fase'])
        .collection('pengampu').doc(idPengampu)
        .collection('tempat').doc(groupData['tempatmengaji'])
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').doc(nisnSiswa);

    batch.set(siswaDiKelompokRef, dataSiswa);
    DocumentReference refDiSiswa = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .doc(nisnSiswa)
        .collection('tahunajarankelompok')
        .doc(idTahunAjaran);
    batch.set(refDiSiswa, {'namatahunajaran': groupData['tahunajaran']});
    batch.set(
      refDiSiswa
          .collection('semester')
          .doc(semesterAktif)
          .collection('kelompokmengaji')
          .doc(groupData['fase']),
      {
        'fase': groupData['fase'],
        'namapengampu': groupData['namapengampu'],
        'tempatmengaji': groupData['tempatmengaji'],
        'idpengampu': idPengampu,
      },
    );
  }

  void _updateStatusSiswaInBatch(
    WriteBatch batch,
    String nisnSiswa,
    String newStatus,
    String idTahunAjaran,
    String kelasId,
    String semesterId,
  ) {
    final DocumentReference siswaRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(kelasId)
        .collection('semester')
        .doc(semesterId)
        .collection('daftarsiswa')
        .doc(nisnSiswa);
    batch.update(siswaRef, {'statuskelompok': newStatus});
  }

  //========================================================================
  // --- FUNGSI UTAMA YANG DIPANGGIL DARI VIEW ---
  //========================================================================

  Future<void> createGroupAndContinue() async {
    if (faseC.text.isEmpty ||
        selectedPengampuData.value == null ||
        tempatC.text.isEmpty) {
      Get.snackbar('Peringatan', 'Fase, Pengampu, dan Tempat wajib diisi.');
      return;
    }
    isProcessing.value = true;
    try {
      final String tahunajaranya = await getTahunAjaranTerakhir();
      final String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
      final String idPengampu = selectedPengampuData.value!['uid'];
      final String aliasPengampu = selectedPengampuData.value!['alias'];

      // Cek ulang untuk mencegah duplikasi (safe guard)
      final checkSnapshot =
          await firestore
              .collection('Sekolah')
              .doc(homeController.idSekolah)
              .collection('tahunajaran')
              .doc(idTahunAjaran)
              .collection('kelompokmengaji')
              .doc(faseC.text)
              .collection('pengampu')
              .doc(idPengampu)
              .get(); // Cek berdasarkan UID

      if (checkSnapshot.exists)
        throw Exception(
          'Pengampu ini sudah memiliki kelompok di fase yang dipilih.',
        );

      await _runComplexGroupCreationWrites(
        idTahunAjaran,
        tahunajaranya,
        idPengampu,
        aliasPengampu,
      );

      createdGroupData.value = {
        'tahunajaran': tahunajaranya,
        'idTahunAjaran': idTahunAjaran,
        'fase': faseC.text,
        'namapengampu': aliasPengampu,
        'idpengampu': idPengampu,
        'tempatmengaji': tempatC.text,
      };

      isGroupCreated.value = true;
      Get.snackbar(
        'Sukses',
        'Kelompok berhasil dibuat. Sekarang tambahkan anggota.',
      );
    } catch (e) {
      Get.snackbar('Error Membuat Kelompok', e.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> addSiswaToGroup(String namaSiswa, String nisnSiswa) async {
    final groupData = createdGroupData.value;
    if (groupData == null) return;
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      await _runComplexSiswaAdditionWrites(namaSiswa, nisnSiswa, groupData);
      // Ambil kelas dari text controller dan kirimkan sebagai argumen ke-3
      await ubahStatusSiswa(nisnSiswa, 'aktif', kelasSiswaC.text);
      Get.back();
      Get.snackbar('Berhasil', '$namaSiswa telah ditambahkan.');
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Gagal menambahkan siswa: $e');
    }
  }

  Future<void> deleteSiswaFromGroup(
    String nisnSiswa,
    String namaSiswa,
    String kelasSiswa,
  ) async {
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Anda yakin ingin menghapus $namaSiswa dari kelompok ini?",
      textConfirm: "Ya, Hapus",
      textCancel: "Batal",
      onConfirm: () async {
        Get.back();
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        try {
          await _runComplexSiswaDeletionWrites(nisnSiswa);
          // Panggil fungsi ubah status yang baru dengan parameter kelasSiswa
          await ubahStatusSiswa(nisnSiswa, 'baru', kelasSiswa);
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
      middleText: "Anda yakin ingin membatalkan dan menghapus kelompok ini?",
      textConfirm: "Ya, Batalkan & Hapus",
      textCancel: "Tidak",
      buttonColor: Colors.red,
      confirmTextColor: Colors.white,
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
    if (groupData == null) {
      Get.snackbar("Error", "Data kelompok tidak ditemukan.");
      return;
    }
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final semesterAktif = homeController.semesterAktifId.value;
      final groupRef = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(groupData['idTahunAjaran'])
          .collection('kelompokmengaji')
          .doc(groupData['fase'])
          .collection('pengampu')
          .doc(groupData['namapengampu'])
          .collection('tempat')
          .doc(groupData['tempatmengaji'])
          .collection('semester')
          .doc(semesterAktif)
          .collection('daftarsiswa');
      final snapshot = await groupRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        Get.back();
        Get.snackbar(
          "Gagal",
          "Kelompok tidak bisa dibatalkan karena sudah ada anggota.",
        );
        return;
      }
      await _runComplexGroupDeletionWrites(groupData);
      Get.back();
      Get.snackbar("Berhasil", "Kelompok telah dibatalkan dan dihapus.");
      resetPage();
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Terjadi kesalahan saat membatalkan: $e");
    }
  }

  
  Future<void> _runComplexGroupCreationWrites(String idTahunAjaran, String tahunajaranya, String idPengampu, String aliasPengampu) async {
    final semesterAktif = homeController.semesterAktifId.value;
    WriteBatch batch = firestore.batch();
    
    // Path 1: Membuat dokumen pengampu di dalam kelompok (tidak berubah)
    DocumentReference pengampuRef = firestore.collection('Sekolah').doc(homeController.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(faseC.text)
        .collection('pengampu').doc(idPengampu);
    batch.set(pengampuRef, {'namaPengampu': aliasPengampu, 'uidPengampu': idPengampu, 'createdAt': Timestamp.now()});
    
    // Path 2: Membuat dokumen tempat di dalam pengampu (tidak berubah)
    DocumentReference tempatRef = pengampuRef.collection('tempat').doc(tempatC.text);
      batch.set(tempatRef, {
      'fase': faseC.text, 
      'tempatmengaji': tempatC.text, 
      'tahunajaran': idTahunAjaran,
      'namapengampu': aliasPengampu, 
      'idpengampu': idPengampu, 
      'emailpenginput': homeController.auth.currentUser!.email, 
      'idpenginput': homeController.auth.currentUser!.uid, 
      'tanggalinput': DateTime.now().toIso8601String(),
    });
    
    // Path 3: Membuat "Jalan Pintas" di dokumen PEGAWAI
    DocumentReference pegawaiTahunAjaranRef = firestore.collection('Sekolah').doc(homeController.idSekolah)
        .collection('pegawai').doc(idPengampu).collection('tahunajarankelompok').doc(idTahunAjaran);
    
    batch.set(pegawaiTahunAjaranRef, {'namatahunajaran': tahunajaranya});
    
    // Simpan data lengkap di dalam "jalan pintas" pegawai
    batch.set(pegawaiTahunAjaranRef.collection('semester').doc(semesterAktif).collection('kelompokmengaji').doc(faseC.text), {
        'fase': faseC.text,
        'tempatmengaji': tempatC.text,
        'namapengampu': aliasPengampu,
        'idpengampu': idPengampu,
    });
    
    await batch.commit();
  }


  // [DIPERBARUI] Menambahkan siswa ke dalam path semester yang benar.
  Future<void> _runComplexSiswaAdditionWrites(
    String namaSiswa,
    String nisnSiswa,
    Map<String, dynamic> groupData,
  ) async {
    final idTahunAjaran = groupData['idTahunAjaran'];
    final semesterAktif = homeController.semesterAktifId.value;
    WriteBatch batch = firestore.batch();

    final dataSiswa = {
      'namasiswa': namaSiswa,
      'nisn': nisnSiswa,
      'kelas': kelasSiswaC.text,
      'fase': groupData['fase'],
      'tempatmengaji': groupData['tempatmengaji'],
      'tahunajaran': groupData['tahunajaran'],
      'kelompokmengaji': groupData['namapengampu'],
      'namapengampu': groupData['namapengampu'],
      'idpengampu': groupData['idpengampu'],
      'emailpenginput': emailAdmin,
      'idpenginput': idUser,
      'tanggalinput': DateTime.now().toIso8601String(),
      'idsiswa': nisnSiswa,
      'ummi': '0',
      'semester': semesterAktif,
    };

    // Path 1: Menambah siswa ke dalam /kelompokmengaji/.../semester/{id}/daftarsiswa
    DocumentReference siswaDiKelompokRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(groupData['fase'])
        .collection('pengampu')
        .doc(groupData['namapengampu'])
        .collection('tempat')
        .doc(groupData['tempatmengaji'])
        .collection('semester')
        .doc(semesterAktif)
        .collection('daftarsiswa')
        .doc(nisnSiswa);
    batch.set(siswaDiKelompokRef, dataSiswa);

    // Path 2: Menulis referensi kelompok di /siswa/{nisn}/.../semester/{id}/...
    DocumentReference refDiSiswa = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .doc(nisnSiswa)
        .collection('tahunajarankelompok')
        .doc(idTahunAjaran);

    batch.set(refDiSiswa, {'namatahunajaran': groupData['tahunajaran']});

    batch.set(
      refDiSiswa
          .collection('semester')
          .doc(semesterAktif)
          .collection('kelompokmengaji')
          .doc(groupData['fase']),
      {
        'fase': groupData['fase'],
        'namapengampu': groupData['namapengampu'],
        'tempatmengaji': groupData['tempatmengaji'],
      },
    );

    await batch.commit();
  }

  // [DIPERBARUI] Menghapus siswa dari path semester yang benar.

  Future<void> _runComplexSiswaDeletionWrites(String nisnSiswa) async {
    final groupData = createdGroupData.value;
    if (groupData == null) return;
    final semesterAktif = homeController.semesterAktifId.value;
    WriteBatch batch = firestore.batch();
    DocumentReference siswaDiKelompokRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(groupData['idTahunAjaran'])
        .collection('kelompokmengaji')
        .doc(groupData['fase'])
        .collection('pengampu')
        .doc(groupData['idpengampu'])
        .collection('tempat')
        .doc(groupData['tempatmengaji'])
        .collection('semester')
        .doc(semesterAktif)
        .collection('daftarsiswa')
        .doc(nisnSiswa);
    batch.delete(siswaDiKelompokRef);
    DocumentReference refDiSiswa = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .doc(nisnSiswa)
        .collection('tahunajarankelompok')
        .doc(groupData['idTahunAjaran']);
    batch.delete(
      refDiSiswa
          .collection('semester')
          .doc(semesterAktif)
          .collection('kelompokmengaji')
          .doc(groupData['fase']),
    );
    await batch.commit();
  }

  // [LENGKAP] Menghapus kerangka kelompok, termasuk referensi di pegawai.
  Future<void> _runComplexGroupDeletionWrites(
    Map<String, dynamic> groupData,
  ) async {
    final idTahunAjaran = groupData['idTahunAjaran'];
    final idPengampu = groupData['idpengampu'];
    final fase = groupData['fase'];
    final namaPengampu = groupData['namapengampu'];
    final tempat = groupData['tempatmengaji'];
    WriteBatch batch = firestore.batch();
    DocumentReference tempatRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(fase)
        .collection('pengampu')
        .doc(idPengampu)
        .collection('tempat')
        .doc(tempat);
    DocumentReference pengampuRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(fase)
        .collection('pengampu')
        .doc(idPengampu);
    DocumentReference faseRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(fase);
    batch.delete(tempatRef);
    batch.delete(pengampuRef);
    // batch.delete(faseRef);
    DocumentReference refDiPegawai = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idPengampu)
        .collection('tahunajarankelompok')
        .doc(idTahunAjaran)
        .collection('semester')
        .doc(homeController.semesterAktifId.value)
        .collection('kelompokmengaji')
        .doc(fase);
    batch.delete(refDiPegawai);
    await batch.commit();
  }

  //========================================================================
  // --- FUNGSI HELPER LAINNYA ---
  //========================================================================

  Future<List<String>> getDataPengampu() async {
    List<String> pengampuList = [];
    final snapshot =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .where('role', isEqualTo: 'Pengampu')
            .get();
    for (var doc in snapshot.docs) {
      pengampuList.add(doc.data()['alias']);
    }
    return pengampuList;
  }

  Future<List<String>> getDataFase() async => ['Fase A', 'Fase B', 'Fase C'];

  Future<List<String>> getDataKelasYangAda() async {
    if (createdGroupData.value == null) return [];
    final idTahunAjaran = homeController.idTahunAjaran.value;
    final fase = createdGroupData.value!['fase'];
    List<String> kelasList = [];
    final snapshot =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelastahunajaran')
            .where('fase', isEqualTo: fase)
            .get();
    for (var doc in snapshot.docs) {
      kelasList.add(doc.id);
    }
    return kelasList;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAddedSiswa() {
    final groupData = createdGroupData.value;
    if (groupData == null) return const Stream.empty();
    return firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(groupData['idTahunAjaran'])
        .collection('kelompokmengaji')
        .doc(groupData['fase'])
        .collection('pengampu')
        .doc(groupData['idpengampu'])
        .collection('tempat')
        .doc(groupData['tempatmengaji'])
        .collection('semester')
        .doc(homeController.semesterAktifId.value)
        .collection('daftarsiswa')
        .orderBy('tanggalinput', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSiswaBaru() {
    if (kelasAktifDiSheet.value.isEmpty) return const Stream.empty();
    final groupData = createdGroupData.value;
    if (groupData == null) return const Stream.empty();
    final idTahunAjaran = groupData['idTahunAjaran'];
    final semesterAktifId = homeController.semesterAktifId.value;
    return firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(kelasAktifDiSheet.value)
        .collection('semester')
        .doc(semesterAktifId)
        .collection('daftarsiswa')
        .where('statuskelompok', isEqualTo: 'baru')
        .snapshots();
  }

  void finishAndGoBack() {
    Get.back();
  }

  Future<String> getTahunAjaranTerakhir() async {
    final snapshot =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .orderBy('namatahunajaran', descending: true)
            .limit(1)
            .get();
    if (snapshot.docs.isEmpty)
      throw Exception("Data tahun ajaran tidak ditemukan.");
    return snapshot.docs.first.data()['namatahunajaran'];
  }

  Future<void> ubahStatusSiswa(
    String nisnSiswa,
    String newStatus,
    String kelasSiswa,
  ) async {
    final groupData = createdGroupData.value;
    if (groupData == null || kelasSiswa.isEmpty) {
      throw Exception("Data kelompok atau kelas asal siswa tidak lengkap.");
    }
    final idTahunAjaran = groupData['idTahunAjaran'];
    final semesterAktifId = homeController.semesterAktifId.value;
    final DocumentReference siswaRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(kelasSiswa)
        .collection('semester')
        .doc(semesterAktifId)
        .collection('daftarsiswa')
        .doc(nisnSiswa);
    await siswaRef.update({'statuskelompok': newStatus});
  }

  void resetPage() {
    isGroupCreated.value = false;
    createdGroupData.value = null;
    faseC.clear();
    pengampuC.clear();
    tempatC.clear();
    kelasSiswaC.clear();
  }
}
