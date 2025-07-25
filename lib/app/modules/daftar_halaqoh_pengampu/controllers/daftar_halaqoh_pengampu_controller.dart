// lib/app/modules/daftar_halaqoh_pengampu/controllers/daftar_halaqoh_pengampu_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../modules/home/controllers/home_controller.dart';

class DaftarHalaqohPengampuController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  final RxBool isLoadingHalaqoh = true.obs;
  final RxBool isLoadingSantri = false.obs;
  final RxBool isDialogLoading = false.obs;
  final RxBool isSavingNilai = false.obs;
  
  final RxList<Map<String, dynamic>> daftarHalaqoh = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> halaqohTerpilih = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> daftarSantri = <Map<String, dynamic>>[].obs;

  final TextEditingController lokasiC = TextEditingController();
  final TextEditingController suratC = TextEditingController();
  final TextEditingController ayatHafalC = TextEditingController();
  final TextEditingController capaianC = TextEditingController();
  final TextEditingController halAyatC = TextEditingController();
  final TextEditingController materiC = TextEditingController();
  final TextEditingController nilaiC = TextEditingController();
  final TextEditingController capaianUjianC = TextEditingController();
  final TextEditingController levelUjianC = TextEditingController();
  final RxString keteranganHalaqoh = "".obs;
  final RxList<String> santriTerpilihUntukNilai = <String>[].obs;
  final RxList<String> santriTerpilihUntukUjian = <String>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // lokasiC = TextEditingController(); suratC = TextEditingController(); ayatHafalC = TextEditingController();
    // capaianC = TextEditingController(); halAyatC = TextEditingController(); materiC = TextEditingController();
    // nilaiC = TextEditingController(); capaianUjianC = TextEditingController(); levelUjianC = TextEditingController();
    fetchHalaqohGroupsFromHomeController();
  }

  @override
  void onClose() {
    lokasiC.dispose(); suratC.dispose(); ayatHafalC.dispose(); capaianC.dispose(); halAyatC.dispose();
    materiC.dispose(); nilaiC.dispose(); capaianUjianC.dispose(); levelUjianC.dispose();
    super.onClose();
  }

  void fetchHalaqohGroupsFromHomeController() {
    isLoadingHalaqoh.value = true;
    final kelompokDariHome = homeC.kelompokMengajiDiajar;
    if (kelompokDariHome.isNotEmpty) {
      daftarHalaqoh.assignAll(kelompokDariHome);
      gantiHalaqohTerpilih(daftarHalaqoh.first);
    }
    isLoadingHalaqoh.value = false;
  }
  
  void gantiHalaqohTerpilih(Map<String, dynamic> kelompokBaru) {
    if (halaqohTerpilih.value?['fase'] == kelompokBaru['fase'] && halaqohTerpilih.value?['tempatmengaji'] == kelompokBaru['tempatmengaji']) return;
    halaqohTerpilih.value = kelompokBaru;
    fetchDaftarSantri();
  }

  Future<void> fetchDaftarSantri() async {
    final kelompok = halaqohTerpilih.value;
    if (kelompok == null) return;
    isLoadingSantri.value = true;
    try {
      daftarSantri.clear();
      final santriSnapshot = await _getDaftarSiswaCollectionRef().get();
      if (santriSnapshot.docs.isNotEmpty) {
        daftarSantri.assignAll(santriSnapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id;
          data['capaian_untuk_view'] = data['capaian_terakhir'] ?? '-';
          return data;
        }).toList());
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar santri: $e");
    } finally {
      isLoadingSantri.value = false;
    }
  }

  CollectionReference<Map<String, dynamic>> _getDaftarSiswaCollectionRef() {
    final kelompok = halaqohTerpilih.value!;
    return firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelompokmengaji').doc(kelompok['fase'])
        .collection('pengampu').doc(kelompok['idpengampu'])
        .collection('tempat').doc(kelompok['tempatmengaji'])
        .collection('semester').doc(homeC.semesterAktifId.value)
        .collection('daftarsiswa');
  }

  void toggleSantriSelection(String nisn) {
    if (santriTerpilihUntukNilai.contains(nisn)) santriTerpilihUntukNilai.remove(nisn);
    else santriTerpilihUntukNilai.add(nisn);
  }
  
  void toggleSantriSelectionForUjian(String nisn) {
    if (santriTerpilihUntukUjian.contains(nisn)) santriTerpilihUntukUjian.remove(nisn);
    else santriTerpilihUntukUjian.add(nisn);
  }
  
  void clearNilaiForm() {
    suratC.clear(); ayatHafalC.clear(); capaianC.clear(); halAyatC.clear();
    materiC.clear(); nilaiC.clear();
    keteranganHalaqoh.value = "";
    santriTerpilihUntukNilai.clear();
  }
  
  String _getGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    return 'C';
  }

  Future<void> simpanNilaiMassal() async {
    if (suratC.text.trim().isEmpty || ayatHafalC.text.trim().isEmpty || capaianC.text.trim().isEmpty || materiC.text.trim().isEmpty || nilaiC.text.trim().isEmpty || santriTerpilihUntukNilai.isEmpty) {
      Get.snackbar("Peringatan", "Isi semua field nilai dan pilih minimal satu santri.");
      return;
    }

    isSavingNilai.value = true;
    try {
      final now = DateTime.now();
      final docIdNilaiHarian = DateFormat('yyyy-MM-dd').format(now);
      int nilaiNumerik = int.tryParse(nilaiC.text.trim()) ?? 0;
      if (nilaiNumerik > 98) nilaiNumerik = 98;
      String grade = _getGrade(nilaiNumerik);
      
      final batch = firestore.batch();
      final refDaftarSiswa = _getDaftarSiswaCollectionRef();
      final kelompok = halaqohTerpilih.value!;
      
      final Map<String, dynamic> dataNilaiTemplate = {
        "tanggalinput": now.toIso8601String(), "emailpenginput": auth.currentUser!.email!,
        "idpengampu": kelompok['idpengampu'], "namapengampu": kelompok['namapengampu'],
        "tempatmengaji": kelompok['tempatmengaji'], "fase": kelompok['fase'],
        "hafalansurat": suratC.text.trim(), "ayathafalansurat": ayatHafalC.text.trim(),
        "capaian": capaianC.text.trim(), "ummihalatauayat": halAyatC.text.trim(),
        "materi": materiC.text.trim(), "nilai": nilaiNumerik, "nilaihuruf": grade,
        "keteranganpengampu": keteranganHalaqoh.value, "uidnilai": docIdNilaiHarian,
        "semester": homeC.semesterAktifId.value,
      };

      for (String nisn in santriTerpilihUntukNilai) {
        final santriData = daftarSantri.firstWhere((s) => s['id'] == nisn);
        final docNilaiRef = refDaftarSiswa.doc(nisn).collection('nilai').doc(docIdNilaiHarian);
        final dataFinal = { ...dataNilaiTemplate, "idsiswa": nisn, "namasiswa": santriData['namasiswa'], "kelas": santriData['kelas'], "tahunajaran": santriData['tahunajaran']};
        batch.set(docNilaiRef, dataFinal, SetOptions(merge: true));
        batch.update(refDaftarSiswa.doc(nisn), {'capaian_terakhir': capaianC.text.trim(), 'tanggal_update_terakhir': now});
      }
      
      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "Nilai berhasil disimpan untuk ${santriTerpilihUntukNilai.length} santri.");
      clearNilaiForm();
      fetchDaftarSantri();
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan nilai: ${e.toString()}");
    } finally {
      isSavingNilai.value = false;
    }
  }

  Future<void> tandaiSiapUjianMassal() async {
    if (levelUjianC.text.trim().isEmpty || capaianUjianC.text.trim().isEmpty || santriTerpilihUntukUjian.isEmpty) {
      Get.snackbar("Peringatan", "Isi semua field dan pilih minimal satu santri."); return;
    }
    isDialogLoading.value = true;
    try {
      final batch = firestore.batch();
      final refDaftarSiswa = _getDaftarSiswaCollectionRef();
      final now = DateTime.now();
      final String uidPendaftar = auth.currentUser!.uid;

      for (String nisn in santriTerpilihUntukUjian) {
        final docSiswaIndukRef = refDaftarSiswa.doc(nisn);
        final docUjianBaruRef = docSiswaIndukRef.collection('ujian').doc();
        batch.update(docSiswaIndukRef, {'status_ujian': 'siap_ujian'});
        batch.set(docUjianBaruRef, {
          'status_ujian': 'siap_ujian', 'level_ujian': levelUjianC.text.trim(),
          'capaian_saat_didaftarkan': capaianUjianC.text.trim(), 'tanggal_didaftarkan': now,
          'didaftarkan_oleh': uidPendaftar, 'semester': homeC.semesterAktifId.value,
          'tanggal_ujian': null, 'diuji_oleh': null, 'catatan_penguji': null,
        });
      }
      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "${santriTerpilihUntukUjian.length} santri telah ditandai siap ujian.");
      santriTerpilihUntukUjian.clear(); capaianUjianC.clear(); levelUjianC.clear();
      fetchDaftarSantri();
    } catch (e) {
      Get.snackbar("Error", "Gagal menandai siswa: $e");
    } finally { isDialogLoading.value = false; }
  }

  // Future<void> updateLokasiHalaqoh() async {
  //   final lokasiBaru = lokasiC.text.trim();
  //   if (lokasiBaru.isEmpty) return;
  //   isDialogLoading.value = true;
  //   try {
  //     final kelompok = halaqohTerpilih.value!;
  //     final tempatRef = firestore.collection('Sekolah').doc(homeC.idSekolah)
  //       .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
  //       .collection('kelompokmengaji').doc(kelompok['fase'])
  //       .collection('pengampu').doc(kelompok['idpengampu'])
  //       .collection('tempat').doc(kelompok['tempatmengaji']);
  //     await tempatRef.update({'lokasi_terakhir': lokasiBaru});
      
  //     halaqohTerpilih.update((val) { val?['lokasi_terakhir'] = lokasiBaru; });
  //     Get.back();
  //     Get.snackbar("Berhasil", "Lokasi telah diperbarui.");
  //   } catch (e) {
  //     Get.snackbar("Error", "Gagal menyimpan lokasi: $e");
  //   } finally {
  //     isDialogLoading.value = false;
  //   }
  // }

  Future<void> updateLokasiHalaqoh() async {
    final lokasiBaru = lokasiC.text.trim();
    if (lokasiBaru.isEmpty) return;

    final kelompok = halaqohTerpilih.value!;
    final lokasiLama = kelompok['tempatmengaji'];

    if (lokasiBaru == lokasiLama) {
      Get.back();
      return;
    }

    isDialogLoading.value = true;
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semesterAktif = homeC.semesterAktifId.value;
      final fase = kelompok['fase'];
      final idPengampu = kelompok['idpengampu'];

      // 1. Referensi ke lokasi lama dan baru
      final pengampuRef = firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(fase)
          .collection('pengampu').doc(idPengampu);
      
      final tempatLamaRef = pengampuRef.collection('tempat').doc(lokasiLama);
      final tempatBaruRef = pengampuRef.collection('tempat').doc(lokasiBaru);

      // 2. Ambil semua data dari lokasi lama
      final tempatDataSnapshot = await tempatLamaRef.get();
      if (!tempatDataSnapshot.exists) throw Exception("Lokasi lama tidak ditemukan.");
      final tempatData = tempatDataSnapshot.data()!..['tempatmengaji'] = lokasiBaru;

      final siswaSnapshot = await tempatLamaRef.collection('semester').doc(semesterAktif).collection('daftarsiswa').get();

      WriteBatch batch = firestore.batch();

      // 3. Tulis ulang semua data ke lokasi baru
      batch.set(tempatBaruRef, tempatData);
      for (var siswaDoc in siswaSnapshot.docs) {
        final siswaData = siswaDoc.data()..['tempatmengaji'] = lokasiBaru;
        batch.set(tempatBaruRef.collection('semester').doc(semesterAktif).collection('daftarsiswa').doc(siswaDoc.id), siswaData);
        
        // 4. Perbarui "buku agenda" di setiap siswa
        final refDiSiswaUtama = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('siswa').doc(siswaDoc.id)
            .collection('tahunajarankelompok').doc(idTahunAjaran)
            .collection('semester').doc(semesterAktif).collection('kelompokmengaji').doc(fase);
        batch.update(refDiSiswaUtama, {'tempatmengaji': lokasiBaru});
      }

      // 5. Hapus semua dokumen dari lokasi lama (setelah dipindahkan)
      for (var siswaDoc in siswaSnapshot.docs) {
        batch.delete(siswaDoc.reference);
      }
      batch.delete(tempatLamaRef);
      
      // 6. Perbarui "buku agenda" di dokumen pegawai
      final refDiPegawai = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('pegawai').doc(idPengampu)
          .collection('tahunajarankelompok').doc(idTahunAjaran)
          .collection('semester').doc(semesterAktif).collection('kelompokmengaji').doc(fase);
      batch.update(refDiPegawai, {'tempatmengaji': lokasiBaru});

      await batch.commit();
      
      Get.back(); // Tutup loading
      Get.back(); // Tutup dialog edit
      Get.snackbar("Berhasil", "Lokasi telah dipindahkan ke $lokasiBaru.");
      
      // Muat ulang semuanya dengan data yang sudah sinkron
      homeC.kelompokMengajiDiajar.clear(); // Hapus cache di home
      await homeC.fetchUserRoleAndTugas(); // Minta home untuk baca ulang agenda
      fetchHalaqohGroupsFromHomeController(); // Refresh halaman ini
      
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Gagal memindahkan lokasi: ${e.toString()}");
    } finally {
      isDialogLoading.value = false;
    }
  }
}

