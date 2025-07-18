// lib/app/modules/jurnal_ajar_harian/controllers/jurnal_ajar_harian_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import HomeController untuk mengakses data global
import '../../home/controllers/home_controller.dart';

class JurnalAjarHarianController extends GetxController {
  
  //========================================================================
  // --- BAGIAN 1: STATE MANAGEMENT BARU ---
  // Penjelasan: Kita merombak total state management untuk mendukung UI baru.
  //========================================================================
  
  var isLoading = false.obs; // Untuk loading data awal (kelas & jam)
  var isSaving = false.obs;  // Untuk proses penyimpanan

  // State BARU untuk menyimpan daftar item yang dipilih pengguna.
  // `.obs` membuat list ini reaktif, sehingga UI akan update saat isinya berubah.
  var selectedKelasList = <String>[].obs;
  var selectedJamList = <String>[].obs;

  // State untuk dropdown mata pelajaran.
  var selectedMapel = Rxn<String>(); // Rxn<String> bisa menampung null

  // Controller standar untuk text field.
  late TextEditingController materimapelC;
  late TextEditingController catatanjurnalC;

  // --- INSTANCE & INFO DASAR ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late final String idUser;
  late final String emailAdmin;
  final String idSekolah = '20404148';
  
  // Mengambil instance HomeController yang sudah ada untuk mengakses data global
  final HomeController homeController = Get.find<HomeController>();

  //========================================================================
  // --- BAGIAN 2: FUNGSI INIT & DISPOSE ---
  //========================================================================

  @override
  void onInit() {
    super.onInit();
    materimapelC = TextEditingController();
    catatanjurnalC = TextEditingController();

    final user = auth.currentUser;
    if (user != null) {
      idUser = user.uid;
      emailAdmin = user.email!;
    } else {
      Get.offAllNamed('/login');
      idUser = '';
      emailAdmin = '';
      Get.snackbar("Error", "Sesi Anda telah berakhir. Silakan login kembali.");
    }
  }

  @override
  void onClose() {
    materimapelC.dispose();
    catatanjurnalC.dispose();
    super.onClose();
  }

  //========================================================================
  // --- BAGIAN 3: LOGIKA UNTUK UI (VIEW) ---
  // Penjelasan: Fungsi-fungsi ini akan dipanggil oleh View saat pengguna
  // mengetuk ChoiceChip atau dropdown.
  //========================================================================

  /// Mengelola pemilihan kelas. Dipanggil saat ChoiceChip kelas ditekan.
  void toggleKelasSelection(String namaKelas) {
    if (selectedKelasList.contains(namaKelas)) {
      selectedKelasList.remove(namaKelas);
    } else {
      selectedKelasList.add(namaKelas);
    }
    // Setiap kali pilihan kelas berubah, reset pilihan mapel.
    selectedMapel.value = null;
    // `update()` di sini akan memicu GetBuilder di DropdownSearch untuk memuat ulang item.
    update(['mapel-dropdown']); 
  }

  /// Mengelola pemilihan jam pelajaran. Dipanggil saat ChoiceChip jam ditekan.
  void toggleJamSelection(String jamPelajaran) {
    if (selectedJamList.contains(jamPelajaran)) {
      selectedJamList.remove(jamPelajaran);
    } else {
      selectedJamList.add(jamPelajaran);
    }
  }

  /// Mengelola perubahan dropdown mata pelajaran.
  void onMapelChanged(String? value) {
    selectedMapel.value = value;
  }

  //========================================================================
  // --- BAGIAN 4: PENGAMBILAN DATA DARI FIRESTORE ---
  // Penjelasan: Fungsi-fungsi ini mengambil data yang dibutuhkan untuk UI.
  //========================================================================

  /// [TETAP] Mengambil data jam pelajaran, tidak ada perubahan.
  Future<QuerySnapshot<Map<String, dynamic>>> getJamPelajaran() {
    return firestore.collection('Sekolah').doc(idSekolah).collection('jampelajaran').get();
  }

  /// [BARU] Mengambil daftar kelas yang diajar oleh guru ini.
  Future<List<String>> getDataKelasYangDiajar() async {
    final idTahunAjaran = homeController.idTahunAjaran.value;
    if (idTahunAjaran == null) return [];

    try {
      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('pegawai').doc(idUser)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelasnya').get();
          
      final kelasList = snapshot.docs.map((doc) => doc.id).toList();
      kelasList.sort();
      return kelasList;
    } catch (e) {
      print("Error getDataKelasYangDiajar: $e");
      return [];
    }
  }

  /// [DIPERBARUI] Mengambil daftar mapel dari SEMUA kelas yang terpilih.
  Future<List<String>> getDataMapel() async {
    // Jika tidak ada kelas yang dipilih, kembalikan list kosong.
    if (selectedKelasList.isEmpty) {
      return [];
    }

    final idTahunAjaran = homeController.idTahunAjaran.value;
    if (idTahunAjaran == null) return [];

    try {
      // Set untuk menampung semua mapel dan otomatis menghilangkan duplikat.
      Set<String> allMapel = {};

      // Loop melalui setiap kelas yang dipilih.
      for (String namaKelas in selectedKelasList) {
        final snapshot = await firestore
            .collection('Sekolah').doc(idSekolah)
            .collection('pegawai').doc(idUser)
            .collection('tahunajaran').doc(idTahunAjaran)
            .collection('kelasnya').doc(namaKelas)
            .collection('matapelajaran').get();
        
        for (var doc in snapshot.docs) {
          allMapel.add(doc.id);
        }
      }
      
      final mapelList = allMapel.toList();
      mapelList.sort();
      return mapelList;

    } catch (e) {
      print("Error getDataMapel (multi-kelas): $e");
      return [];
    }
  }

