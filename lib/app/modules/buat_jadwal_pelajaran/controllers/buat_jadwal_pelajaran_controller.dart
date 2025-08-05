// lib/app/modules/buat_jadwal_pelajaran/controllers/buat_jadwal_pelajaran_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/controllers/home_controller.dart';

class BuatJadwalPelajaranController extends GetxController {
  
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  final RxMap<String, RxList<Map<String, dynamic>>> jadwalPelajaran = <String, RxList<Map<String, dynamic>>>{}.obs;
  RxString selectedHari = 'Senin'.obs;
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<String> selectedKelasId = Rxn<String>();
  RxBool isLoading = true.obs;
  RxBool isLoadingJadwal = false.obs;
  
  final RxList<Map<String, dynamic>> daftarJam = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarGuruTersedia = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> daftarMapelTersedia = <Map<String, dynamic>>[].obs;

  List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
  String idSekolah = "20404148";

  @override
  void onInit() {
    super.onInit();
    for (var hari in daftarHari) {
      jadwalPelajaran[hari] = <Map<String, dynamic>>[].obs;
    }
    _fetchDaftarKelas();
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

  Future<void> _fetchDaftarJam() async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah)
        .collection('jampelajaran').orderBy('urutan').get();
    daftarJam.value = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'label': "${data['namaKegiatan']} (${data['jampelajaran']})",
        'waktu': data['jampelajaran'],
      };
    }).toList();
  }
  
  // [DISEDERHANAKAN] Sekarang mengambil SEMUA guru yang relevan, tidak lagi per mapel.
  Future<void> _fetchGuruDanMapel() async {
    if (selectedKelasId.value == null) return;
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;

      // Kembali membaca dari 'penugasan' untuk mendapatkan data yang relevan
      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('penugasan').doc(selectedKelasId.value!)
          .collection('matapelajaran').get();

      // Reset list sebelum diisi
      daftarMapelTersedia.clear();
      daftarGuruTersedia.clear();

      // Gunakan Set untuk memastikan daftar mapel tidak duplikat
      final Set<String> uniqueMapelIds = {};

      for(var doc in snapshot.docs) {
        final data = doc.data();

        // Tambahkan data guru ke daftar utama (ini bisa berisi duplikasi mapel)
        daftarGuruTersedia.add({
          'uid': data['idGuru'], 
          'nama': data['guru'], 
          'idMapel': data['idMapel'] // Ini adalah kunci penghubungnya
        });

        // Tambahkan mapel ke daftar unik
        if (!uniqueMapelIds.contains(data['idMapel'])) {
          uniqueMapelIds.add(data['idMapel']);
          daftarMapelTersedia.add({
            'idMapel': data['idMapel'],
            'nama': data['namamatapelajaran']
          });
        }
      }
    } catch(e) { 
      Get.snackbar("Error", "Gagal memuat data guru & mapel: $e"); 
    }
  }

  Future<void> onKelasChanged(String? kelasId) async {
    if (kelasId == null || kelasId.isEmpty) return;
    selectedKelasId.value = kelasId;
    clearJadwal();
    
    isLoadingJadwal.value = true;
    await Future.wait([
      loadJadwalFromFirestore(),
      _fetchDaftarJam(),
      _fetchGuruDanMapel(),
    ]);
    isLoadingJadwal.value = false;
  }
  
  void changeSelectedHari(String? hari) {
    if (hari != null) { selectedHari.value = hari; }
  }

   void tambahPelajaran() {
  jadwalPelajaran[selectedHari.value]?.add({
    'jam': null, 
    'idMapel': null, 
    'namaMapel': null, 
    // [PENTING] Inisialisasi sebagai List kosong
    'listIdGuru': [], 
    'listNamaGuru': [],
  });
}

  void hapusPelajaran(int index) {
    jadwalPelajaran[selectedHari.value]?.removeAt(index);
  }

  // [DISEDERHANAKAN] Logika update untuk single-select guru
  void updatePelajaran(int index, String key, dynamic value) {
    final pelajaran = jadwalPelajaran[selectedHari.value]![index];

    if (key == 'idMapel') {
      final mapel = daftarMapelTersedia.firstWhere((m) => m['idMapel'] == value, orElse: () => {});
      pelajaran['idMapel'] = value;
      pelajaran['namaMapel'] = mapel['nama'];
      // Reset guru jika mapel berubah
      pelajaran['listIdGuru'] = [];
      pelajaran['listNamaGuru'] = [];
    } else if (key == 'idGuru') {
      final guru = daftarGuruTersedia.firstWhere((g) => g['uid'] == value, orElse: () => {});
      // [KUNCI PERUBAHAN] Simpan sebagai List dengan satu item
      pelajaran['listIdGuru'] = [value];
      pelajaran['listNamaGuru'] = [guru['nama']];
    } else {
      pelajaran[key] = value;
    }
    jadwalPelajaran[selectedHari.value]!.refresh();
  }
  
  // Fungsi simpan, load, dan clear tidak perlu perubahan signifikan dari versi terakhir

    Future<void> simpanJadwalKeFirestore() async {
      if (selectedKelasId.value == null || selectedKelasId.value!.isEmpty) {
        Get.snackbar('Perhatian', 'Silakan pilih kelas terlebih dahulu.');
        return;
      }

      isLoading.value = true;
      try {
        // [VALIDASI] Panggil "Penjaga" sebelum menyimpan
        final validationError = await _validateGuruClash();
        if (validationError != null) {
          Get.snackbar('Validasi Gagal', validationError, backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 5));
          isLoading.value = false;
          return;
        }

        Map<String, List<Map<String, dynamic>>> dataToSave = {};
        jadwalPelajaran.forEach((hari, listPelajaran) {
          dataToSave[hari] = listPelajaran.map((p) => Map<String, dynamic>.from(p)).toList();
        });

        final idTahunAjaran = homeC.idTahunAjaran.value!;
        DocumentReference docRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('jadwalkelas').doc(selectedKelasId.value!);

        await docRef.set(dataToSave);
        Get.snackbar('Sukses', 'Jadwal pelajaran berhasil disimpan!');
      } catch (e) {
        Get.snackbar('Error', 'Gagal menyimpan jadwal: ${e.toString()}');
      } finally {
        isLoading.value = false;
      }
  }

  // [BARU] Fungsi "Penjaga" Anti-Bentrok
  //  Future<String?> _validateGuruClash() async {
  //     final idTahunAjaran = homeC.idTahunAjaran.value!;
  //     // Loop melalui setiap hari dalam jadwal yang sedang diedit
  //     for (var hari in jadwalPelajaran.keys) {
  //       for (var slot in jadwalPelajaran[hari]!) {
  //         if ((slot['listIdGuru'] as List).isEmpty || slot['jam'] == null) continue;

  //         for (var idGuru in slot['listIdGuru']) {
  //           // Query untuk mencari bentrok di kelas LAIN
  //           final clashCheck = await firestore
  //               .collection('Sekolah').doc(idSekolah)
  //               .collection('tahunajaran').doc(idTahunAjaran)
  //               .collection('jadwalkelas')
  //               .where(Filter.and(
  //                   Filter(hari, arrayContains: {'idGuru': idGuru, 'jam': slot['jam']}), // Cek di dalam array hari
  //                   Filter(FieldPath.documentId, isNotEqualTo: selectedKelasId.value!) // Pastikan bukan kelas yang sama
  //               )).limit(1).get();

  //           if (clashCheck.docs.isNotEmpty) {
  //             final guru = daftarGuruTersedia.firstWhere((g) => g['uid'] == idGuru, orElse: () => {'nama': 'Guru'});
  //             return "Bentrok: ${guru['nama']} sudah terjadwal di kelas lain pada hari $hari, jam ${slot['jam']}.";
  //           }
  //         }
  //       }
  //     }
  //     return null; // Tidak ada bentrok
  //  }

  // [BARU & DIPERBAIKI] Fungsi "Penjaga" Anti-Bentrok yang lebih andal
  Future<String?> _validateGuruClash() async {
    // Pastikan ID tahun ajaran dan kelas yang dipilih valid sebelum melanjutkan
    if (homeC.idTahunAjaran.value == null || selectedKelasId.value == null) {
      return "Sesi tidak valid atau kelas belum dipilih.";
    }
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    
    // 1. Ambil SEMUA jadwal dari SEMUA kelas di tahun ajaran aktif, 
    //    KECUALI kelas yang sedang diedit saat ini.
    final otherSchedulesSnapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('jadwalkelas')
        .where(FieldPath.documentId, isNotEqualTo: selectedKelasId.value!)
        .get();

    // 2. Buat sebuah "lookup map" untuk pengecekan cepat.
    //    Struktur key-nya: 'idGuru-Hari-Jam' 
    //    Struktur value-nya: 'ID Kelas' tempat bentrok terjadi
    //    Contoh entri: {'uid_guru_budi-Senin-07.00-07.45': 'Kelas-8B'}
    final Map<String, String> guruBookings = {};

    for (var doc in otherSchedulesSnapshot.docs) {
      // Ambil ID kelas lain dari dokumennya
      final idKelasLain = doc.id; 
      final jadwalKelasLain = doc.data();

      // Iterasi setiap hari (Senin, Selasa, dst.) dalam data jadwal kelas lain
      jadwalKelasLain.forEach((hari, listPelajaran) {
        if (listPelajaran is List) {
          for (var pelajaran in listPelajaran) {
            final jam = pelajaran['jam'] as String?;
            // Pastikan 'listIdGuru' dibaca sebagai List<String> untuk keamanan
            final listIdGuru = List<String>.from(pelajaran['listIdGuru'] ?? []);
            
            // Hanya proses jika ada jam dan guru yang ditugaskan
            if (jam != null && listIdGuru.isNotEmpty) {
              for (var idGuru in listIdGuru) {
                // Buat kunci unik untuk setiap pemesanan slot guru
                final key = '$idGuru-$hari-$jam';
                // Simpan ID kelas tempat guru tersebut dijadwalkan
                guruBookings[key] = idKelasLain; 
              }
            }
          }
        }
      });
    }

    // 3. Sekarang, cek setiap slot dalam jadwal yang sedang diedit di UI 
    //    terhadap "lookup map" yang sudah kita buat.
    for (var hari in jadwalPelajaran.keys) {
      for (var slot in jadwalPelajaran[hari]!) {
        final jam = slot['jam'] as String?;
        final listIdGuru = List<String>.from(slot['listIdGuru'] ?? []);

        // Lewati slot yang belum lengkap diisi
        if (jam == null || listIdGuru.isEmpty) continue;

        for (var idGuru in listIdGuru) {
          final key = '$idGuru-$hari-$jam';
          if (guruBookings.containsKey(key)) {
            // BENTROK DITEMUKAN!
            
            // Cari nama guru dan nama kelas untuk pesan error yang lebih informatif
            final guruInfo = daftarGuruTersedia.firstWhere((g) => g['uid'] == idGuru, orElse: () => {'nama': 'Guru Tidak Dikenal'});
            final namaGuruBentrok = guruInfo['nama'];
            
            final idKelasBentrok = guruBookings[key]!;
            final kelasInfo = daftarKelas.firstWhere((k) => k['id'] == idKelasBentrok, orElse: () => {'nama': 'kelas lain'});
            final namaKelasBentrok = kelasInfo['nama'];

            // Kembalikan pesan error yang jelas
            return "Bentrok: ${namaGuruBentrok} sudah terjadwal di '$namaKelasBentrok' pada hari $hari, jam $jam.";
          }
        }
      }
    }

    // Jika loop selesai tanpa menemukan bentrok, kembalikan null
    return null; 
  }
  

//   // ... (loadJadwal & clearJadwal tidak berubah signifikan)

  Future<void> loadJadwalFromFirestore() async {
    if (selectedKelasId.value == null || selectedKelasId.value!.isEmpty) return;

    final idTahunAjaran = homeC.idTahunAjaran.value!;
    try {
      DocumentSnapshot docSnap = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('jadwalkelas')
          .doc(selectedKelasId.value!)
          .get();

      clearJadwal();
      if (docSnap.exists && docSnap.data() != null) {
        final dataJadwal = docSnap.data() as Map<String, dynamic>;
        dataJadwal.forEach((hari, listPelajaranData) {
          if (jadwalPelajaran.containsKey(hari) && listPelajaranData is List) {
            jadwalPelajaran[hari]!.value = List<Map<String, dynamic>>.from(
              listPelajaranData.map((item) => Map<String, dynamic>.from(item as Map))
            );
          }
        });
      }
    } catch (e) { Get.snackbar('Error', 'Gagal memuat jadwal: ${e.toString()}'); }
  }

  void clearJadwal() {
    for (var hari in daftarHari) {
      jadwalPelajaran[hari]?.clear();
    }
  }
}