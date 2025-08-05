// lib/app/modules/guru_pengganti/controllers/guru_pengganti_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../home/controllers/home_controller.dart';

class GuruPenggantiController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final String idSekolah = "20404148";

  // --- STATE UTAMA ---
  // [DIHAPUS] selectedDate tidak lagi reaktif
  final DateTime today = DateTime.now();
  final Rxn<String> selectedKelasId = Rxn<String>();
  
  final RxBool isLoading = true.obs;
  final RxBool isLoadingJadwal = false.obs;
  
  // --- STATE DATA ---
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> jadwalTampil = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarGuru = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchDaftarKelas(),
        _fetchDaftarGuru(),
      ]);
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data awal: $e");
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _fetchDaftarKelas() async {
    isLoading.value = true;
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').orderBy('namakelas').get();

      if (snapshot.docs.isNotEmpty) {
        daftarKelas.value = snapshot.docs.map((doc) => {
          'id': doc.id,
          'nama': doc.data()['namakelas'] ?? doc.id,
        }).toList();
      }
    } catch (e) { Get.snackbar('Error', 'Gagal mengambil daftar kelas: ${e.toString()}'); } 
    finally { isLoading.value = false; }
  }
  
  Future<void> _fetchDaftarGuru() async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah)
        .collection('pegawai').where('role', whereIn: ['Guru Kelas', 'Guru Mapel', 'Pengampu']).get();
    daftarGuru.value = snapshot.docs.map((doc) => {'uid': doc.id, 'nama': doc.data()['alias']}).toList();
  }

  void onKelasChanged(String? kelasId) {
    if (kelasId != null) {
      selectedKelasId.value = kelasId;
      loadJadwalDanPengganti(); // Panggil fungsi utama yang baru
    }
  }

  // [DIROMBAK TOTAL] Fungsi ini sekarang menggabungkan jadwal & data pengganti
  Future<void> loadJadwalDanPengganti() async {
    if (selectedKelasId.value == null) return;
    isLoadingJadwal.value = true;
    jadwalTampil.clear();
    try {
      final String namaHari = DateFormat('EEEE', 'id_ID').format(today);
      if (namaHari == 'Sabtu' || namaHari == 'Minggu') return;

      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final docSnap = await firestore.collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('jadwalkelas').doc(selectedKelasId.value!).get();
          
      if (!docSnap.exists || !docSnap.data()!.containsKey(namaHari)) return;

      List<Map<String, dynamic>> jadwalPermanen = List<Map<String, dynamic>>.from(docSnap.data()![namaHari]);

      // Ambil data pengganti untuk kelas & tanggal ini
      final penggantiSnap = await firestore.collection('sesi_pengganti_kbm')
          .where('idKelas', isEqualTo: selectedKelasId.value)
          .where('tanggal', isEqualTo: DateFormat('yyyy-MM-dd').format(today))
          .get();
      
      final Map<String, Map<String, dynamic>> petaPengganti = {
        for (var doc in penggantiSnap.docs) doc.data()['jam']: {...doc.data(), 'idPenggantiDoc': doc.id}
      };

      // Gabungkan data
      List<Map<String, dynamic>> jadwalFinal = [];
      for (var slot in jadwalPermanen) {
        if (petaPengganti.containsKey(slot['jam'])) {
          // Jika ada pengganti, gunakan data pengganti
          slot['isReplaced'] = true;
          slot['penggantiInfo'] = petaPengganti[slot['jam']];
        } else {
          slot['isReplaced'] = false;
        }
        jadwalFinal.add(slot);
      }
      jadwalTampil.value = jadwalFinal;

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat jadwal: $e");
    } finally {
      isLoadingJadwal.value = false;
    }
  }
  
  // [BARU & KUNCI] Fungsi untuk mendapatkan daftar guru yang BEBAS
  Future<List<Map<String, dynamic>>> getGuruTersedia(String jam, String idGuruAsli) async {
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    final String namaHari = DateFormat('EEEE', 'id_ID').format(today);
    
    // 1. Dapatkan semua guru yang sudah punya jadwal permanen di jam ini
    final jadwalPermanenSnap = await firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('jadwalkelas').where(namaHari, arrayContainsAny: [{'jam': jam}]).get();

    Set<String> guruSibuk = {};
    for (var doc in jadwalPermanenSnap.docs) {
      final jadwalHari = doc.data()[namaHari] as List;
      final slot = jadwalHari.firstWhere((s) => s['jam'] == jam, orElse: () => null);
      if (slot != null && slot['idGuru'] != null) {
        guruSibuk.add(slot['idGuru']);
      }
    }

    // 2. Dapatkan semua guru yang sudah jadi pengganti di jam ini
    final penggantiSnap = await firestore.collection('sesi_pengganti_kbm')
        .where('tanggal', isEqualTo: DateFormat('yyyy-MM-dd').format(today))
        .where('jam', isEqualTo: jam).get();
        
    for (var doc in penggantiSnap.docs) {
      guruSibuk.add(doc.data()['idGuruPengganti']);
    }

    // 3. Filter daftar guru utama
    return daftarGuru.where((guru) {
      // Guru tersedia jika:
      // - ID-nya tidak ada di daftar sibuk
      // - DAN ID-nya bukan guru asli yang sedang digantikan
      return !guruSibuk.contains(guru['uid']) && guru['uid'] != idGuruAsli;
    }).toList();
  }

  Future<void> simpanPengganti(Map<String, dynamic> jadwalSlot, String idGuruPengganti) async {
    final guruPengganti = daftarGuru.firstWhere((g) => g['uid'] == idGuruPengganti);
    
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      // [FIX] Ambil data guru asli dari List, bukan field tunggal
      final List<dynamic> listIdGuruAsli = jadwalSlot['listIdGuru'] ?? [];
      final List<dynamic> listNamaGuruAsli = jadwalSlot['listNamaGuru'] ?? [];
  
      final dataToSave = {
        "tanggal": DateFormat('yyyy-MM-dd').format(today),
        "idKelas": selectedKelasId.value,
        "jam": jadwalSlot['jam'],
        "idMapel": jadwalSlot['idMapel'],
        // Ambil item pertama dari list, atau string kosong jika listnya kosong
        "idGuruAsli": listIdGuruAsli.isNotEmpty ? listIdGuruAsli.first : '',
        "namaGuruAsli": listNamaGuruAsli.isNotEmpty ? listNamaGuruAsli.first : '',
        "idGuruPengganti": idGuruPengganti,
        "namaGuruPengganti": guruPengganti['nama'],
        "catatanAdmin": "Penggantian manual oleh Admin.",
        "dibuatPada": FieldValue.serverTimestamp(),
      };
      
      await firestore.collection('sesi_pengganti_kbm').add(dataToSave);
      
      Get.back(); Get.back();
      Get.snackbar("Berhasil", "${guruPengganti['nama']} telah ditugaskan sebagai pengganti.");
      loadJadwalDanPengganti(); // Muat ulang
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Gagal menyimpan data pengganti: $e");
    }
  }

  // [BARU] Fungsi untuk membatalkan penugasan pengganti
  Future<void> batalkanPengganti(String idPenggantiDoc) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      await firestore.collection('sesi_pengganti_kbm').doc(idPenggantiDoc).delete();
      Get.back();
      Get.snackbar("Berhasil", "Penugasan pengganti telah dibatalkan.");
      loadJadwalDanPengganti(); // Muat ulang data untuk refresh UI
    } catch(e) {
      Get.back();
      Get.snackbar("Error", "Gagal membatalkan: $e");
    }
  }
}