// // lib/app/modules/daftar_halaqoh_pengampu/controllers/daftar_halaqoh_pengampu_controller.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../../modules/home/controllers/home_controller.dart';
// import 'package:flutter/material.dart';

// class DaftarHalaqohPengampuController extends GetxController {

//   final FirebaseAuth auth = FirebaseAuth.instance;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final HomeController homeC = Get.find<HomeController>();

//   final RxBool isLoadingHalaqoh = true.obs;
//   final RxBool isLoadingSantri = false.obs;

//   final Rxn<String> tempatTerpilih = Rxn<String>();
//   final RxList<String> daftarHalaqoh = <String>[].obs;
//   final Rxn<String> halaqohTerpilih = Rxn<String>();
//   final RxList<Map<String, dynamic>> daftarSantri = <Map<String, dynamic>>[].obs;


//   final RxBool isSavingNilai = false.obs;

//   final TextEditingController lokasiC = TextEditingController();

//   // Controller untuk form template nilai
//   final TextEditingController suratC = TextEditingController();
//   final TextEditingController ayatHafalC = TextEditingController();
//   final TextEditingController capaianC = TextEditingController();
//   final TextEditingController halAyatC = TextEditingController();
//   final TextEditingController materiC = TextEditingController();
//   final TextEditingController nilaiC = TextEditingController();
//   final RxString keteranganHalaqoh = "".obs;

