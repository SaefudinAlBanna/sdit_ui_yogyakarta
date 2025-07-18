// lib/app/modules/daftar_halaqohnya/controllers/daftar_halaqohnya_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/siswa_halaqoh.dart';
import '../../home/controllers/home_controller.dart';

class DaftarHalaqohnyaController extends GetxController {
  
  // --- DEPENDENSI & INFO DASAR ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeController = Get.find<HomeController>();
  final String idSekolah = '20404148';
  
  // --- STATE INFO HALAQOH ---
  late final String fase;
  late final String namaPengampu;
  late final String idPengampu;
  late final String namaTempat;
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
  // --- STATE BARU UNTUK FITUR INPUT NILAI MASSAL ---
  //========================================================================
  final RxBool isSavingNilai = false.obs;
  final TextEditingController suratC = TextEditingController();
  final TextEditingController ayatHafalC = TextEditingController();
  final TextEditingController capaianC = TextEditingController();
  final TextEditingController materiC = TextEditingController();
  final TextEditingController nilaiC = TextEditingController();
  final TextEditingController kelasSiswaC = TextEditingController();
  final RxString keteranganHalaqoh = "".obs;
  final RxList<String> santriTerpilihUntukNilai = <String>[].obs;
  final List<String> listLevelUmi = ['Jilid 1', 'Jilid 2', 'Jilid 3', 'Jilid 4', 'Jilid 5', 'Jilid 6', 'Al-Quran', 'Gharib', 'Tajwid', 'Turjuman', 'Juz 30', 'Juz 29', 'Juz 28', 'Juz 1', 'Juz 2', 'Juz 3', 'Juz 4', 'Juz 5'];
  //========================================================================

