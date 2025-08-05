// lib/app/modules/daftar_halaqoh_pengampu/controllers/daftar_halaqoh_pengampu_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/siswa_halaqoh.dart';
import '../../../modules/home/controllers/home_controller.dart';
import '../../../routes/app_pages.dart';
import 'dart:async';
import 'package:collection/collection.dart';

import '../../../services/halaqoh_service.dart';
import '../../../interfaces/input_nilai_massal_interface.dart';
import '../../../widgets/tandai_siap_ujian_sheet.dart';
// import '../../../widgets/input_nilai_massal_sheet.dart';


class DaftarHalaqohPengampuController extends GetxController implements IInputNilaiMassalController, ITandaiSiapUjianController {

  @override
  final RxBool isDialogLoading = false.obs;
  @override
  final RxList<String> santriTerpilihUntukUjian = <String>[].obs;
  @override // Tambahkan override untuk menandakan ini adalah implementasi kontrak
  final RxBool isSavingNilai = false.obs;
  @override
  final RxList<SiswaHalaqoh> daftarSiswa = <SiswaHalaqoh>[].obs;
  @override
  final RxList<String> santriTerpilihUntukNilai = <String>[].obs;
  @override
  Map<String, TextEditingController> nilaiMassalControllers = {};
  // Controller untuk template
  @override
  final TextEditingController suratC = TextEditingController();
  @override
  final TextEditingController ayatHafalC = TextEditingController();
  @override
  final TextEditingController capaianC = TextEditingController();
  @override
  final TextEditingController materiC = TextEditingController();
  // RxString tidak punya getter langsung, jadi kita buat getter-nya
  @override
  RxString get keteranganHalaqoh => _keteranganHalaqoh;

  final RxString _keteranganHalaqoh = "".obs;

  // StreamSubscription? _halaqohSubscription; // <-- [BARU] Tambahkan ini
  StreamSubscription? _siswaSubscription;
  Worker? _homeControllerReadyWorker;

  // --- DEPENDENSI ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  // --- STATE KONTROL UI ---
  final RxBool isLoading = true.obs; // Satu-satunya loading indicator utama
  // final RxBool isDialogLoading = false.obs;
  // final RxBool isSavingNilai = false.obs;
  
  // --- STATE DATA ---
  final RxList<Map<String, dynamic>> daftarHalaqoh = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> halaqohTerpilih = Rxn<Map<String, dynamic>>();
  // final RxList<Map<String, dynamic>> daftarSantri = <Map<String, dynamic>>[].obs;
  // final RxList<SiswaHalaqoh> daftarSantri = <SiswaHalaqoh>[].obs;
  final HalaqohService halaqohService = Get.find();

  // --- CONTROLLER & STATE LAINNYA ---
  final TextEditingController lokasiC = TextEditingController();
  // final TextEditingController suratC = TextEditingController();
  // final TextEditingController ayatHafalC = TextEditingController();
  // final TextEditingController capaianC = TextEditingController();
  final TextEditingController halAyatC = TextEditingController();
  // final TextEditingController materiC = TextEditingController();
  final TextEditingController capaianUjianC = TextEditingController();
  final TextEditingController levelUjianC = TextEditingController();
  // final RxString keteranganHalaqoh = "".obs;
  // final RxList<String> santriTerpilihUntukNilai = <String>[].obs;
  // final RxList<String> santriTerpilihUntukUjian = <String>[].obs;
  // Map<String, TextEditingController> nilaiMassalControllers = {};
  

  @override
  void toggleSantriSelection(String nisn) {
    if (santriTerpilihUntukNilai.contains(nisn)) {
      santriTerpilihUntukNilai.remove(nisn);
    } else {
      santriTerpilihUntukNilai.add(nisn);
    }
  }

  @override
  void toggleSantriSelectionForUjian(String nisn) {
    if (santriTerpilihUntukUjian.contains(nisn)) {
      santriTerpilihUntukUjian.remove(nisn);
    } else {
      santriTerpilihUntukUjian.add(nisn);
    }
  }
  