//   // List reaktif untuk menyimpan NISN santri yang dipilih (dicentang)
//   final RxList<String> santriTerpilihUntukNilai = <String>[].obs;
//   //========================================================================

//   //========================================================================
//   // --- STATE BARU UNTUK FITUR TANDAI SIAP UJIAN ---
//   //========================================================================
//   final RxBool isDialogLoading = false.obs; // Untuk loading dialog
//   final TextEditingController capaianUjianC = TextEditingController();
//   final TextEditingController levelUjianC = TextEditingController();
//   final RxList<String> santriTerpilihUntukUjian = <String>[].obs;
//   //========================================================================

//   // @override
//   // void onInit() {
//   //   super.onInit();
//   //   fetchHalaqohGroups();
//   //   fetchHalaqohGroupsFromHomeController();
//   // }

//   @override
//   void onInit() {
//     super.onInit();
//     // lokasiC = TextEditingController(); suratC = TextEditingController(); ayatHafalC = TextEditingController();
//     // capaianC = TextEditingController(); halAyatC = TextEditingController(); materiC = TextEditingController();
//     // nilaiC = TextEditingController(); capaianUjianC = TextEditingController(); levelUjianC = TextEditingController();
//     fetchHalaqohGroupsFromHomeController();
//   }

//   @override
//   void onClose() {
//     lokasiC.dispose(); suratC.dispose(); ayatHafalC.dispose(); capaianC.dispose(); halAyatC.dispose();
//     materiC.dispose(); nilaiC.dispose(); capaianUjianC.dispose(); levelUjianC.dispose();
//     super.onClose();
//   }