  // --- STATE BARU UNTUK FITUR UJIAN ---
  final TextEditingController capaianUjianC = TextEditingController();
  final TextEditingController levelUjianC = TextEditingController(); // Untuk menentukan ujian apa
  final RxList<String> santriTerpilihUntukUjian = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    final Map<String, dynamic>? args = Get.arguments;
    if (args != null) {
      fase = args['fase'];
      namaPengampu = args['namapengampu'];
      idPengampu = args['idpengampu'];
      namaTempat = args['namatempat'];
      _loadInitialData();
    } else {
      Get.snackbar("Error", "Informasi Halaqoh tidak lengkap.");
      Get.offAllNamed('/home');
    }
  }

  @override
  void onClose() {
    _siswaSubscription?.cancel();
    umiC.dispose(); bulkUpdateUmiC.dispose();
    suratC.dispose(); ayatHafalC.dispose(); capaianC.dispose();
    materiC.dispose(); nilaiC.dispose();
    kelasSiswaC.dispose();
    super.onClose();
  }

  void _loadInitialData() {
    _loadDataPengampu();
    _listenToDaftarSiswa();
  }

  Future<void> _loadDataPengampu() async {
    try {
      final pegawaiDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idPengampu).get();
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
    // Validasi
    if (levelUjianC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Level Ujian wajib diisi."); return; }
    if (capaianUjianC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Capaian Akhir wajib diisi."); return; }
    if (santriTerpilihUntukUjian.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu santri."); return; }

    isDialogLoading.value = true;
    try {
      final batch = firestore.batch();
      final refDaftarSiswa = await _getDaftarSiswaCollectionRef();
      final now = DateTime.now();
      final String uidPendaftar = homeController.auth.currentUser!.uid;

      for (String nisn in santriTerpilihUntukUjian) {
        final docSiswaIndukRef = refDaftarSiswa.doc(nisn);
        final docUjianBaruRef = docSiswaIndukRef.collection('ujian').doc(); // ID Otomatis

        // 1. Update status di dokumen induk
        batch.update(docSiswaIndukRef, {
          'status_ujian': 'siap_ujian',
        });

        // 2. Buat dokumen baru di subkoleksi 'ujian'
        batch.set(docUjianBaruRef, {
          'status_ujian': 'siap_ujian',
          'level_ujian': levelUjianC.text.trim(),
          'capaian_saat_didaftarkan': capaianUjianC.text.trim(),
          'tanggal_didaftarkan': now,
          'didaftarkan_oleh': uidPendaftar,
          'semester': homeController.semesterAktifId.value,
          // Field untuk Koordinator nanti
          'tanggal_ujian': null,
          'diuji_oleh': null,
          'catatan_penguji': null,
        });
      }

      await batch.commit();
      Get.back(); // Tutup dialog
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

  Future<void> _listenToDaftarSiswa() async {
    isLoading.value = true;
    try {
      final ref = await _getDaftarSiswaCollectionRef();
      _siswaSubscription?.cancel();
      // snapshots() akan otomatis mengirim data baru setiap kali ada perubahan di dokumen daftarsiswa
      _siswaSubscription = ref.orderBy('namasiswa').snapshots().listen((snapshot) {
        // Model SiswaHalaqoh akan otomatis membaca 'capaian_terakhir'
        final siswaList = snapshot.docs.map((doc) => SiswaHalaqoh.fromFirestore(doc)).toList();
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
      // final batch = firestore.batch();
      // batch.update(refSiswa, {'ummi': umiC.text});

      Get.back();
      Get.snackbar("Berhasil", "Data Umi telah diperbarui.");
      // _listenToDaftarSiswa();
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

      // for (String nisn in siswaTerpilihUntukUpdateMassal) {
      //   batch.update(refDaftarSiswa.doc(nisn), {'ummi': targetLevel});
      // }
      for (String nisn in siswaTerpilihUntukUpdateMassal) {
        batch.update(refDaftarSiswa.doc(nisn), {'ummi': bulkUpdateUmiC.text});
      }

      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "${siswaTerpilihUntukUpdateMassal.length} siswa telah diupdate.");
      _listenToDaftarSiswa();
    } catch (e) {
      Get.snackbar("Error", "Gagal melakukan update massal: $e");
    } finally {
      isDialogLoading.value = false;
      siswaTerpilihUntukUpdateMassal.clear();
      bulkUpdateUmiC.clear();
    }
  }

  Future<List<String>> getKelasTersedia() async {
    try {
      final ref = (await _getTahunAjaranRef()).collection('kelastahunajaran');

      // --- PERBAIKAN DI SINI ---
      // Gunakan variabel 'fase' secara langsung karena nilainya sudah benar
      final snapshot = await ref.where('fase', isEqualTo: fase).get(); 

      if (snapshot.docs.isEmpty) {
        print("Tidak ada kelas ditemukan untuk Fase: $fase");
        return [];
      }
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil daftar kelas: ${e.toString()}");
      return [];
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
      final refDaftarSiswa = await _getDaftarSiswaCollectionRef(); // Path semester sudah termasuk di sini

      final dataNilaiTemplate = {
        "tanggalinput": now.toIso8601String(),
        "emailpenginput": homeController.emailAdmin,
        "idpengampu": idPengampu,
        "namapengampu": namaPengampu,
        "hafalansurat": suratC.text.trim(),
        "ayathafalansurat": ayatHafalC.text.trim(),
        "capaian": capaianC.text.trim(),
        "materi": materiC.text.trim(),
        "nilai": nilaiNumerik,
        "nilaihuruf": grade,
        "keteranganpengampu": keteranganHalaqoh.value,
        "uidnilai": docIdNilaiHarian,
        "semester": homeController.semesterAktifId.value,
      };

      for (String nisn in santriTerpilihUntukNilai) {
        final santriData = daftarSiswa.firstWhere((s) => s.nisn == nisn);
        final docNilaiRef = refDaftarSiswa.doc(nisn).collection('nilai').doc(docIdNilaiHarian);
        
        final docSiswaIndukRef = refDaftarSiswa.doc(nisn);
        final dataFinal = { ...dataNilaiTemplate, "idsiswa": nisn, "namasiswa": santriData.namaSiswa };
        
        batch.set(docNilaiRef, dataFinal, SetOptions(merge: true));

        batch.update(docSiswaIndukRef, {
          'capaian_terakhir': capaianC.text.trim(),
          'tanggal_update_terakhir': now,
        });
      }

      //  batch.update(docSiswaIndukRef, {
      //     'ummi': umiC.text.trim().isNotEmpty ? umiC.text.trim() : santriData.ummi, // Update UMI jika diisi di template
      //     'capaian_terakhir': capaianC.text.trim(),
      //     'tanggal_update_terakhir': now,
      //   });
      // }

      await batch.commit();

      Get.back();
      Get.snackbar("Berhasil", "Nilai berhasil disimpan untuk ${santriTerpilihUntukNilai.length} santri.");
      clearNilaiForm();

      // _listenToDaftarSiswa();

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan nilai: ${e.toString()}");
    } finally {
      isSavingNilai.value = false;
    }
  }

  Future<CollectionReference<Map<String, dynamic>>> _getDaftarSiswaCollectionRef() async {
    final idTahunAjaran = homeController.idTahunAjaran.value!;
    final semesterAktif = homeController.semesterAktifId.value;

    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(fase)
        .collection('pengampu').doc(namaPengampu)
        .collection('tempat').doc(namaTempat)
        .collection('semester').doc(semesterAktif) // <-- INTEGRASI SEMESTER
        .collection('daftarsiswa');
  }


  /// Membersihkan form template nilai.
  void clearNilaiForm() {
    suratC.clear();
    ayatHafalC.clear();
    capaianC.clear();
    // halAyatC.clear();
    materiC.clear();
    nilaiC.clear();
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