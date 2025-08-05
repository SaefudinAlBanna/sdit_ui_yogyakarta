// lib/app/modules/halaman_pengganti/controllers/halaman_pengganti_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/siswa_halaqoh.dart';
import '../../home/controllers/home_controller.dart';
import '../../../services/halaqoh_service.dart';
import '../../../interfaces/input_nilai_massal_interface.dart';
import '../../../widgets/tandai_siap_ujian_sheet.dart';
import 'package:flutter/material.dart';

class HalamanPenggantiController extends GetxController 
    implements IInputNilaiMassalController, ITandaiSiapUjianController {

  // --- Implementasi Kontrak ---
  @override final RxBool isSavingNilai = false.obs;
  @override final RxList<SiswaHalaqoh> daftarSiswa = <SiswaHalaqoh>[].obs;
  @override final RxList<String> santriTerpilihUntukNilai = <String>[].obs;
  @override Map<String, TextEditingController> nilaiMassalControllers = {};
  @override final TextEditingController suratC = TextEditingController();
  @override final TextEditingController ayatHafalC = TextEditingController();
  @override final TextEditingController capaianC = TextEditingController();
  @override final TextEditingController materiC = TextEditingController();
  @override RxString get keteranganHalaqoh => _keteranganHalaqoh;
  final RxString _keteranganHalaqoh = "".obs;
  @override final RxBool isDialogLoading = false.obs;
  @override final RxList<String> santriTerpilihUntukUjian = <String>[].obs;

  // --- State Halaman ---
  final RxBool isLoading = true.obs;
  // [PERBAIKAN] Gunakan nama variabel yang konsisten
  final RxList<Map<String, dynamic>> daftarHalaqoh = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> halaqohTerpilih = Rxn<Map<String, dynamic>>();
  StreamSubscription? _siswaSubscription;

  // --- Dependensi ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final HalaqohService halaqohService = Get.find();

  @override
  void onInit() {
    super.onInit();
    _fetchTugasPengganti();
  }
  
  @override
  void onClose() {
    _siswaSubscription?.cancel();
    // Dispose semua controller
    suratC.dispose(); ayatHafalC.dispose(); capaianC.dispose(); materiC.dispose();
    nilaiMassalControllers.forEach((_, c) => c.dispose());
    super.onClose();
  }

  // [DIUBAH TOTAL] Fungsi ini sekarang sudah benar
  Future<void> _fetchTugasPengganti() async {
    isLoading.value = true;
    try {
      final tanggalHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final sesiPenggantiSnapshot = await firestore.collectionGroup('sesi_pengganti')
          .where('tanggal', isEqualTo: tanggalHariIni)
          .where('uid_pengganti', isEqualTo: homeC.idUser)
          .get();
      
      final List<Map<String, dynamic>> kelompokPengganti = [];
      if (sesiPenggantiSnapshot.docs.isNotEmpty) {
        for (var doc in sesiPenggantiSnapshot.docs) {
          final data = doc.data();
          kelompokPengganti.add({
            'fase': data['fase'],
            'tempatmengaji': data['namaTempat'],
            'idpengampu': data['uid_pengganti'],
            'namapengampu': data['nama_pengganti'],
            'idPengampuAsli': data['uid_pengampu_asli'],
            'namaPengampuAsli': data['nama_pengampu_asli'],
            'isPengganti': true,
          });
        }
      }
      // [PERBAIKAN] Isi variabel yang benar
      daftarHalaqoh.assignAll(kelompokPengganti);

      if (daftarHalaqoh.isNotEmpty) {
        await gantiHalaqohTerpilih(daftarHalaqoh.first);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat tugas pengganti: $e");
    } finally {
      isLoading.value = false;
    }
  }

    Future<void> gantiHalaqohTerpilih(Map<String, dynamic> kelompokBaru) async {
    halaqohTerpilih.value = kelompokBaru;
    daftarSiswa.clear();
    isLoading.value = true;
    try {
      final String idPengampuUntukQuery = kelompokBaru['idPengampuAsli'];
      
      final refPengampu = firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
          .collection('kelompokmengaji').doc(kelompokBaru['fase'])
          .collection('pengampu').doc(idPengampuUntukQuery);

      final tempatSnapshot = await refPengampu.collection('tempat').limit(1).get();
      if (tempatSnapshot.docs.isEmpty) throw Exception("Struktur data tempat tidak ditemukan!");
      
      final String idTempatYangBenar = tempatSnapshot.docs.first.id;
      
      await _siswaSubscription?.cancel();
      
      final refSiswa = refPengampu.collection('tempat').doc(idTempatYangBenar)
          .collection('semester').doc(homeC.semesterAktifId.value)
          .collection('daftarsiswa');

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
  void clearNilaiForm() {
    suratC.clear();
    ayatHafalC.clear();
    capaianC.clear();
    materiC.clear();
    _keteranganHalaqoh.value = "";
    santriTerpilihUntukNilai.clear();
  }

  // ... (sisa controller Anda sudah benar)
  // Fungsi gantiHalaqohTerpilih, simpanNilaiMassal, tandaiSiapUjianMassal, dll.
  // sudah benar karena mereka membaca dari `halaqohTerpilih` dan `daftarSiswa`.

}


// // lib/app/modules/halaman_pengganti/controllers/halaman_pengganti_controller.dart

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../../models/siswa_halaqoh.dart';
// import '../../home/controllers/home_controller.dart';
// import '../../../services/halaqoh_service.dart';
// // Import interface juga untuk konsistensi
// import '../../../interfaces/input_nilai_massal_interface.dart';
// import '../../../widgets/tandai_siap_ujian_sheet.dart';
// import 'package:flutter/material.dart';

// class HalamanPenggantiController extends GetxController 
//     implements IInputNilaiMassalController, ITandaiSiapUjianController {

//   // Implementasi kontrak (sama seperti controller pengampu asli)
//   @override final RxBool isSavingNilai = false.obs;
//   @override final RxList<SiswaHalaqoh> daftarSiswa = <SiswaHalaqoh>[].obs;
//   @override final RxList<String> santriTerpilihUntukNilai = <String>[].obs;
//   @override Map<String, TextEditingController> nilaiMassalControllers = {};
//   @override final TextEditingController suratC = TextEditingController();
//   @override final TextEditingController ayatHafalC = TextEditingController();
//   @override final TextEditingController capaianC = TextEditingController();
//   @override final TextEditingController materiC = TextEditingController();
//   @override RxString get keteranganHalaqoh => _keteranganHalaqoh;
//   final RxString _keteranganHalaqoh = "".obs;
//   @override final RxBool isDialogLoading = false.obs;
//   @override final RxList<String> santriTerpilihUntukUjian = <String>[].obs;

//   // State Halaman
//   final RxBool isLoading = true.obs;
//   final RxList<Map<String, dynamic>> daftarHalaqohPengganti = <Map<String, dynamic>>[].obs;
//   final Rxn<Map<String, dynamic>> halaqohTerpilih = Rxn<Map<String, dynamic>>();
//   final RxList<Map<String, dynamic>> daftarHalaqoh = <Map<String, dynamic>>[].obs;

//   StreamSubscription? _siswaSubscription;

//   // Dependensi
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final HomeController homeC = Get.find<HomeController>();
//   final HalaqohService halaqohService = Get.find();

//   @override
//   void onInit() {
//     super.onInit();
//     _fetchTugasPengganti();
//   }
  
//   @override
//   void onClose() {
//     _siswaSubscription?.cancel();
//     // ... dispose semua controller ...
//     // _homeControllerReadyWorker?.dispose();
//     nilaiMassalControllers.forEach((_, controller) => controller.dispose());
//     // lokasiC.dispose();
//     ayatHafalC.dispose();
//      suratC.dispose(); ayatHafalC.dispose();
//     capaianC.dispose();
//     // halAyatC.dispose(); 
//     materiC.dispose();
//     // capaianUjianC.dispose(); 
//     // levelUjianC.dispose();
//     super.onClose();
//     super.onClose();
//   }

//   // Fungsi untuk mengambil data awal (hanya kelompok pengganti)
//   Future<void> _fetchTugasPengganti() async {
//     isLoading.value = true;
//     try {
//       final tanggalHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
//       final sesiPenggantiSnapshot = await firestore.collectionGroup('sesi_pengganti')
//           .where('tanggal', isEqualTo: tanggalHariIni)
//           .where('uid_pengganti', isEqualTo: homeC.idUser)
//           .get();
      
//       final List<Map<String, dynamic>> kelompokPengganti = [];
//       if (sesiPenggantiSnapshot.docs.isNotEmpty) {
//         for (var doc in sesiPenggantiSnapshot.docs) {
//           final data = doc.data();
//           kelompokPengganti.add({
//             'fase': data['fase'],
//             'tempatmengaji': data['namaTempat'],
//             'idpengampu': data['uid_pengganti'],
//             'namapengampu': data['nama_pengganti'],
//             'idPengampuAsli': data['uid_pengampu_asli'],
//             'namaPengampuAsli': data['nama_pengampu_asli'],
//             'isPengganti': true,
//           });
//         }
//       }
//       // daftarHalaqohPengganti.assignAll(kelompokPengganti);
//       daftarHalaqoh.assignAll(kelompokPengganti);

//       if (daftarHalaqohPengganti.isNotEmpty) {
//         await gantiHalaqohTerpilih(daftarHalaqohPengganti.first);
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat tugas pengganti: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // Fungsi gantiHalaqohTerpilih ini 100% identik dengan yang ada
//   // di DaftarHalaqohPengampuController versi pengganti.
//   Future<void> gantiHalaqohTerpilih(Map<String, dynamic> kelompokBaru) async {
//     halaqohTerpilih.value = kelompokBaru;
//     daftarSiswa.clear();
//     isLoading.value = true;
//     try {
//       final String idPengampuUntukQuery = kelompokBaru['idPengampuAsli'];
      
//       final refPengampu = firestore.collection('Sekolah').doc(homeC.idSekolah)
//           .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
//           .collection('kelompokmengaji').doc(kelompokBaru['fase'])
//           .collection('pengampu').doc(idPengampuUntukQuery);

//       final tempatSnapshot = await refPengampu.collection('tempat').limit(1).get();
//       if (tempatSnapshot.docs.isEmpty) throw Exception("Struktur data tempat tidak ditemukan!");
      
//       final String idTempatYangBenar = tempatSnapshot.docs.first.id;
      
//       await _siswaSubscription?.cancel();
      
//       final refSiswa = refPengampu.collection('tempat').doc(idTempatYangBenar)
//           .collection('semester').doc(homeC.semesterAktifId.value)
//           .collection('daftarsiswa');

//       _siswaSubscription = refSiswa.orderBy('namasiswa').snapshots().listen((snapshot) {
        
//         final List<SiswaHalaqoh> siswaList = List<SiswaHalaqoh>.from(
//           snapshot.docs.map((doc) => SiswaHalaqoh.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
//         );

//         siswaList.sort((a, b) {
//           bool aSiap = a.statusUjian == 'siap_ujian';
//           bool bSiap = b.statusUjian == 'siap_ujian';
//           if (aSiap && !bSiap) return -1;
//           if (!aSiap && bSiap) return 1;
//           return a.namaSiswa.compareTo(b.namaSiswa);
//         });

//         daftarSiswa.assignAll(siswaList);

//         nilaiMassalControllers.forEach((_, c) => c.dispose());
//         nilaiMassalControllers.clear();
//         for (var santri in daftarSiswa) {
//           nilaiMassalControllers[santri.nisn] = TextEditingController();
//         }
        
//         if (isLoading.value) {
//           isLoading.value = false;
//         }
//       }, onError: (e) {
//         Get.snackbar("Error", "Gagal memuat data santri: $e");
//         isLoading.value = false;
//       });
//     } catch (e) {
//       Get.snackbar("Error Kritis", "Gagal memvalidasi struktur data kelompok: $e");
//       isLoading.value = false;
//     }
//   }

//   // Semua fungsi kontrak (simpanNilaiMassal, tandaiSiapUjian, dll)
//   // akan sama persis seperti di DaftarHalaqohPengampuController karena mereka
//   // hanya memanggil HalaqohService. Anda bisa salin-tempel dari sana.
//   @override 
//   Future<void> simpanNilaiMassal() async {
//     if (santriTerpilihUntukNilai.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu santri."); return; }
//     // Validasi lain bisa ditambahkan di sini jika perlu

//     isSavingNilai.value = true;

//     // Siapkan data yang dibutuhkan oleh service
//     final Map<String, String> nilaiPerSiswa = {};
//     for (var nisn in santriTerpilihUntukNilai) {
//       nilaiPerSiswa[nisn] = nilaiMassalControllers[nisn]?.text ?? '';
//     }

//     final templateData = {
//       'surat': suratC.text.trim(),
//       'ayat': ayatHafalC.text.trim(),
//       'capaian': capaianC.text.trim(),
//       'materi': materiC.text.trim(),
//       'keterangan': keteranganHalaqoh.value,
//     };

//     // Panggil service
//     final bool isSuccess = await halaqohService.inputNilaiMassal(
//       infoKelompok: halaqohTerpilih.value!,
//       semuaSiswaDiKelompok: daftarSiswa.map((s) => s.rawData).toList(),
//       daftarNisnTerpilih: santriTerpilihUntukNilai,
//       nilaiPerSiswa: nilaiPerSiswa,
//       templateData: templateData,
//     );

//     isSavingNilai.value = false;

//     if (isSuccess) {
//       Get.back(); // Tutup bottom sheet
//       Get.snackbar("Berhasil", "Nilai berhasil disimpan.");
//       clearNilaiForm();
//       nilaiMassalControllers.forEach((_, controller) => controller.clear());
//     }
//   }

//   @override 
//   Future<void> tandaiSiapUjianMassal() async {
//     if (santriTerpilihUntukUjian.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu santri."); return; }

//     isDialogLoading.value = true;
    
//     // Filter objek SiswaHalaqoh lengkap berdasarkan nisn yang terpilih
//     final List<SiswaHalaqoh> siswaTerpilihObjek = daftarSiswa
//         .where((siswa) => santriTerpilihUntukUjian.contains(siswa.nisn))
//         .toList();

//     final bool isSuccess = await halaqohService.tandaiSiapUjianMassal(
//       infoKelompok: halaqohTerpilih.value!,
//       siswaTerpilih: siswaTerpilihObjek,
//     );

//     isDialogLoading.value = false;

//     if (isSuccess) {
//       Get.back(); // Tutup bottom sheet
//       Get.snackbar("Berhasil", "${santriTerpilihUntukUjian.length} santri telah ditandai siap ujian.");
//       santriTerpilihUntukUjian.clear();
//     }
//   }

//   @override
//   void toggleSantriSelection(String nisn) {
//     if (santriTerpilihUntukNilai.contains(nisn)) {
//       santriTerpilihUntukNilai.remove(nisn);
//     } else {
//       santriTerpilihUntukNilai.add(nisn);
//     }
//   }

//   @override
//   void toggleSantriSelectionForUjian(String nisn) {
//     if (santriTerpilihUntukUjian.contains(nisn)) {
//       santriTerpilihUntukUjian.remove(nisn);
//     } else {
//       santriTerpilihUntukUjian.add(nisn);
//     }
//   }

//   @override
//   void clearNilaiForm() {
//     suratC.clear();
//     ayatHafalC.clear();
//     capaianC.clear();
//     materiC.clear();
//     _keteranganHalaqoh.value = "";
//     santriTerpilihUntukNilai.clear();
//   }
// }