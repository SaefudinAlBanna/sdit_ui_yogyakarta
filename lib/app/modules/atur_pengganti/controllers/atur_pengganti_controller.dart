// lib/app/modules/atur_pengganti/controllers/atur_pengganti_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../home/controllers/home_controller.dart';

class AturPenggantiController extends GetxController {
  // --- DEPENDENSI ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  // --- STATE ---
  final RxBool isLoading = true.obs;
  final RxBool isDialogLoading = false.obs;
  
  /// Menyimpan daftar semua kelompok Halaqoh yang aktif
  final RxList<Map<String, dynamic>> daftarHalaqohHariIni = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetchHalaqohHariIni();
  }

  /// Mengambil semua kelompok dari semua fase
     Future<void> _fetchHalaqohHariIni() async {
    isLoading.value = true;
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final tanggalHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final tempatSnapshot = await firestore.collectionGroup('tempat')
          .where('tahunajaran', isEqualTo: idTahunAjaran)
          .get();
      
      // Gunakan Future.wait untuk performa maksimal
      final futures = tempatSnapshot.docs.map((doc) async {
        final data = doc.data();
        
        // Cek apakah ada sesi pengganti untuk hari ini
        final penggantiDoc = await doc.reference
            .collection('sesi_pengganti')
            .doc(tanggalHariIni)
            .get();
        
        return {
          'fase': data['fase'],
          'namaTempat': doc.id,
          'idPengampuAsli': data['idpengampu'],
          'namaPengampuAsli': data['namapengampu'],
          'adaPengganti': penggantiDoc.exists, // Status boolean
          'namaPengganti': penggantiDoc.exists ? penggantiDoc.data()!['nama_pengganti'] : null, // Nama pengganti jika ada
        };
      }).toList();

      final List<Map<String, dynamic>> hasilAkhir = await Future.wait(futures);
      
      daftarHalaqohHariIni.assignAll(hasilAkhir);

    } catch (e) {
      print(e);
      Get.snackbar("Error", "Gagal memuat daftar Halaqoh: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableGuruPengganti(String idPengampuAsli) async {
    // 1. Ambil kedua daftar kebijakan dari HomeController
    final List<String> role = homeC.rolePenggantiTahsin;
    final List<String> tugas = homeC.tugasPenggantiTahsin;

    // 2. Siapkan dua query untuk dijalankan secara paralel
    final queryByRole = firestore
        .collection('Sekolah').doc(homeC.idSekolah).collection('pegawai')
        .where('role', whereIn: role)
        .get();

    final queryByTugas = firestore
        .collection('Sekolah').doc(homeC.idSekolah).collection('pegawai')
        .where('tugas', arrayContainsAny: tugas)
        .get();
    
    // 3. Jalankan kedua query secara bersamaan
    final results = await Future.wait([queryByRole, queryByTugas]);
    final roleDocs = results[0].docs;
    final tugasDocs = results[1].docs;

    // 4. Gabungkan hasil dan hilangkan duplikasi menggunakan Map
    final Map<String, Map<String, dynamic>> uniquePegawai = {};

    for (var doc in roleDocs) {
      uniquePegawai[doc.id] = {'uid': doc.id, 'alias': doc.data()['alias'] ?? 'Tanpa Nama'};
    }
    for (var doc in tugasDocs) {
      uniquePegawai[doc.id] = {'uid': doc.id, 'alias': doc.data()['alias'] ?? 'Tanpa Nama'};
    }

    // 5. Filter pengampu asli dari daftar gabungan
    uniquePegawai.remove(idPengampuAsli);

    // 6. Kembalikan hasilnya sebagai List
    return uniquePegawai.values.toList();
  }

  

  /// [FUNGSI INTI] Menyimpan data sesi pengganti ke Firestore
  Future<void> simpanSesiPengganti(Map<String, dynamic> kelompok, Map<String, dynamic> guruPengganti) async {
    isDialogLoading.value = true;
    try {
      final String tanggalHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final docRef = firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
          .collection('kelompokmengaji').doc(kelompok['fase'])
          .collection('pengampu').doc(kelompok['idPengampuAsli'])
          .collection('tempat').doc(kelompok['namaTempat'])
          .collection('sesi_pengganti').doc(tanggalHariIni);
          
      await docRef.set({
        'uid_pengganti': guruPengganti['uid'],
        'nama_pengganti': guruPengganti['alias'],
        'uid_pengampu_asli': kelompok['idPengampuAsli'],
        'nama_pengampu_asli': kelompok['namaPengampuAsli'],
        'dicatat_oleh_uid': homeC.auth.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        // --- TAMBAHAN KUNCI DI SINI ---
        'tanggal': tanggalHariIni, // Simpan tanggal sebagai field
        'fase': kelompok['fase'], // Simpan info ini juga untuk kemudahan
        'namaTempat': kelompok['namaTempat'], // Simpan info ini juga
        'idTahunAjaran': homeC.idTahunAjaran.value!,
        'semester': homeC.semesterAktifId.value,
      });

      Get.back(); // Tutup dialog pilih guru
      Get.snackbar("Berhasil", "${guruPengganti['alias']} telah ditugaskan sebagai pengganti.");

    _fetchHalaqohHariIni(); 

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan sesi pengganti: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }

  Future<void> batalkanSesiPengganti(Map<String, dynamic> kelompok) async {
    Get.defaultDialog(
      title: "Konfirmasi",
      middleText: "Anda yakin ingin membatalkan sesi pengganti untuk kelompok ini?",
      textConfirm: "Ya, Batalkan",
      textCancel: "Tidak",
      onConfirm: () async {
        Get.back();
        isDialogLoading.value = true;
        try {
          final tanggalHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final docRef = firestore
              .collection('Sekolah').doc(homeC.idSekolah)
              .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
              .collection('kelompokmengaji').doc(kelompok['fase'])
              .collection('pengampu').doc(kelompok['idPengampuAsli'])
              .collection('tempat').doc(kelompok['namaTempat'])
              .collection('sesi_pengganti').doc(tanggalHariIni);
          
          await docRef.delete();
          Get.snackbar("Berhasil", "Sesi pengganti telah dibatalkan.");
          _fetchHalaqohHariIni(); // Muat ulang data
        } catch (e) {
          Get.snackbar("Error", "Gagal membatalkan: $e");
        } finally {
          isDialogLoading.value = false;
        }
      }
    );
  }

}