//   void fetchHalaqohGroupsFromHomeController() {
//     isLoadingHalaqoh.value = true;
//     final kelompokDariHome = homeC.kelompokMengajiDiajar;
//     if (kelompokDariHome.isNotEmpty) {
//       daftarHalaqoh.assignAll(kelompokDariHome as Iterable<String>);
//       gantiHalaqohTerpilih(daftarHalaqoh.first as Map<String, dynamic>);
//     }
//     isLoadingHalaqoh.value = false;
//   }

//   /// 1. Mengambil daftar kelompok (sudah 'sadar semester' karena memanggil fungsi baru di HomeController).
//   Future<void> fetchHalaqohGroups() async {
//     try {
//       isLoadingHalaqoh.value = true;
//       final kelompok = await homeC.getDataKelompok();
//       daftarHalaqoh.assignAll(kelompok);
//       if (daftarHalaqoh.isNotEmpty) {
//         gantiHalaqohTerpilih(daftarHalaqoh.first as Map<String, dynamic>);
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat kelompok halaqoh: $e");
//     } finally {
//       isLoadingHalaqoh.value = false;
//     }
//   }
  
//   /// 2. Aksi saat pengguna memilih kelompok (tidak ada perubahan).
//   // void gantiHalaqohTerpilih(String namaHalaqoh) {
//   //   if (halaqohTerpilih.value == namaHalaqoh && !isLoadingSantri.value) return;
//   //   halaqohTerpilih.value = namaHalaqoh;
//   //   tempatTerpilih.value = null; 
//   //   fetchDaftarSantri(namaHalaqoh);
//   // }

