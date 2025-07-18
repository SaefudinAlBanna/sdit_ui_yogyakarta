// lib/app/modules/daftar_halaqoh_pengampu/controllers/daftar_halaqoh_pengampu_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';

class DaftarHalaqohPengampuController extends GetxController {

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  final RxBool isLoadingHalaqoh = true.obs;
  final RxBool isLoadingSantri = false.obs;
  final Rxn<String> tempatTerpilih = Rxn<String>();
  final RxList<String> daftarHalaqoh = <String>[].obs;
  final Rxn<String> halaqohTerpilih = Rxn<String>();
  final RxList<Map<String, dynamic>> daftarSantri = <Map<String, dynamic>>[].obs;

  final RxBool isSavingNilai = false.obs;

  // Controller untuk form template nilai
  final TextEditingController suratC = TextEditingController();
  final TextEditingController ayatHafalC = TextEditingController();
  final TextEditingController capaianC = TextEditingController();
  final TextEditingController halAyatC = TextEditingController();
  final TextEditingController materiC = TextEditingController();
  final TextEditingController nilaiC = TextEditingController();
  final RxString keteranganHalaqoh = "".obs;

  // List reaktif untuk menyimpan NISN santri yang dipilih (dicentang)
  final RxList<String> santriTerpilihUntukNilai = <String>[].obs;
  //========================================================================

  //========================================================================
  // --- STATE BARU UNTUK FITUR TANDAI SIAP UJIAN ---
  //========================================================================
  final RxBool isDialogLoading = false.obs; // Untuk loading dialog
  final TextEditingController capaianUjianC = TextEditingController();
  final TextEditingController levelUjianC = TextEditingController();
  final RxList<String> santriTerpilihUntukUjian = <String>[].obs;
  //========================================================================

  @override
  void onInit() {
    super.onInit();
    fetchHalaqohGroups();
  }

  @override
  void onClose() {
    // Dispose semua controller baru
    suratC.dispose();
    ayatHafalC.dispose();
    halAyatC.dispose();
    materiC.dispose();
    nilaiC.dispose();
    super.onClose();
  }

