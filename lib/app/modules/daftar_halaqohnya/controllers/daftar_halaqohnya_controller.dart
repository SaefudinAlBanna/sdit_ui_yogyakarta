// lib/app/modules/daftar_halaqohnya/controllers/daftar_halaqohnya_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/siswa_halaqoh.dart';
import '../../home/controllers/home_controller.dart';

class DaftarHalaqohnyaController extends GetxController {
  
  // --- DEPENDENSI & INFO DASAR ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final String idSekolah = '20404148';

  // --- HAK AKSES (SESUAI ARSITEKTUR BARU) ---
  bool get canPerformWriteActions => homeC.canManageTahsin || homeC.userTugas.contains('Koordinator Halaqoh') || homeC.kapten || homeC.isDalang;


   // --- STATE INFO HALAQOH (SEKARANG REAKTIF) ---
  final RxString fase = ''.obs;
  final RxString namaPengampu = ''.obs;
  final RxString idPengampu = ''.obs;
  final RxString namaTempat = ''.obs;
  final Rxn<String> urlFotoPengampu = Rxn<String>();

  // --- STATE DAFTAR SISWA ---
  final RxBool isLoading = true.obs;
  final RxList<SiswaHalaqoh> daftarSiswa = <SiswaHalaqoh>[].obs;
  StreamSubscription? _siswaSubscription;
  
  // --- STATE UNTUK DIALOG & AKSI ---
  final RxBool isDialogLoading = false.obs;
  final TextEditingController umiC = TextEditingController();
  final TextEditingController bulkUpdateUmiC = TextEditingController();
  final RxList<String> siswaTerpilihUntukUpdateMassal = <String>[].obs;

  //========================================================================
  // --- [BARU] STATE DICANGKOK DARI 'TAMBAH_KELOMPOK_MENGAJI' ---
  //========================================================================
  // "Keranjang Belanja" untuk menampung siswa yang akan ditambahkan
  final RxMap<String, Map<String, dynamic>> siswaTerpilih = <String, Map<String, dynamic>>{}.obs;
  final RxString kelasAktifDiSheet = ''.obs;
  final RxList<String> availableKelas = <String>[].obs;
  final RxString searchQueryInSheet = ''.obs;
  // Ini tetap dibutuhkan untuk logika internal penambahan siswa
  final TextEditingController kelasSiswaC = TextEditingController(); 
  //========================================================================
  // final homeC homeC = Get.find<homeC>();

  final RxBool isSavingNilai = false.obs;
  final TextEditingController suratC = TextEditingController();
  final TextEditingController ayatHafalC = TextEditingController();
  final TextEditingController capaianC = TextEditingController();
  final TextEditingController materiC = TextEditingController();
  final TextEditingController nilaiC = TextEditingController();
  
  final RxString keteranganHalaqoh = "".obs;
  final RxList<String> santriTerpilihUntukNilai = <String>[].obs;
  final List<String> listLevelUmi = ['Jilid 1', 'Jilid 2', 'Jilid 3', 'Jilid 4', 'Jilid 5', 'Jilid 6', 'Al-Quran', 'Gharib', 'Tajwid', 'Turjuman', 'Juz 30', 'Juz 29', 'Juz 28', 'Juz 1', 'Juz 2', 'Juz 3', 'Juz 4', 'Juz 5'];