//   void gantiHalaqohTerpilih(Map<String, dynamic> kelompokBaru) {
//   // Bandingkan fase baru dengan halaqohTerpilih saat ini
//   if (halaqohTerpilih.value == kelompokBaru['fase'].toString()) return;

//   // Update halaqohTerpilih dengan fase baru
//   halaqohTerpilih.value = kelompokBaru['fase'].toString();

//   // Panggil fungsi fetchDaftarSantri
//   fetchDaftarSantri();
// }

// // Fungsi dummy untuk fetchDaftarSantri
// // void fetchDaftarSantri() {
// //   print('Memuat daftar santri...');
// // }

//   // Future<void> fetchDaftarSantri(String namaHalaqoh) async {
//   //   try {
//   //     isLoadingSantri.value = true;
//   //     daftarSantri.clear();

//   //     String idTahunAjaran = homeC.idTahunAjaran.value!;
//   //     String semesterAktif = homeC.semesterAktifId.value;
//   //     String idSekolah = homeC.idSekolah;
//   //     String idUser = auth.currentUser!.uid;

//   //     final pegawaiDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
//   //     if (!pegawaiDoc.exists) throw Exception("Data pengampu tidak ditemukan.");
//   //     String namaPengampu = pegawaiDoc.data()!['alias'];

//   //     // Langkah A: Dapatkan dokumen tempat default
//   //     final tempatSnapshot = await firestore.collection('Sekolah').doc(idSekolah)
//   //         .collection('tahunajaran').doc(idTahunAjaran)
//   //         .collection('kelompokmengaji').doc(namaHalaqoh)
//   //         .collection('pengampu').doc(namaPengampu)
//   //         .collection('tempat').limit(1).get();

//   //     if (tempatSnapshot.docs.isEmpty) {
//   //       tempatTerpilih.value = null;
//   //       daftarSantri.clear();
//   //       return;
//   //     }
      
//   //     final tempatDoc = tempatSnapshot.docs.first;
      
//   //     // =================================================================
//   //     // Catatan saya
//   //     // =================================================================
//   //     // Kode untuk mengambil LOKASI TERAKHIR (default sekarang)
//   //     // Ia akan mencari field 'lokasi_terakhir', jika tidak ada, ia akan menggunakan nama dokumen (lokasi default)
//   //     tempatTerpilih.value = tempatDoc.data()['lokasi_terakhir'] ?? tempatDoc.id;
      
//   //     /*
//   //      Kode untuk mengambil LOKASI LAMA (default dari struktur)
//   //      Jika sekolah ingin kembali ke default, uncomment ini dan comment kode di atas.
//   //     tempatTerpilih.value = tempatDoc.id;
//   //     */
//   //     // =================================================================

//   //     final santriSnapshot = await tempatDoc.reference
//   //         .collection('semester').doc(semesterAktif)
//   //         .collection('daftarsiswa').get();

//   //     if (santriSnapshot.docs.isNotEmpty) {
//   //       List<Future<Map<String, dynamic>>> futures = santriSnapshot.docs.map((doc) async {
//   //         var data = doc.data();
//   //         data['id'] = doc.id;
//   //         data['capaian_untuk_view'] = data['capaian_terakhir'] ?? '-';
//   //         return data;
//   //       }).toList();
//   //       final listSantriLengkap = await Future.wait(futures);
//   //       daftarSantri.assignAll(listSantriLengkap);
//   //     }
//   //   } catch (e) {
//   //     Get.snackbar("Error", "Gagal memuat daftar santri: $e");
//   //     daftarSantri.clear();
//   //     tempatTerpilih.value = null;
//   //   } finally {
//   //     isLoadingSantri.value = false;
//   //   }
//   // }