  /// 1. Mengambil daftar kelompok (sudah 'sadar semester' karena memanggil fungsi baru di HomeController).
  Future<void> fetchHalaqohGroups() async {
    try {
      isLoadingHalaqoh.value = true;
      final kelompok = await homeC.getDataKelompok(); // Fungsi ini sudah kita perbaiki
      daftarHalaqoh.assignAll(kelompok);

      if (daftarHalaqoh.isNotEmpty) {
        gantiHalaqohTerpilih(daftarHalaqoh.first);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat kelompok halaqoh: $e");
    } finally {
      isLoadingHalaqoh.value = false;
    }
  }
  
  /// 2. Aksi saat pengguna memilih kelompok (tidak ada perubahan).
  void gantiHalaqohTerpilih(String namaHalaqoh) {
    halaqohTerpilih.value = namaHalaqoh;
    tempatTerpilih.value = null; 
    fetchDaftarSantri(namaHalaqoh);
  }

  /// 3. [DIPERBARUI] Mengambil daftar santri dari path yang sudah ada semesternya.
  Future<void> fetchDaftarSantri(String namaHalaqoh) async {
    try {
      isLoadingSantri.value = true;
      daftarSantri.clear();

      // Ambil data global yang dibutuhkan
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      String semesterAktif = homeC.semesterAktifId.value;
      String idSekolah = homeC.idSekolah;
      String idUser = auth.currentUser!.uid;

      // Langkah A & B: Dapatkan namaPengampu dan namaTempat (tetap sama)
      final pegawaiDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
      if (!pegawaiDoc.exists) throw Exception("Data pengampu tidak ditemukan.");
      String namaPengampu = pegawaiDoc.data()!['alias'];

      final tempatSnapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelompokmengaji').doc(namaHalaqoh).collection('pengampu').doc(namaPengampu).collection('tempat').limit(1).get();
      if (tempatSnapshot.docs.isEmpty) {
        tempatTerpilih.value = null;
        daftarSantri.clear();
        return;
      }
      String namaTempat = tempatSnapshot.docs.first.id;
      tempatTerpilih.value = namaTempat;

      // Langkah C: Dapatkan daftar santri dasar
      final santriSnapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(namaHalaqoh)
          .collection('pengampu').doc(namaPengampu)
          .collection('tempat').doc(namaTempat)
          .collection('semester').doc(semesterAktif) // <-- Path semester sudah benar
          .collection('daftarsiswa').get();

      // Langkah D (BARU): Proses setiap santri untuk mendapatkan capaian terakhirnya
      if (santriSnapshot.docs.isNotEmpty) {
        // Buat daftar Future, di mana setiap Future akan mengembalikan Map santri yang sudah lengkap
        List<Future<Map<String, dynamic>>> futures = santriSnapshot.docs.map((doc) async {
          var data = doc.data();
          data['id'] = doc.id;
          
          // Ambil capaian terakhir dari dokumen induknya (denormalisasi)
          // Ini adalah cara paling efisien
          String capaianTerakhir = data['capaian_terakhir'] ?? '-';
          
          // Tambahkan field baru ke map
          data['capaian_untuk_view'] = capaianTerakhir;
          
          return data;
        }).toList();

        // Tunggu semua Future selesai
        final listSantriLengkap = await Future.wait(futures);
        
        daftarSantri.assignAll(listSantriLengkap);
      }

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar santri: $e");
      daftarSantri.clear();
      tempatTerpilih.value = null;
    } finally {
      isLoadingSantri.value = false;
    }
  }

  //========================================================================
  // --- LOGIKA BARU UNTUK FITUR INPUT NILAI MASSAL ---
  //========================================================================

  /// Mengelola checkbox santri. Dipanggil dari UI.
  void toggleSantriSelection(String nisn) {
    if (santriTerpilihUntukNilai.contains(nisn)) {
      santriTerpilihUntukNilai.remove(nisn);
    } else {
      santriTerpilihUntukNilai.add(nisn);
    }
  }

  /// Membersihkan form template nilai.
  void clearNilaiForm() {
    suratC.clear();
    ayatHafalC.clear();
    capaianC.clear();
    halAyatC.clear();
    materiC.clear();
    nilaiC.clear();
    keteranganHalaqoh.value = "";
    santriTerpilihUntukNilai.clear();
  }


  /// [FUNGSI INTI BARU] Menyimpan nilai dari template untuk semua santri yang terpilih.
  Future<void> simpanNilaiMassal() async {
    // 1. Validasi Input
    if (suratC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Surat hafalan wajib diisi."); return; }
    if (ayatHafalC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Ayat hafalan wajib diisi."); return; }
    if (capaianC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Capaian wajib diisi."); return; }
    if (materiC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Materi UMMI/AlQuran wajib diisi."); return; }
    if (nilaiC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Nilai wajib diisi."); return; }
    if (santriTerpilihUntukNilai.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu santri."); return; }

    isSavingNilai.value = true;
    try {
      // 2. Dapatkan data global (tetap sama)
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semesterAktif = homeC.semesterAktifId.value;
      final idSekolah = homeC.idSekolah;
      final now = DateTime.now();
      final docIdNilaiHarian = DateFormat('yyyy-MM-dd').format(now);

      int nilaiNumerik = int.tryParse(nilaiC.text.trim()) ?? 0;
      if (nilaiNumerik > 98) nilaiNumerik = 98;
      String grade = _getGrade(nilaiNumerik);
      
      final batch = firestore.batch();
      
      final Map<String, dynamic> dataNilaiTemplate = {
        "tanggalinput": now.toIso8601String(),
        "emailpenginput": auth.currentUser!.email!,
        "idpengampu": auth.currentUser!.uid,
        "hafalansurat": suratC.text.trim(),
        "ayathafalansurat": ayatHafalC.text.trim(),
        "capaian": capaianC.text.trim(),
        "ummihalatauayat": halAyatC.text.trim(),
        "materi": materiC.text.trim(),
        "nilai": nilaiNumerik,
        "nilaihuruf": grade,
        "keteranganpengampu": keteranganHalaqoh.value,
        "uidnilai": docIdNilaiHarian,
        "semester": semesterAktif,
      };

      // 3. Looping untuk setiap santri yang terpilih
      for (String nisn in santriTerpilihUntukNilai) {
        // Cari data lengkap santri dari list yang sudah ada
        final santriData = daftarSantri.firstWhere((s) => s['id'] == nisn);

        // Path ke dokumen nilai siswa
        final docNilaiRef = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(santriData['fase'])
          .collection('pengampu').doc(santriData['namapengampu'])
          .collection('tempat').doc(santriData['tempatmengaji'])
          .collection('semester').doc(semesterAktif)
          .collection('daftarsiswa').doc(nisn)
          .collection('nilai').doc(docIdNilaiHarian);

          final docSiswaIndukRef = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          // ... (sisa path ke .../daftarsiswa/{nisn})
          .collection('kelompokmengaji').doc(santriData['fase'])
          .collection('pengampu').doc(santriData['namapengampu'])
          .collection('tempat').doc(santriData['tempatmengaji'])
          .collection('semester').doc(semesterAktif)
          .collection('daftarsiswa').doc(nisn);
        
        // Gabungkan template dengan data spesifik santri
        final dataFinal = {
          ...dataNilaiTemplate,
          "fase": santriData['fase'],
          "idsiswa": nisn,
          "kelas": santriData['kelas'],
          "kelompokmengaji": santriData['kelompokmengaji'],
          "namapengampu": santriData['namapengampu'],
          "namasiswa": santriData['namasiswa'],
          "tahunajaran": santriData['tahunajaran'],
          "tempatmengaji": santriData['tempatmengaji'],
        };
        
        // Tambahkan operasi set (atau update jika perlu) ke dalam batch
        batch.set(docNilaiRef, dataFinal, SetOptions(merge: true));

        batch.update(docSiswaIndukRef, {
          'capaian_terakhir': capaianC.text.trim(),
          'tanggal_update_terakhir': now,
        });
      }
      

      // 4. Commit semua operasi sekaligus
      await batch.commit();

      Get.back(); // Tutup bottom sheet
      Get.snackbar(
        "Berhasil", 
        "Nilai berhasil disimpan untuk ${santriTerpilihUntukNilai.length} santri.",
        backgroundColor: Colors.green, colorText: Colors.white
      );
      clearNilaiForm(); // Bersihkan form setelah berhasil

      fetchDaftarSantri(halaqohTerpilih.value!);

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan nilai: ${e.toString()}");
    } finally {
      isSavingNilai.value = false;
    }
  }

  //========================================================================
  // --- FUNGSI BARU UNTUK FITUR TANDAI SIAP UJIAN ---
  //========================================================================

  void toggleSantriSelectionForUjian(String nisn) {
    if (santriTerpilihUntukUjian.contains(nisn)) {
      santriTerpilihUntukUjian.remove(nisn);
    } else {
      santriTerpilihUntukUjian.add(nisn);
    }
  }

  Future<void> tandaiSiapUjianMassal() async {
    if (levelUjianC.text.trim().isEmpty || capaianUjianC.text.trim().isEmpty || santriTerpilihUntukUjian.isEmpty) {
      Get.snackbar("Peringatan", "Isi semua field dan pilih minimal satu santri."); return;
    }
    isDialogLoading.value = true;
    try {
      final batch = firestore.batch();
      final refDaftarSiswa = await _getDaftarSiswaCollectionRef();
      final now = DateTime.now();
      final String uidPendaftar = auth.currentUser!.uid;

      for (String nisn in santriTerpilihUntukUjian) {
        final docSiswaIndukRef = refDaftarSiswa.doc(nisn);
        final docUjianBaruRef = docSiswaIndukRef.collection('ujian').doc();

        batch.update(docSiswaIndukRef, {'status_ujian': 'siap_ujian'});
        batch.set(docUjianBaruRef, {
          'status_ujian': 'siap_ujian',
          'level_ujian': levelUjianC.text.trim(),
          'capaian_saat_didaftarkan': capaianUjianC.text.trim(),
          'tanggal_didaftarkan': now,
          'didaftarkan_oleh': uidPendaftar,
          'semester': homeC.semesterAktifId.value,
          'tanggal_ujian': null, 'diuji_oleh': null, 'catatan_penguji': null,
        });
      }

      await batch.commit();
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "${santriTerpilihUntukUjian.length} santri telah ditandai siap ujian.");
      santriTerpilihUntukUjian.clear();
      capaianUjianC.clear();
      levelUjianC.clear();
      // Muat ulang data untuk refresh status di UI
      fetchDaftarSantri(halaqohTerpilih.value!);
    } catch (e) {
      Get.snackbar("Error", "Gagal menandai siswa: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }

  /// Helper untuk mendapatkan path koleksi daftarsiswa
  Future<CollectionReference<Map<String, dynamic>>> _getDaftarSiswaCollectionRef() async {
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    final semesterAktif = homeC.semesterAktifId.value;
    final idSekolah = homeC.idSekolah;
    final idUser = auth.currentUser!.uid;
    final pegawaiDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
    final namaPengampu = pegawaiDoc.data()!['alias'];
    
    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(halaqohTerpilih.value!)
        .collection('pengampu').doc(namaPengampu)
        .collection('tempat').doc(tempatTerpilih.value!)
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa');
  }


  String _getGrade(int score) {
    if (score >= 90) return 'A'; // A/A+ disederhanakan menjadi A
    if (score >= 85) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 75) return 'B-';
    if (score >= 70) return 'C+';
    if (score >= 65) return 'C';
    if (score >= 60) return 'C-';
    return 'D';
  }
}