// // lib/app/modules/guru_pengganti/controllers/guru_pengganti_controller.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../home/controllers/home_controller.dart';

// class GuruPenggantiController extends GetxController {
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;a
//   final HomeController homeC = Get.find<HomeController>();
//   final String idSekolah = "sdit-ui-yogyakarta";

//   // --- STATE UTAMA ---
//   final Rx<DateTime> selectedDate = DateTime.now().obs;
//   final Rxn<String> selectedKelasId = Rxn<String>();
  
//   final RxBool isLoading = true.obs;
//   final RxBool isLoadingJadwal = false.obs;
  
//   // --- STATE DATA ---
//   final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
//   final RxList<Map<String, dynamic>> jadwalHariIni = <Map<String, dynamic>>[].obs;
//   final RxList<Map<String, dynamic>> daftarGuru = <Map<String, dynamic>>[].obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _fetchInitialData();
//   }

//   Future<void> _fetchInitialData() async {
//     isLoading.value = true;
//     try {
//       await Future.wait([
//         _fetchDaftarKelas(),
//         _fetchDaftarGuru(),
//       ]);
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat data awal: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }
  
//   Future<void> _fetchDaftarKelas() async { /* ... (Sama seperti di BuatJadwalPelajaranController) ... */ }
//   Future<void> _fetchDaftarGuru() async {
//     final snapshot = await firestore.collection('Sekolah').doc(idSekolah)
//         .collection('pegawai').where('role', whereIn: ['Guru Kelas', 'Guru Mapel', 'Pengampu']).get();
//     daftarGuru.value = snapshot.docs.map((doc) => {'uid': doc.id, 'nama': doc.data()['alias']}).toList();
//   }