//   Future<void> fetchDaftarSantri() async {
//     final kelompok = halaqohTerpilih.value;
//     if (kelompok == null) return;
//     isLoadingSantri.value = true;
//     try {
//       daftarSantri.clear();
//       final santriSnapshot = await _getDaftarSiswaCollectionRef().get();
//       if (santriSnapshot.docs.isNotEmpty) {
//         daftarSantri.assignAll(santriSnapshot.docs.map((doc) {
//           var data = doc.data();
//           data['id'] = doc.id;
//           data['capaian_untuk_view'] = data['capaian_terakhir'] ?? '-';
//           return data;
//         }).toList());
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat daftar santri: $e");
//     } finally {
//       isLoadingSantri.value = false;
//     }
//   }

//   CollectionReference<Map<String, dynamic>> _getDaftarSiswaCollectionRef() {
//   final kelompok = halaqohTerpilih.value;

//   if (kelompok == null) {
//     throw Exception("Halaqoh belum dipilih.");
//   }

//   return FirebaseFirestore.instance
//       .collection('Sekolah').doc(homeC.idSekolah)
//       .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
//       .collection('kelompokmengaji').doc(kelompok['fase'].toString())
//       .collection('pengampu').doc(kelompok['idpengampu'].toString())
//       .collection('tempat').doc(kelompok['tempatmengaji'].toString())
//       .collection('semester').doc(homeC.semesterAktifId.value!)
//       .collection('daftarsiswa');
// }


//   Future<void> updateLokasiHalaqoh() async {
//     final lokasiBaru = lokasiC.text.trim();
//     if (lokasiBaru.isEmpty) {
//       Get.snackbar("Peringatan", "Nama lokasi tidak boleh kosong.");
//       return;
//     }

//     isDialogLoading.value = true;
//     try {
//       // Dapatkan referensi ke dokumen 'tempat'
//       String idTahunAjaran = homeC.idTahunAjaran.value!;
//       String idSekolah = homeC.idSekolah;
//       String idUser = auth.currentUser!.uid;
//       final pegawaiDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
//       String namaPengampu = pegawaiDoc.data()!['alias'];
//       final tempatSnapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelompokmengaji').doc(halaqohTerpilih.value!).collection('pengampu').doc(namaPengampu).collection('tempat').limit(1).get();

//       if (tempatSnapshot.docs.isEmpty) throw Exception("Dokumen tempat tidak ditemukan.");
      
//       final tempatRef = tempatSnapshot.docs.first.reference;

//       // Update field 'lokasi_terakhir' di dokumen tersebut
//       await tempatRef.update({'lokasi_terakhir': lokasiBaru});

//       // Update state di UI secara lokal
//       tempatTerpilih.value = lokasiBaru;

//       Get.back(); // Tutup dialog
//       Get.snackbar("Berhasil", "Lokasi telah diperbarui menjadi $lokasiBaru.");

//     } catch (e) {
//       Get.snackbar("Error", "Gagal menyimpan lokasi: $e");
//     } finally {
//       isDialogLoading.value = false;
//     }
//   }

//   //========================================================================
//   // --- LOGIKA BARU UNTUK FITUR INPUT NILAI MASSAL ---
//   //========================================================================

//   /// Mengelola checkbox santri. Dipanggil dari UI.
//   void toggleSantriSelection(String nisn) {
//     if (santriTerpilihUntukNilai.contains(nisn)) {
//       santriTerpilihUntukNilai.remove(nisn);
//     } else {
//       santriTerpilihUntukNilai.add(nisn);
//     }
//   }

//   /// Membersihkan form template nilai.
//   void clearNilaiForm() {
//     suratC.clear();
//     ayatHafalC.clear();
//     capaianC.clear();
//     halAyatC.clear();
//     materiC.clear();
//     nilaiC.clear();
//     keteranganHalaqoh.value = "";
//     santriTerpilihUntukNilai.clear();
//   }