  @override
  Future<void> tandaiSiapUjianMassal() async {
    if (santriTerpilihUntukUjian.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu santri."); return; }

    isDialogLoading.value = true;
    
    // Filter objek SiswaHalaqoh lengkap berdasarkan nisn yang terpilih
    final List<SiswaHalaqoh> siswaTerpilihObjek = daftarSiswa
        .where((siswa) => santriTerpilihUntukUjian.contains(siswa.nisn))
        .toList();

    final bool isSuccess = await halaqohService.tandaiSiapUjianMassal(
      infoKelompok: halaqohTerpilih.value!,
      siswaTerpilih: siswaTerpilihObjek,
    );

    isDialogLoading.value = false;

    if (isSuccess) {
      Get.back(); // Tutup bottom sheet
      Get.snackbar("Berhasil", "${santriTerpilihUntukUjian.length} santri telah ditandai siap ujian.");
      santriTerpilihUntukUjian.clear();
    }
  }

  @override
  Future<void> simpanNilaiMassal() async {
    if (santriTerpilihUntukNilai.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu santri."); return; }
    // Validasi lain bisa ditambahkan di sini jika perlu

    isSavingNilai.value = true;

    // Siapkan data yang dibutuhkan oleh service
    final Map<String, String> nilaiPerSiswa = {};
    for (var nisn in santriTerpilihUntukNilai) {
      nilaiPerSiswa[nisn] = nilaiMassalControllers[nisn]?.text ?? '';
    }

    final templateData = {
      'surat': suratC.text.trim(),
      'ayat': ayatHafalC.text.trim(),
      'capaian': capaianC.text.trim(),
      'materi': materiC.text.trim(),
      'keterangan': keteranganHalaqoh.value,
    };

    // Panggil service
    final bool isSuccess = await halaqohService.inputNilaiMassal(
      infoKelompok: halaqohTerpilih.value!,
      semuaSiswaDiKelompok: daftarSiswa.map((s) => s.rawData).toList(),
      daftarNisnTerpilih: santriTerpilihUntukNilai,
      nilaiPerSiswa: nilaiPerSiswa,
      templateData: templateData,
    );

    isSavingNilai.value = false;

    if (isSuccess) {
      Get.back(); // Tutup bottom sheet
      Get.snackbar("Berhasil", "Nilai berhasil disimpan.");
      clearNilaiForm();
      nilaiMassalControllers.forEach((_, controller) => controller.clear());
    }
  }

  @override
  void clearNilaiForm() {
    suratC.clear();
    ayatHafalC.clear();
    capaianC.clear();
    materiC.clear();
    _keteranganHalaqoh.value = "";
    santriTerpilihUntukNilai.clear();
  }

   @override
  void onInit() {
    super.onInit();
    // [DIUBAH TOTAL] Logika onInit menjadi sangat sederhana
    isLoading.value = true;
    
    // Langsung panggil fungsi untuk memuat data dari HomeController
    _loadDataFromHomeController();
  }

  @override
  void onClose() {
    // _halaqohSubscription?.cancel();
    _homeControllerReadyWorker?.dispose();
    nilaiMassalControllers.forEach((_, controller) => controller.dispose());
    lokasiC.dispose(); suratC.dispose(); ayatHafalC.dispose();
    capaianC.dispose(); halAyatC.dispose(); materiC.dispose();
    capaianUjianC.dispose(); levelUjianC.dispose();
    super.onClose();
  }

  // --- FUNGSI UTAMA ---

  Future<void> _loadDataFromHomeController() async {
    // Beri sedikit waktu agar HomeController benar-benar siap
    await Future.delayed(const Duration(milliseconds: 100));

    // [AKTIFKAN] Gunakan getter baru dari HomeController untuk memesan data
    final kelompokList = homeC.kelompokPermanen;
    
    // [AKTIFKAN] Simpan data yang diterima ke dalam state
    daftarHalaqoh.assignAll(kelompokList);

    if (daftarHalaqoh.isNotEmpty) {
      // Jika berhasil menerima data, pilih kelompok pertama
      await gantiHalaqohTerpilih(daftarHalaqoh.first, isInitialLoad: true);
    } else {
      // Jika setelah memesan ternyata datanya kosong, matikan loading
      isLoading.value = false;
    }
  }

  Future<void> gantiHalaqohTerpilih(Map<String, dynamic> kelompokBaru, {bool isInitialLoad = false}) async {
    if (isLoading.value && !isInitialLoad) return;

    // Sekarang kita bisa kembali menggunakan perbandingan 'fase' yang sederhana,
    // karena tidak akan ada lagi fase duplikat di halaman ini.
    if (!isInitialLoad && halaqohTerpilih.value?['fase'] == kelompokBaru['fase']) {
      return;
    }
    
    halaqohTerpilih.value = kelompokBaru;
    daftarSiswa.clear();
    isLoading.value = true;

    try {
      await _siswaSubscription?.cancel(); 
      
      final refSiswa = _getDaftarSiswaCollectionRef();

      _siswaSubscription = refSiswa.orderBy('namasiswa').snapshots().listen((snapshot) {
        
        final List<SiswaHalaqoh> siswaList = List<SiswaHalaqoh>.from(
          snapshot.docs.map((doc) => SiswaHalaqoh.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        );

        siswaList.sort((a, b) {
          bool aSiap = a.statusUjian == 'siap_ujian';
          bool bSiap = b.statusUjian == 'siap_ujian';
          if (aSiap && !bSiap) return -1;
          if (!aSiap && bSiap) return 1;
          return a.namaSiswa.compareTo(b.namaSiswa);
        });

        daftarSiswa.assignAll(siswaList);

        nilaiMassalControllers.forEach((_, c) => c.dispose());
        nilaiMassalControllers.clear();
        for (var santri in daftarSiswa) {
          nilaiMassalControllers[santri.nisn] = TextEditingController();
        }
        
        if (isLoading.value) {
          isLoading.value = false;
        }
      }, onError: (e) {
        Get.snackbar("Error", "Gagal memuat data santri: $e");
        isLoading.value = false;
      });
    } catch (e) {
      Get.snackbar("Error Kritis", "Gagal memvalidasi struktur data kelompok: $e");
      isLoading.value = false;
    }
  }



  // --- (Sisa semua fungsi lainnya tidak berubah) ---

  // --- FUNGSI AKSI (UNTUK DIALOG & TOMBOL) ---

  Future<void> updateLokasiHalaqoh() async {
    final lokasiBaru = lokasiC.text.trim();
    if (lokasiBaru.isEmpty) {
      Get.snackbar("Peringatan", "Nama lokasi tidak boleh kosong.");
      return;
    }

    // Ambil data kelompok saat ini, pastikan tidak null
    final kelompok = halaqohTerpilih.value;
    if (kelompok == null) {
      Get.snackbar("Error", "Tidak ada kelompok halaqoh yang terpilih.");
      return;
    }
    
    isDialogLoading.value = true;
    
    try {
      WriteBatch batch = firestore.batch();
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final idPengampu = auth.currentUser!.uid;
      final idTempatAman = kelompok['tempatmengaji']; // Ini adalah ID aman yg tidak boleh diubah
      final fase = kelompok['fase'];
      final semesterAktif = homeC.semesterAktifId.value;

      // Path 1: Update Sumber Kebenaran Utama (/kelompokmengaji/...)
      // Hanya update field 'lokasi_terakhir' untuk nama tampilan.
      final refTempatUtama = firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(fase)
          .collection('pengampu').doc(idPengampu)
          .collection('tempat').doc(idTempatAman);
      batch.update(refTempatUtama, {'lokasi_terakhir': lokasiBaru});

      // Path 2: Update "Shortcut" di Dokumen Pegawai (/pegawai/...)
      // Update field yang sama untuk konsistensi. JANGAN sentuh 'tempatmengaji'.
      final refDiPegawai = firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('pegawai').doc(idPengampu)
          .collection('tahunajarankelompok').doc(idTahunAjaran)
          .collection('semester').doc(semesterAktif)
          .collection('kelompokmengaji').doc(fase);
      batch.update(refDiPegawai, {'lokasi_terakhir': lokasiBaru});
      
      await batch.commit();
      
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "Lokasi telah diperbarui.");
      
      // [PENTING] Muat ulang data dari server untuk memastikan UI 100% konsisten.
      // Kita panggil ulang gantiHalaqohTerpilih untuk me-refresh state dari Firestore.
      var updatedKelompok = Map<String, dynamic>.from(kelompok);
      updatedKelompok['lokasi_terakhir'] = lokasiBaru;
      
      // Ganti state lokal agar UI langsung update, lalu refresh data santri di background
      halaqohTerpilih.value = updatedKelompok; 
      gantiHalaqohTerpilih(updatedKelompok, isInitialLoad: true); // `isInitialLoad: true` untuk memaksa reload

    } catch (e) {
      Get.snackbar("Error", "Gagal update lokasi: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }

// --- FUNGSI HELPER (PENDUKUNG) ---

  CollectionReference<Map<String, dynamic>> _getDaftarSiswaCollectionRef() {
    final kelompok = halaqohTerpilih.value!;
    return firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelompokmengaji').doc(kelompok['fase'])
        .collection('pengampu').doc(auth.currentUser!.uid)
        .collection('tempat').doc(kelompok['tempatmengaji'])
        .collection('semester').doc(homeC.semesterAktifId.value)
        .collection('daftarsiswa');
  }
  
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