  final TextEditingController capaianUjianC = TextEditingController();
  final TextEditingController levelUjianC = TextEditingController(); 
  final RxList<String> santriTerpilihUntukUjian = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    final Map<String, dynamic>? args = Get.arguments;
    if (args != null) {
      fase.value = args['fase'];
      namaPengampu.value = args['namapengampu'];
      idPengampu.value = args['idpengampu'];
      namaTempat.value = args['namatempat'];
      _loadInitialData();
    } else {
      Get.snackbar("Error", "Informasi Halaqoh tidak lengkap.");
      Get.offAllNamed('/home');
    }
  }

  @override
  void onClose() {
    _siswaSubscription?.cancel();
    // Dispose semua controller
    umiC.dispose(); bulkUpdateUmiC.dispose(); suratC.dispose(); ayatHafalC.dispose();
    capaianC.dispose(); materiC.dispose(); nilaiC.dispose(); kelasSiswaC.dispose();
    capaianUjianC.dispose(); levelUjianC.dispose();
    super.onClose();
  }

  void _loadInitialData() {
    _loadDataPengampu();
    _listenToDaftarSiswa();
  }

  DocumentReference _getPengampuDocRef() {
    return firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelompokmengaji').doc(fase.value)
        .collection('pengampu').doc(idPengampu.value);
  }

  CollectionReference _getDaftarSiswaCollectionRef() {
    return _getPengampuDocRef()
        .collection('tempat').doc(namaTempat.value)
        .collection('semester').doc(homeC.semesterAktifId.value)
        .collection('daftarsiswa');
  }



  Future<void> _loadDataPengampu() async {
    try {
      final pegawaiDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idPengampu.value).get();
      if (pegawaiDoc.exists) {
        urlFotoPengampu.value = pegawaiDoc.data()?['profileImageUrl'];
      }
    } catch (e) {
      if (kDebugMode) print("Gagal memuat foto pengampu: $e");
    }
  }

   void toggleSantriSelectionForUjian(String nisn) {
    if (santriTerpilihUntukUjian.contains(nisn)) {
      santriTerpilihUntukUjian.remove(nisn);
    } else {
      santriTerpilihUntukUjian.add(nisn);
    }
  }

  Future<void> tandaiSiapUjianMassal() async {
    if (levelUjianC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Level Ujian wajib diisi."); return; }
    if (capaianUjianC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Capaian Akhir wajib diisi."); return; }
    if (santriTerpilihUntukUjian.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu santri."); return; }

    isDialogLoading.value = true;
    try {
      final batch = firestore.batch();
      final refDaftarSiswa = await _getDaftarSiswaCollectionRef();
      final now = DateTime.now();
      final String uidPendaftar = homeC.auth.currentUser!.uid;

      for (String nisn in santriTerpilihUntukUjian) {
        final docSiswaIndukRef = refDaftarSiswa.doc(nisn);
        final docUjianBaruRef = docSiswaIndukRef.collection('ujian').doc();

        batch.update(docSiswaIndukRef, {'status_ujian': 'siap_ujian'});

        final santriData = daftarSiswa.firstWhere((s) => s.nisn == nisn);

        batch.set(docUjianBaruRef, {
          'namasiswa': santriData.namaSiswa,
          'status_ujian': 'siap_ujian',
          'level_ujian': levelUjianC.text.trim(),
          'capaian_saat_didaftarkan': capaianUjianC.text.trim(),
          'tanggal_didaftarkan': now,
          'didaftarkan_oleh': uidPendaftar,
          'semester': homeC.semesterAktifId.value,
          'tanggal_ujian': null,
          'diuji_oleh': null,
          'catatan_penguji': null,
        });
      }

      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "${santriTerpilihUntukUjian.length} santri telah ditandai siap ujian.");
      santriTerpilihUntukUjian.clear();
      capaianUjianC.clear();
      levelUjianC.clear();
    } catch (e) {
      Get.snackbar("Error", "Gagal menandai siswa: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }

  // Future<void> _listenToDaftarSiswa() async {
  //   isLoading.value = true;
  //   try {
  //     _siswaSubscription?.cancel();
  //     _siswaSubscription = _getDaftarSiswaCollectionRef().orderBy('namasiswa').snapshots().listen((snapshot) {
  //       daftarSiswa.assignAll(snapshot.docs.map((doc) => SiswaHalaqoh.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList());
  //       isLoading.value = false;
  //     });
  //   } catch (e) {
  //     Get.snackbar("Error", "Gagal menyiapkan koneksi data: $e");
  //     isLoading.value = false;
  //   }
  // }

  Future<void> _listenToDaftarSiswa() async {
    isLoading.value = true;
    try {
      _siswaSubscription?.cancel();
      _siswaSubscription = _getDaftarSiswaCollectionRef().orderBy('namasiswa').snapshots().listen((snapshot) {
        // --- PERBAIKAN UTAMA DI SINI ---
        final siswaList = snapshot.docs
            .map((doc) => SiswaHalaqoh.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList(); // <-- TAMBAHKAN .toList() SECARA EKSPLISIT

        daftarSiswa.assignAll(siswaList);
        isLoading.value = false;
      }, onError: (error) {
        Get.snackbar("Error", "Gagal memuat data siswa: $error");
        isLoading.value = false;
      });
    } catch (e) {
      Get.snackbar("Error", "Gagal menyiapkan koneksi data: $e");
      isLoading.value = false;
    }
  }

  Future<void> gantiPengampu(Map<String, dynamic>? pengampuBaru) async {
  // Cek apakah pengampuBaru null atau tidak lengkap
  if (pengampuBaru == null || pengampuBaru['uid'] == null || pengampuBaru['alias'] == null) {
    Get.snackbar("Error", "Data pengampu tidak lengkap.");
    return;
  }

  Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

  try {
    final String idPengampuBaru = pengampuBaru['uid'];
    final String aliasPengampuBaru = pengampuBaru['alias'];

    // Cek apakah pengampu yang dipilih sama
    if (idPengampu.value == idPengampuBaru) {
      Get.back();
      Get.snackbar("Info", "Anda memilih pengampu yang sama.");
      return;
    }

    // Referensi dokumen lama dan data siswa
    final pengampuLamaRef = _getPengampuDocRef();
    final tempatLamaRef = pengampuLamaRef.collection('tempat').doc(namaTempat.value);
    final siswaSnapshot = await _getDaftarSiswaCollectionRef().get();

    // Referensi dokumen baru
    final pengampuBaruRef = firestore
        .collection('Sekolah')
        .doc(homeC.idSekolah)
        .collection('tahunajaran')
        .doc(homeC.idTahunAjaran.value!)
        .collection('kelompokmengaji')
        .doc(fase.value)
        .collection('pengampu')
        .doc(idPengampuBaru);
    final tempatBaruRef = pengampuBaruRef.collection('tempat').doc(namaTempat.value);

    WriteBatch batch = firestore.batch();

    // Ambil dan salin data tempat lama
    final tempatDataSnapshot = await tempatLamaRef.get();
    if (!tempatDataSnapshot.exists) {
      throw Exception("Data tempat lama tidak ditemukan.");
    }

    final tempatData = Map<String, dynamic>.from(tempatDataSnapshot.data() ?? {});
    tempatData['namapengampu'] = aliasPengampuBaru;
    tempatData['idpengampu'] = idPengampuBaru;

    // Buat data pengampu baru dan tempatnya
    batch.set(pengampuBaruRef, {
      'namaPengampu': aliasPengampuBaru,
      'uidPengampu': idPengampuBaru,
      'createdAt': Timestamp.now(),
    });
    batch.set(tempatBaruRef, tempatData);

    // Pindahkan siswa ke tempat baru
    for (var siswaDoc in siswaSnapshot.docs) {
      final rawData = siswaDoc.data();
      if (rawData is! Map<String, dynamic>) continue;

      final siswaData = Map<String, dynamic>.from(rawData);
      siswaData['namapengampu'] = aliasPengampuBaru;
      siswaData['idpengampu'] = idPengampuBaru;

      final siswaRefBaru = tempatBaruRef
          .collection('semester')
          .doc(homeC.semesterAktifId.value)
          .collection('daftarsiswa')
          .doc(siswaDoc.id);

      batch.set(siswaRefBaru, siswaData);
      batch.delete(siswaDoc.reference);
    }

    // Hapus tempat dan pengampu lama
    batch.delete(tempatLamaRef);
    batch.delete(pengampuLamaRef);

    // Update data pegawai lama
    final pegawaiLamaRef = firestore
        .collection('Sekolah')
        .doc(homeC.idSekolah)
        .collection('pegawai')
        .doc(idPengampu.value);

    final pegawaiBaruRef = firestore
        .collection('Sekolah')
        .doc(homeC.idSekolah)
        .collection('pegawai')
        .doc(idPengampuBaru);

    batch.update(pegawaiLamaRef, {'tahunajarankelompok': {}});

    // Komit semua perubahan
    await batch.commit();

    // Update UI state
    idPengampu.value = idPengampuBaru;
    namaPengampu.value = aliasPengampuBaru;

    Get.back(); // Tutup loading
    Get.back(); // Tutup dialog pilih pengampu
    Get.snackbar("Berhasil", "Pengampu telah diganti menjadi $aliasPengampuBaru.");

    _loadInitialData();
  } catch (e) {
    Get.back(); // Pastikan dialog loading ditutup
    Get.snackbar("Error", "Gagal mengganti pengampu: ${e.toString()}");
  }
}


  Future<void> openSiswaPicker() async {
    // Reset semua state sheet sebelum dibuka
    siswaTerpilih.clear();
    searchQueryInSheet.value = '';
    availableKelas.clear();
    kelasAktifDiSheet.value = '';

    // Ambil data kelas yang sesuai dengan fase kelompok ini
    final kelas = await getDataKelasYangAda();
    availableKelas.assignAll(kelas);

    // Set kelas aktif default SETELAH data siap
    if (availableKelas.isNotEmpty) {
      kelasAktifDiSheet.value = availableKelas.first;
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
        middleText: "Anda memiliki ${siswaTerpilih.length} siswa terpilih. Simpan sebelum pindah kelas?",
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
        }
      );
    } else {
      kelasAktifDiSheet.value = kelasBaru;
    }
  }

  Future<void> simpanSiswaTerpilih() async {
    if (siswaTerpilih.isEmpty) return;

    isDialogLoading.value = true;
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      final semesterAktif = homeC.semesterAktifId.value;
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final tahunAjaranDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).get();
      final tahunajarannya = tahunAjaranDoc.data()!['namatahunajaran'];
      
      WriteBatch batch = firestore.batch();
      
      final groupData = {
        'tahunajaran': tahunajarannya, 'idTahunAjaran': idTahunAjaran,
        'fase': fase, 'namapengampu': namaPengampu,
        'idpengampu': idPengampu, 'tempatmengaji': namaTempat,
      };

      for (var siswa in siswaTerpilih.values) {
        _addSiswaToBatch(batch, siswa['namasiswa'], siswa['nisn'], siswa['kelas'], groupData, semesterAktif);
    
        // Panggil fungsi yang sudah diperbaiki dengan parameter semesterAktif
        _updateStatusSiswaInBatch(batch, siswa['nisn'], 'aktif', idTahunAjaran, siswa['kelas'], semesterAktif); 
      }
      
      await batch.commit();
      Get.back(); 
      Get.snackbar("Berhasil", "${siswaTerpilih.length} siswa telah ditambahkan.");
      siswaTerpilih.clear();

    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Gagal menambahkan siswa: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }

  void _addSiswaToBatch(WriteBatch batch, String namaSiswa, String nisnSiswa, String kelasSiswa, Map<String, dynamic> groupData, String semesterAktif) {
    final idTahunAjaran = groupData['idTahunAjaran'];
    final dataSiswa = {
      'namasiswa': namaSiswa, 'nisn': nisnSiswa, 'kelas': kelasSiswa, 'fase': groupData['fase'],
      'tempatmengaji': groupData['tempatmengaji'], 'tahunajaran': groupData['tahunajaran'],
      'kelompokmengaji': groupData['namapengampu'], 'namapengampu': groupData['namapengampu'],
      'idpengampu': groupData['idpengampu'], 'emailpenginput': homeC.emailAdmin,
      'idpenginput': homeC.idUser, 'tanggalinput': DateTime.now().toIso8601String(),
      'idsiswa': nisnSiswa, 'ummi': '0', 'semester': semesterAktif,
    };

    DocumentReference siswaDiKelompokRef = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(groupData['fase'])
        .collection('pengampu').doc(groupData['namapengampu'])
        .collection('tempat').doc(groupData['tempatmengaji'])
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').doc(nisnSiswa);
    batch.set(siswaDiKelompokRef, dataSiswa);

    DocumentReference refDiSiswa = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(nisnSiswa)
        .collection('tahunajarankelompok').doc(idTahunAjaran);
    batch.set(refDiSiswa, {'namatahunajaran': groupData['tahunajaran']});
    batch.set(refDiSiswa.collection('semester').doc(semesterAktif).collection('kelompokmengaji').doc(groupData['fase']), {
        'fase': groupData['fase'], 'namapengampu': groupData['namapengampu'], 'tempatmengaji': groupData['tempatmengaji']
    });
  }

  void _updateStatusSiswaInBatch(WriteBatch batch, String nisnSiswa, String newStatus, String idTahunAjaran, String kelasId, String semesterId) {
  final DocumentReference siswaRef = firestore
      .collection('Sekolah').doc(idSekolah)
      .collection('tahunajaran').doc(idTahunAjaran)
      .collection('kelastahunajaran').doc(kelasId)
      .collection('semester').doc(semesterId) // <-- PATH SEMESTER DITAMBAHKAN
      .collection('daftarsiswa').doc(nisnSiswa);
  batch.update(siswaRef, {'statuskelompok': newStatus});
}

  Future<List<String>> getDataKelasYangAda() async {
    final idTahunAjaran = homeC.idTahunAjaran.value;
    List<String> kelasList = [];
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran')
        .where('fase', isEqualTo: fase.value).get(); // Menggunakan 'fase' dari properti kelas
    for (var doc in snapshot.docs) { kelasList.add(doc.id); }
    return kelasList;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSiswaBaru() {
    // Validasi awal tidak berubah
    if (kelasAktifDiSheet.value.isEmpty) {
      return const Stream.empty();
    }
    
    // Ambil semua data yang dibutuhkan untuk path yang lengkap
    final idTahunAjaran = homeC.idTahunAjaran.value;
    final semesterAktifId = homeC.semesterAktifId.value;

    // Pastikan data global tersedia sebelum membuat query
    if (idTahunAjaran == null) {
        Get.snackbar("Error", "Tahun Ajaran tidak terdeteksi.");
        return const Stream.empty();
    }

    // --- [PERBAIKAN] Gunakan path yang benar dengan semester ---
    return firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(kelasAktifDiSheet.value)
        .collection('semester').doc(semesterAktifId) // <-- Path semester ditambahkan
        .collection('daftarsiswa').where('statuskelompok', isEqualTo: 'baru')
        .snapshots();
}

  Future<String> _fetchCapaianTerakhir(DocumentReference siswaRef) async {
    try {
      final nilaiSnapshot = await siswaRef
          .collection('nilai')
          .orderBy('tanggalinput', descending: true)
          .limit(1)
          .get();
      if (nilaiSnapshot.docs.isNotEmpty) {
        return nilaiSnapshot.docs.first.data()['capaian'] ?? '';
      }
      return ''; // Kembalikan string kosong jika tidak ada nilai
    } catch (e) {
      return ''; // Kembalikan string kosong jika error
    }
  }
  
  //========================================================================
  // --- LOGIKA BARU UNTUK FITUR INPUT NILAI MASSAL ---
  //========================================================================

  Future<void> updateUmi(String nisn) async {
    if (umiC.text.isEmpty) { Get.snackbar("Peringatan", "Kategori Umi belum dipilih."); return; }
    isDialogLoading.value = true;
    try {
      final refSiswa = (await _getDaftarSiswaCollectionRef()).doc(nisn);

      await refSiswa.update({'ummi': umiC.text});
      Get.back();
      Get.snackbar("Berhasil", "Data Umi telah diperbarui.");
    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui data: ${e.toString()}");
    } finally {
      isDialogLoading.value = false;
      umiC.clear();
    }
  }

  Future<void> updateUmiMassal() async {
    final String targetLevel = bulkUpdateUmiC.text;
    if (targetLevel.isEmpty) { Get.snackbar("Peringatan", "Pilih level UMI tujuan."); return; }
    if (siswaTerpilihUntukUpdateMassal.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu siswa."); return; }

    isDialogLoading.value = true;
    try {
      final WriteBatch batch = firestore.batch();
      final refDaftarSiswa = await _getDaftarSiswaCollectionRef();

      for (String nisn in siswaTerpilihUntukUpdateMassal) {
        batch.update(refDaftarSiswa.doc(nisn), {'ummi': bulkUpdateUmiC.text});
      }

      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "${siswaTerpilihUntukUpdateMassal.length} siswa telah diupdate.");
    } catch (e) {
      Get.snackbar("Error", "Gagal melakukan update massal: $e");
    } finally {
      isDialogLoading.value = false;
      siswaTerpilihUntukUpdateMassal.clear();
      bulkUpdateUmiC.clear();
    }
  }


 /// Mengambil daftar siswa yang belum punya kelompok dari kelas tertentu
  Stream<QuerySnapshot<Map<String, dynamic>>> getSiswaBaruStream(String namaKelas) async* {
    final ref = (await _getTahunAjaranRef()).collection('kelastahunajaran');
    yield* ref
        .doc(namaKelas)
        .collection('daftarsiswa')
        .where('statuskelompok', isEqualTo: 'baru')
        .snapshots();
  }

  /// Helper untuk mendapatkan referensi TAHUN AJARAN terakhir. Mencegah duplikasi kode.
  Future<DocumentReference<Map<String, dynamic>>> _getTahunAjaranRef() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) throw Exception("Tahun Ajaran tidak ditemukan");
    return snapshot.docs.first.reference;
  }

  /// Menambahkan siswa baru ke kelompok halaqoh (menggantikan `simpanSiswaKelompok`)
  Future<void> tambahSiswaKeHalaqoh(Map<String, dynamic> dataSiswa) async {
    isDialogLoading.value = true;
    try {
      final String nisn = dataSiswa['nisn'];
      final refDaftarSiswaHalaqoh = (await _getDaftarSiswaCollectionRef()).doc(nisn);
      final refSiswaDiKelasAsal = (await _getTahunAjaranRef())
          .collection('kelastahunajaran').doc(dataSiswa['namakelas'])
          .collection('daftarsiswa').doc(nisn);

      WriteBatch batch = firestore.batch();
     

      // 1. Tambahkan siswa ke daftar siswa halaqoh ini
      batch.set(refDaftarSiswaHalaqoh, {
        'namasiswa': dataSiswa['namasiswa'],
        'nisn': nisn,
        'kelas': dataSiswa['namakelas'],
        'ummi': '0', // Nilai default UMI
        'profileImageUrl': dataSiswa['profileImageUrl'],
        'fase': fase,
        'namapengampu': namaPengampu,
        'tempatmengaji': namaTempat,
        'tanggalinput': FieldValue.serverTimestamp(),
      });

      // 2. Update status siswa di daftar kelas asal
      batch.update(refSiswaDiKelasAsal, {'statuskelompok': 'aktif'});

      // (Opsional) Tambahkan juga rekam jejak di koleksi /Sekolah/{id}/siswa/{nisn}/...
      // Logika ini bisa ditambahkan di sini jika diperlukan

      await batch.commit();
      Get.snackbar("Berhasil", "${dataSiswa['namasiswa']} telah ditambahkan.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menambahkan siswa: ${e.toString()}");
    } finally {
      isDialogLoading.value = false;
    }
  }

  /// Mengelola checkbox santri. Dipanggil dari UI.
  void toggleSantriSelection(String nisn) {
    if (santriTerpilihUntukNilai.contains(nisn)) {
      santriTerpilihUntukNilai.remove(nisn);
    } else {
      santriTerpilihUntukNilai.add(nisn);
    }
  }

  Future<void> simpanNilaiMassal() async {
    // Validasi tidak berubah
    if (santriTerpilihUntukNilai.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu santri."); return; }
    if (materiC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Materi wajib diisi."); return; }
    if (nilaiC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Nilai wajib diisi."); return; }

    isSavingNilai.value = true;
    try {
      final now = DateTime.now();
      final docIdNilaiHarian = DateFormat('yyyy-MM-dd').format(now);
      
      int nilaiNumerik = int.tryParse(nilaiC.text.trim()) ?? 0;
      if (nilaiNumerik > 98) nilaiNumerik = 98;
      String grade = _getGrade(nilaiNumerik);
      
      final batch = firestore.batch();
      final refDaftarSiswa = _getDaftarSiswaCollectionRef();

      final dataNilaiTemplate = {
        "tanggalinput": now.toIso8601String(),
        "emailpenginput": homeC.auth.currentUser!.email,
        "namapengampu": namaPengampu.value, // Ambil nilai string-nya
        "hafalansurat": suratC.text.trim(),
        "ayathafalansurat": ayatHafalC.text.trim(),
        "capaian": capaianC.text.trim(),
        "materi": materiC.text.trim(),
        "nilai": nilaiNumerik,
        "nilaihuruf": grade,
        "keteranganpengampu": keteranganHalaqoh.value,
        "uidnilai": docIdNilaiHarian,
        "semester": homeC.semesterAktifId.value,
        "tempatmengaji": namaTempat.value,
      };

      for (String nisn in santriTerpilihUntukNilai) {
        final santriData = daftarSiswa.firstWhere((s) => s.nisn == nisn);
        final docNilaiRef = refDaftarSiswa.doc(nisn).collection('nilai').doc(docIdNilaiHarian);
        
        // --- PERBAIKAN UTAMA DI SINI ---
        final dataFinal = { 
          ...dataNilaiTemplate, 
          "idsiswa": nisn, 
          "namasiswa": santriData.namaSiswa,
          // Ambil idpengampu dari state controller, tapi gunakan .value
          "idpengampu": idPengampu.value, 
        };
        
        batch.set(docNilaiRef, dataFinal, SetOptions(merge: true));

        // Update capaian terakhir di dokumen induk
        batch.update(refDaftarSiswa.doc(nisn), {
          'capaian_terakhir': capaianC.text.trim(),
          'tanggal_update_terakhir': now,
        });
      }
      await batch.commit();

      Get.back(); // Tutup bottom sheet
      Get.snackbar("Berhasil", "Nilai berhasil disimpan untuk ${santriTerpilihUntukNilai.length} santri.");
      clearNilaiForm(); // Bersihkan form
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan nilai: ${e.toString()}");
    } finally {
      isSavingNilai.value = false;
    }
  }

   Future<List<Map<String, dynamic>>> getTujuanHalaqoh() async {
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      
      // Cari semua pengampu di fase yang sama
      final pengampuSnapshot = await firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(fase.value)
          .collection('pengampu').get();

      List<Map<String, dynamic>> tujuanList = [];
      for (var pengampuDoc in pengampuSnapshot.docs) {
        // Jangan masukkan kelompok saat ini sebagai tujuan
        if (pengampuDoc.id == idPengampu.value) continue;

        // Ambil juga nama tempatnya
        final tempatSnapshot = await pengampuDoc.reference.collection('tempat').limit(1).get();
        if (tempatSnapshot.docs.isNotEmpty) {
          tujuanList.add({
            'idpengampu': pengampuDoc.id,
            'namapengampu': pengampuDoc.data()['namaPengampu'],
            'namatempat': tempatSnapshot.docs.first.id,
          });
        }
      }
      return tujuanList;
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar tujuan: $e");
      return [];
    }
  }

    Future<void> pindahHalaqoh(SiswaHalaqoh siswa, Map<String, dynamic> tujuan) async {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      try {
        final String idTahunAjaran = homeC.idTahunAjaran.value!;
        final String semesterAktif = homeC.semesterAktifId.value;

        final refSiswaAsal = _getDaftarSiswaCollectionRef().doc(siswa.nisn);

        final refSiswaTujuan = firestore
            .collection('Sekolah').doc(homeC.idSekolah)
            .collection('tahunajaran').doc(idTahunAjaran)
            .collection('kelompokmengaji').doc(fase.value)
            .collection('pengampu').doc(tujuan['idpengampu'])
            .collection('tempat').doc(tujuan['namatempat'])
            .collection('semester').doc(semesterAktif)
            .collection('daftarsiswa').doc(siswa.nisn);

        final refDiSiswaUtama = firestore
            .collection('Sekolah').doc(homeC.idSekolah)
            .collection('siswa').doc(siswa.nisn)
            .collection('tahunajarankelompok').doc(idTahunAjaran)
            .collection('semester').doc(semesterAktif)
            .collection('kelompokmengaji').doc(fase.value);

        WriteBatch batch = firestore.batch();

        // Ambil data siswa asal
        final siswaDoc = await refSiswaAsal.get();
        final rawData = siswaDoc.data();

        if (rawData == null || rawData is! Map<String, dynamic>) {
          throw Exception("Data siswa sumber tidak ditemukan atau tidak valid.");
        }

        // Salin dan modifikasi data siswa
        final Map<String, dynamic> siswaData = Map<String, dynamic>.from(rawData);

        siswaData['namapengampu'] = tujuan['namapengampu'];
        siswaData['idpengampu'] = tujuan['idpengampu'];
        siswaData['tempatmengaji'] = tujuan['namatempat'];

        // Tambahkan semua operasi batch
        batch.set(refSiswaTujuan, siswaData);
        batch.delete(refSiswaAsal);
        batch.set(refDiSiswaUtama, {
          'fase': fase.value,
          'namapengampu': tujuan['namapengampu'],
          'tempatmengaji': tujuan['namatempat'],
        });

        await batch.commit();

        Get.back(); // Tutup loading dialog
        Get.back(); // Kembali ke layar sebelumnya
        Get.snackbar("Berhasil", "${siswa.namaSiswa} telah dipindahkan.");
      } catch (e) {
        Get.back(); // Tutup loading dialog jika error
        Get.snackbar("Error", "Gagal memindahkan siswa: ${e.toString()}");
      }
    }



  /// Membersihkan form template nilai.
  void clearNilaiForm() {
    suratC.clear(); ayatHafalC.clear(); capaianC.clear();
    materiC.clear(); nilaiC.clear();
    keteranganHalaqoh.value = "";
    santriTerpilihUntukNilai.clear();
  }

  /// Konversi nilai angka ke huruf.
  String _getGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 85) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 75) return 'B-';
    if (score >= 70) return 'C+';
    if (score >= 65) return 'C';
    if (score >= 60) return 'C-';
    return 'D';
  }

  
}