//   /// [FUNGSI INTI BARU] Menyimpan nilai dari template untuk semua santri yang terpilih.
//   Future<void> simpanNilaiMassal() async {
//     // 1. Validasi Input
//     if (suratC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Surat hafalan wajib diisi."); return; }
//     if (ayatHafalC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Ayat hafalan wajib diisi."); return; }
//     if (capaianC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Capaian wajib diisi."); return; }
//     if (materiC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Materi UMMI/AlQuran wajib diisi."); return; }
//     if (nilaiC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Nilai wajib diisi."); return; }
//     if (santriTerpilihUntukNilai.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu santri."); return; }

//     isSavingNilai.value = true;
//     try {
//       // 2. Dapatkan data global (tetap sama)
//       final idTahunAjaran = homeC.idTahunAjaran.value!;
//       final semesterAktif = homeC.semesterAktifId.value;
//       final idSekolah = homeC.idSekolah;
//       final now = DateTime.now();
//       final docIdNilaiHarian = DateFormat('yyyy-MM-dd').format(now);

//       int nilaiNumerik = int.tryParse(nilaiC.text.trim()) ?? 0;
//       if (nilaiNumerik > 98) nilaiNumerik = 98;
//       String grade = _getGrade(nilaiNumerik);
      
//       final batch = firestore.batch();
      
//       final Map<String, dynamic> dataNilaiTemplate = {
//         "tanggalinput": now.toIso8601String(),
//         "emailpenginput": auth.currentUser!.email!,
//         "idpengampu": auth.currentUser!.uid,
//         "hafalansurat": suratC.text.trim(),
//         "ayathafalansurat": ayatHafalC.text.trim(),
//         "capaian": capaianC.text.trim(),
//         "ummihalatauayat": halAyatC.text.trim(),
//         "materi": materiC.text.trim(),
//         "nilai": nilaiNumerik,
//         "nilaihuruf": grade,
//         "keteranganpengampu": keteranganHalaqoh.value,
//         "uidnilai": docIdNilaiHarian,
//         "semester": semesterAktif,
//       };

//       // 3. Looping untuk setiap santri yang terpilih
//       for (String nisn in santriTerpilihUntukNilai) {
//         // Cari data lengkap santri dari list yang sudah ada
//         final santriData = daftarSantri.firstWhere((s) => s['id'] == nisn);

//         // Path ke dokumen nilai siswa
//         final docNilaiRef = firestore
//           .collection('Sekolah').doc(idSekolah)
//           .collection('tahunajaran').doc(idTahunAjaran)
//           .collection('kelompokmengaji').doc(santriData['fase'])
//           .collection('pengampu').doc(santriData['namapengampu'])
//           .collection('tempat').doc(santriData['tempatmengaji'])
//           .collection('semester').doc(semesterAktif)
//           .collection('daftarsiswa').doc(nisn)
//           .collection('nilai').doc(docIdNilaiHarian);

//           final docSiswaIndukRef = firestore
//           .collection('Sekolah').doc(idSekolah)
//           .collection('tahunajaran').doc(idTahunAjaran)
//           .collection('kelompokmengaji').doc(santriData['fase'])
//           .collection('pengampu').doc(santriData['namapengampu'])
//           .collection('tempat').doc(santriData['tempatmengaji'])
//           .collection('semester').doc(semesterAktif)
//           .collection('daftarsiswa').doc(nisn);
        
//         // Gabungkan template dengan data spesifik santri
//         final dataFinal = {
//           ...dataNilaiTemplate,
//           "fase": santriData['fase'],
//           "idsiswa": nisn,
//           "kelas": santriData['kelas'],
//           "kelompokmengaji": santriData['kelompokmengaji'],
//           "namapengampu": santriData['namapengampu'],
//           "namasiswa": santriData['namasiswa'],
//           "tahunajaran": santriData['tahunajaran'],
//           "tempatmengaji": santriData['tempatmengaji'],
//         };
        
//         // Tambahkan operasi set (atau update jika perlu) ke dalam batch
//         batch.set(docNilaiRef, dataFinal, SetOptions(merge: true));

//         batch.update(docSiswaIndukRef, {
//           'capaian_terakhir': capaianC.text.trim(),
//           'tanggal_update_terakhir': now,
//         });
//       }
      

//       // 4. Commit semua operasi sekaligus
//       await batch.commit();