  //========================================================================
  // --- BAGIAN 5: FUNGSI SIMPAN DATA (DIRUMBAK TOTAL) ---
  // Penjelasan: Ini adalah inti dari perubahan. Menggunakan looping ganda
  // dan path yang sudah menyertakan semester.
  //========================================================================
  Future<void> simpanJurnal() async {
    // 1. Validasi Input Pengguna
    if (selectedKelasList.isEmpty) {
      Get.snackbar("Peringatan", "Pilih minimal satu kelas."); return;
    }
    if (selectedJamList.isEmpty) {
      Get.snackbar("Peringatan", "Pilih minimal satu jam pelajaran."); return;
    }
    if (selectedMapel.value == null) {
      Get.snackbar("Peringatan", "Mata pelajaran wajib dipilih."); return;
    }
    if (materimapelC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Materi pelajaran wajib diisi."); return;
    }

    isSaving.value = true;
    try {
      // 2. Dapatkan data global (tahun ajaran & semester) dari HomeController
      final idTahunAjaran = homeController.idTahunAjaran.value!;
      final semesterAktif = homeController.semesterAktifId.value;
      
      final now = DateTime.now();
      final docIdTanggalJurnal = DateFormat.yMd('id_ID').format(now).replaceAll('/', '-');
      final guruDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
      final namaGuru = guruDoc.data()?['alias'] as String? ?? 'Guru';

      // 3. Buat instance WriteBatch. Semua operasi akan dikumpulkan di sini.
      final batch = firestore.batch();

      // Siapkan data jurnal utama sekali saja.
      // `kelas` & `jampelajaran` akan diisi dinamis di dalam loop.
      final dataJurnalTemplate = {
        'namamapel': selectedMapel.value,
        'materipelajaran': materimapelC.text.trim(),
        'catatanjurnal': catatanjurnalC.text.trim(),
        'tanggalinput': now.toIso8601String(),
        'idpenginput': idUser,
        'emailpenginput': emailAdmin,
        'namapenginput': namaGuru,
        'uidtanggal': docIdTanggalJurnal,
        'timestamp': now,
        'semester': semesterAktif,
      };

      // 4. Looping Ganda
      for (String namaKelas in selectedKelasList) {
        for (String jamPelajaran in selectedJamList) {
          
          // Buat data spesifik untuk iterasi ini
          final dataJurnalFinal = {
            ...dataJurnalTemplate,
            'kelas': namaKelas,
            'jampelajaran': jamPelajaran,
          };

          // --- Path 1: Rekap di Kelas (kelastahunajaran) dengan struktur semester ---
          final refKelas = firestore.collection('Sekolah').doc(idSekolah)
              .collection('tahunajaran').doc(idTahunAjaran)
              .collection('kelastahunajaran').doc(namaKelas)
              .collection('semester').doc(semesterAktif) // <-- INTEGRASI SEMESTER
              .collection('tanggaljurnal').doc(docIdTanggalJurnal)
              .collection('jurnalkelas').doc(jamPelajaran);
          batch.set(refKelas, dataJurnalFinal);

          // --- Path 2: Rekap di Guru (pegawai) dengan struktur semester ---
          final refGuru = firestore.collection('Sekolah').doc(idSekolah)
              .collection('pegawai').doc(idUser)
              .collection('tahunajaran').doc(idTahunAjaran)
              .collection('semester').doc(semesterAktif) // <-- INTEGRASI SEMESTER
              .collection('tanggaljurnal').doc(docIdTanggalJurnal)
              .collection('jurnalkelas').doc(jamPelajaran);
          batch.set(refGuru, dataJurnalFinal);
          
          // --- Path 3: Data Flat untuk Laporan (jurnal_flat), tanpa semester ---
          final refFlat = firestore.collection('Sekolah').doc(idSekolah).collection('jurnal_flat').doc();
          batch.set(refFlat, dataJurnalFinal);
        }
      }

      // 5. Commit semua operasi tulis yang sudah dikumpulkan.
      await batch.commit();

      Get.back(); // Tutup halaman input
      Get.snackbar(
        "Berhasil", 
        "Jurnal berhasil disimpan untuk ${selectedKelasList.length} kelas dan ${selectedJamList.length} jam pelajaran.",
        backgroundColor: Colors.green.shade700, colorText: Colors.white,
      );

    } catch (e) {
      print("Error simpanJurnal (multi): $e");
      Get.snackbar(
        "Gagal Menyimpan", "Terjadi kesalahan: ${e.toString()}",
        backgroundColor: Colors.red.shade700, colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  //========================================================================
  // --- BAGIAN 6: STREAM RIWAYAT JURNAL ---
  // Penjelasan: Kita juga perlu memperbarui ini agar membaca dari path semester yang benar.
  //========================================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> getJurnalHariIni() {
    try {
      final idTahunAjaran = homeController.idTahunAjaran.value!;
      final semesterAktif = homeController.semesterAktifId.value;
      final now = DateTime.now();
      final docIdJurnal = DateFormat.yMd('id_ID').format(now).replaceAll('/', '-');

      return firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('pegawai').doc(idUser)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('semester').doc(semesterAktif) // <-- INTEGRASI SEMESTER
          .collection('tanggaljurnal').doc(docIdJurnal)
          .collection('jurnalkelas')
          .orderBy('tanggalinput', descending: true)
          .snapshots();
    } catch (e) {
      print("Error getJurnalHariIni: $e");
      return Stream.error(e);
    }
  }
}