//   // --- AKSI PENGGUNA ---
//   void onDateChanged(DateTime newDate) {
//     selectedDate.value = newDate;
//     if (selectedKelasId.value != null) {
//       loadJadwal();
//     }
//   }

//   void onKelasChanged(String? kelasId) {
//     if (kelasId != null) {
//       selectedKelasId.value = kelasId;
//       loadJadwal();
//     }
//   }

//   Future<void> loadJadwal() async {
//     if (selectedKelasId.value == null) return;
//     isLoadingJadwal.value = true;
//     jadwalHariIni.clear();
//     try {
//       final String namaHari = DateFormat('EEEE', 'id_ID').format(selectedDate.value);
//       if (namaHari == 'Sabtu' || namaHari == 'Minggu') {
//         isLoadingJadwal.value = false;
//         return;
//       }

//       final idTahunAjaran = homeC.idTahunAjaran.value!;
//       final docSnap = await firestore.collection('Sekolah').doc(idSekolah)
//           .collection('tahunajaran').doc(idTahunAjaran)
//           .collection('jadwalkelas').doc(selectedKelasId.value!).get();
          
//       if (docSnap.exists && docSnap.data()!.containsKey(namaHari)) {
//         jadwalHariIni.value = List<Map<String, dynamic>>.from(docSnap.data()![namaHari]);
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat jadwal: $e");
//     } finally {
//       isLoadingJadwal.value = false;
//     }
//   }

//   Future<void> simpanPengganti(Map<String, dynamic> jadwalSlot, String idGuruPengganti) async {
//     final guruPengganti = daftarGuru.firstWhere((g) => g['uid'] == idGuruPengganti);
    
//     Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
//     try {
//       final dataToSave = {
//         "tanggal": DateFormat('yyyy-MM-dd').format(selectedDate.value),
//         "idKelas": selectedKelasId.value,
//         "jam": jadwalSlot['jam'],
//         "idMapel": jadwalSlot['idMapel'],
//         "idGuruAsli": jadwalSlot['idGuru'],
//         "namaGuruAsli": jadwalSlot['namaGuru'],
//         "idGuruPengganti": idGuruPengganti,
//         "namaGuruPengganti": guruPengganti['nama'],
//         "catatanAdmin": "Penggantian manual oleh Admin.",
//         "dibuatPada": FieldValue.serverTimestamp(),
//       };
      
//       await firestore.collection('sesi_pengganti_kbm').add(dataToSave);
      
//       Get.back(); // Tutup dialog loading
//       Get.back(); // Tutup dialog pemilihan guru
//       Get.snackbar("Berhasil", "${guruPengganti['nama']} telah ditugaskan sebagai pengganti.");
//       // Di masa depan, kita bisa refresh tampilan untuk menunjukkan siapa penggantinya
//     } catch (e) {
//       Get.back();
//       Get.snackbar("Error", "Gagal menyimpan data pengganti: $e");
//     }
//   }
// }