//       Get.back(); // Tutup bottom sheet
//       Get.snackbar(
//         "Berhasil", 
//         "Nilai berhasil disimpan untuk ${santriTerpilihUntukNilai.length} santri.",
//         backgroundColor: Colors.green, colorText: Colors.white
//       );
//       clearNilaiForm(); // Bersihkan form setelah berhasil

//       fetchDaftarSantri(halaqohTerpilih.value!);

//     } catch (e) {
//       Get.snackbar("Error", "Gagal menyimpan nilai: ${e.toString()}");
//     } finally {
//       isSavingNilai.value = false;
//     }
//   }

//   //========================================================================
//   // --- FUNGSI BARU UNTUK FITUR TANDAI SIAP UJIAN ---
//   //========================================================================

//   void toggleSantriSelectionForUjian(String nisn) {
//     if (santriTerpilihUntukUjian.contains(nisn)) {
//       santriTerpilihUntukUjian.remove(nisn);
//     } else {
//       santriTerpilihUntukUjian.add(nisn);
//     }
//   }

//   Future<void> tandaiSiapUjianMassal() async {
//     if (levelUjianC.text.trim().isEmpty || capaianUjianC.text.trim().isEmpty || santriTerpilihUntukUjian.isEmpty) {
//       Get.snackbar("Peringatan", "Isi semua field dan pilih minimal satu santri."); return;
//     }
//     isDialogLoading.value = true;
//     try {
//       final batch = firestore.batch();
//       final refDaftarSiswa = await _getDaftarSiswaCollectionRef();
//       final now = DateTime.now();
//       final String uidPendaftar = auth.currentUser!.uid;

//       for (String nisn in santriTerpilihUntukUjian) {
//         final docSiswaIndukRef = refDaftarSiswa.doc(nisn);
//         final docUjianBaruRef = docSiswaIndukRef.collection('ujian').doc();

//         batch.update(docSiswaIndukRef, {'status_ujian': 'siap_ujian'});
//         batch.set(docUjianBaruRef, {
//           'status_ujian': 'siap_ujian',
//           'level_ujian': levelUjianC.text.trim(),
//           'capaian_saat_didaftarkan': capaianUjianC.text.trim(),
//           'tanggal_didaftarkan': now,
//           'didaftarkan_oleh': uidPendaftar,
//           'semester': homeC.semesterAktifId.value,
//           'tanggal_ujian': null, 'diuji_oleh': null, 'catatan_penguji': null,
//         });
//       }

//       await batch.commit();
//       Get.back(); // Tutup dialog
//       Get.snackbar("Berhasil", "${santriTerpilihUntukUjian.length} santri telah ditandai siap ujian.");
//       santriTerpilihUntukUjian.clear();
//       capaianUjianC.clear();
//       levelUjianC.clear();
//       // Muat ulang data untuk refresh status di UI
//       fetchDaftarSantri(halaqohTerpilih.value!);
//     } catch (e) {
//       Get.snackbar("Error", "Gagal menandai siswa: $e");
//     } finally {
//       isDialogLoading.value = false;
//     }
//   }

//   /// Helper untuk mendapatkan path koleksi daftarsiswa
//   // Future<CollectionReference<Map<String, dynamic>>> _getDaftarSiswaCollectionRef() async {
//   //   final idTahunAjaran = homeC.idTahunAjaran.value!;
//   //   final semesterAktif = homeC.semesterAktifId.value;
//   //   final idSekolah = homeC.idSekolah;
//   //   final idUser = auth.currentUser!.uid;
//   //   final pegawaiDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
//   //   final namaPengampu = pegawaiDoc.data()!['alias'];
    
//   //   return firestore
//   //       .collection('Sekolah').doc(idSekolah)
//   //       .collection('tahunajaran').doc(idTahunAjaran)
//   //       .collection('kelompokmengaji').doc(halaqohTerpilih.value!)
//   //       .collection('pengampu').doc(namaPengampu)
//   //       .collection('tempat').doc(tempatTerpilih.value!)
//   //       .collection('semester').doc(semesterAktif)
//   //       .collection('daftarsiswa');
//   // }


//   String _getGrade(int score) {
//     if (score >= 90) return 'A'; // A/A+ disederhanakan menjadi A
//     if (score >= 85) return 'B+';
//     if (score >= 80) return 'B';
//     if (score >= 75) return 'B-';
//     if (score >= 70) return 'C+';
//     if (score >= 65) return 'C';
//     if (score >= 60) return 'C-';
//     return 'D';
//   }
// }