// lib/app/modules/daftar_kelas/controllers/daftar_kelas_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';


// Kita butuh akses ke HomeController untuk mengambil data yang sudah ada
import '../../../modules/home/controllers/home_controller.dart'; 


class DaftarKelasController extends GetxController with GetSingleTickerProviderStateMixin {
  // Hapus 'var data = Get.arguments;' karena sudah tidak digunakan lagi.

  // --- DEPENDENSI ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>(); // Akses HomeController

  // --- STATE UNTUK TAB HALAQOH ---
  final RxBool isLoadingHalaqoh = false.obs;
  final RxList<Map<String, dynamic>> daftarSiswaHalaqoh = <Map<String, dynamic>>[].obs;
  final RxString searchQueryHalaqoh = ''.obs;
  
  // State untuk memantau proses loading data
  final RxBool isLoadingKelas = true.obs; 
  final RxBool isLoadingMapel = false.obs;

   // --- TAMBAHAN BARU: State & Controller untuk TABS ---
  late TabController tabController;
  final RxInt selectedTabIndex = 0.obs;

  // Daftar kelas yang diajar oleh guru (diambil dari HomeController)
  final RxList<String> daftarKelasDiajar = <String>[].obs;
  
  // Menyimpan nama kelas yang sedang dipilih oleh pengguna
  final Rxn<String> kelasTerpilih = Rxn<String>();

  // Daftar mata pelajaran untuk kelas yang dipilih
  final RxList<Map<String, dynamic>> daftarMapel = <Map<String, dynamic>>[].obs;

  // --- STATE BARU UNTUK FITUR ABSENSI ---
  //========================================================================
  final RxBool isSavingAbsensi = false.obs;
  // Key: NISN Siswa, Value: Status Absensi ('Sakit', 'Izin', 'Alfa')
  final RxMap<String, String> absensiHariIni = <String, String>{}.obs;
  // Menyimpan daftar siswa dari kelas yang terpilih
  final RxList<Map<String, dynamic>> daftarSiswaDiKelas = <Map<String, dynamic>>[].obs;
  //========================================================================

  // --- STATE BARU UNTUK HAK AKSES & PENCARIAN ---
  //========================================================================
  final RxBool isWaliKelas = false.obs; // Untuk menentukan apakah user adalah wali kelas
  final RxString searchQuery = ''.obs;   // Untuk menyimpan query pencarian di dialog absensi
  //========================================================================

  // --- STATE MAPEL BARU (LEBIH LENGKAP) ---
  //========================================================================
  final RxBool isLoadingMapelDanJadwal = false.obs; // Menggabungkan loading

  // final RxBool hasBeenInitialized = false.obs;
  
  // Daftar untuk bagian ATAS (yang diajar guru ini & bisa diklik)
  final RxList<Map<String, dynamic>> daftarMapelDiajar = <Map<String, dynamic>>[].obs;

  // Daftar untuk bagian BAWAH (semua mapel & read-only)
  final RxList<Map<String, dynamic>> semuaMapelDiKelas = <Map<String, dynamic>>[].obs;

   final RxList<String> displayKelasList = <String>[].obs;
  // List untuk menyimpan data asli (cache)
    List<String> _taughtClasses = [];
    List<String> _allSchoolClasses = [];

  bool get isSuperUser => homeC.userRole.value == 'Kepala Sekolah' || homeC.userRole.value == 'Admin';
  bool get isTeacher => homeC.userRole.value == 'Guru Kelas' || homeC.userRole.value == 'Guru Mapel';
  bool get isObserver => !isSuperUser && !isTeacher;
  bool get isReadOnly => isObserver;


   @override
  void onInit() {
    super.onInit();
    
    // --- PERUBAHAN 2: Inisialisasi TabController ---
    // Inisialisasi dengan jumlah tab yang kita rencanakan (misal: 4)
    tabController = TabController(length: 4, vsync: this);
    
    // Tambahkan listener untuk tahu saat tab berpindah
    tabController.addListener(() {
      selectedTabIndex.value = tabController.index;
      // Di sini kita bisa tambahkan logika lazy loading untuk tab lain nanti
    });
    
    // Logika `once` untuk menunggu HomeController sudah sangat bagus, biarkan saja.
    if (!homeC.isLoading.value) {
      fetchInitialDataBasedOnRole();
    } else {
      once(homeC.isLoading, (bool loading) {
        if (!loading) {
          fetchInitialDataBasedOnRole();
        }
      });
    }
  }

  // lib/app/modules/daftar_kelas/controllers/daftar_kelas_controller.dart

  // @override
  // void onInit() {
  //   super.onInit();
  //   tabController = TabController(length: 4, vsync: this);
  //   tabController.addListener(() { selectedTabIndex.value = tabController.index; });

  //   // Kembali ke listener 'once' yang aman
  //   if (homeC.isReady.value) {
  //     fetchInitialDataBasedOnRole();
  //   } else {
  //     once(homeC.isReady, (_) => fetchInitialDataBasedOnRole());
  //   }
  // }

   @override
  void onClose() {
    // --- PERUBAHAN 3: Jangan lupa dispose TabController ---
    tabController.dispose();
    super.onClose();
  }

  

  // void toggleObservingMode() {
  //   isObservingMode.value = !isObservingMode.value;
    
  //   // Tukar sumber data yang ditampilkan
  //   if (isObservingMode.value) {
  //     displayKelasList.assignAll(_allSchoolClasses);
  //   } else {
  //     displayKelasList.assignAll(_taughtClasses);
  //   }
    
  //   // Reset pilihan kelas saat mode berganti
  //   if (displayKelasList.isNotEmpty) {
  //     gantiKelasTerpilih(displayKelasList.first);
  //   } else {
  //     kelasTerpilih.value = null;
  //   }
  // }

  Future<void> fetchHalaqohData(String namaKelas) async {
  try {
    isLoadingHalaqoh.value = true;
    daftarSiswaHalaqoh.clear();

    String idTahunAjaran = homeC.idTahunAjaran.value!;
    String semesterAktif = homeC.semesterAktifId.value;
    
    // LANGKAH 1: Ambil daftar siswa dasar dari kelas yang dipilih
    final siswaDiKelasSnapshot = await firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(namaKelas)
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').get();

    if (siswaDiKelasSnapshot.docs.isEmpty) {
      // Jika tidak ada siswa di kelas, hentikan proses.
      isLoadingHalaqoh.value = false;
      return;
    }

    // Siapkan daftar Future. Setiap Future akan mencari data pelengkap untuk satu siswa.
    List<Future<Map<String, dynamic>?>> futures = siswaDiKelasSnapshot.docs.map((siswaDoc) async {
      final siswaDataDasar = siswaDoc.data();
      final nisn = siswaDataDasar['nisn'];

      // LANGKAH 2: Untuk setiap siswa, lakukan query PENCARIAN ke koleksi kelompokmengaji
      // Kita mencari dokumen di mana ID-nya (nisn) sama dengan nisn siswa ini.
      final halaqohDataSnapshot = await firestore
          .collectionGroup('daftarsiswa') // <- Gunakan CollectionGroup untuk mencari di semua subkoleksi
          .where('nisn', isEqualTo: nisn)
          .where('tahunajaran', isEqualTo: homeC.idTahunAjaran.value!.replaceAll('-', '/')) // Filter berdasarkan tahun ajaran aktif
          .limit(1)
          .get();

      // LANGKAH 3: Gabungkan data
      if (halaqohDataSnapshot.docs.isNotEmpty) {
        final dataHalaqoh = halaqohDataSnapshot.docs.first.data();
        
        // Gabungkan data dasar dengan data halaqoh yang kaya
        return {
          ...siswaDataDasar, // Mengandung namasiswa, nisn, dll.
          ...dataHalaqoh,    // Mengandung ummi, capaian_terakhir, namapengampu, tempatmengaji
        };
      } else {
        // Jika siswa ini belum punya kelompok halaqoh, kembalikan data dasarnya saja
        return siswaDataDasar;
      }
    }).toList();

    // Tunggu semua proses pencarian dan penggabungan selesai
    final List<Map<String, dynamic>?> hasilGabungan = await Future.wait(futures);

    // Bersihkan dari hasil null dan urutkan berdasarkan nama
    final List<Map<String, dynamic>> hasilFinal = hasilGabungan.where((item) => item != null).cast<Map<String, dynamic>>().toList();
    hasilFinal.sort((a, b) => (a['namasiswa'] as String).compareTo(b['namasiswa'] as String));

    daftarSiswaHalaqoh.assignAll(hasilFinal);

  } catch (e) {
    Get.snackbar("Error", "Gagal memuat data halaqoh: $e");
    print('Link nya = $e');
  } finally {
    isLoadingHalaqoh.value = false;
  }
}

  Future<void> fetchInitialDataBasedOnRole() async {
    try {
      isLoadingKelas.value = true;
      List<String> kelasUntukTampil;
      if (isSuperUser || isObserver) {
        kelasUntukTampil = await _fetchAllKelasDiSekolah();
      } else { // isTeacher
        kelasUntukTampil = await homeC.getDataKelasYangDiajar();
      }
      daftarKelasDiajar.assignAll(kelasUntukTampil);
      if (daftarKelasDiajar.isNotEmpty) {
        gantiKelasTerpilih(daftarKelasDiajar.first);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data awal: $e");
    } finally {
      isLoadingKelas.value = false;
    }
  }

  // --- HELPER FUNCTION BARU (Khusus Kepala Sekolah) ---
  Future<List<String>> _fetchAllKelasDiSekolah() async {
    try {
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      final snapshot = await firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').orderBy('namakelas').get();
          
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print("Error fetchAllKelasDiSekolah: $e");
      return []; // Kembalikan list kosong jika error
    }
  }

  Future<void> fetchKelasYangDiajar() async {
    try {
      isLoadingKelas.value = true;
      // [PERBAIKAN] Panggil fungsi tanpa parameter, karena HomeController sudah tahu semester aktif
      final kelas = await homeC.getDataKelasYangDiajar(); 
      
      daftarKelasDiajar.assignAll(kelas);

      if (daftarKelasDiajar.isNotEmpty) {
        gantiKelasTerpilih(daftarKelasDiajar.first);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar kelas: $e");
    } finally {
      isLoadingKelas.value = false;
    }
  }

  /// 2. Aksi yang dijalankan saat pengguna memilih kelas lain.
   void gantiKelasTerpilih(String namaKelas) async {
    if (kelasTerpilih.value == namaKelas && !isLoadingMapelDanJadwal.value) return;
    kelasTerpilih.value = namaKelas;
    isLoadingMapelDanJadwal.value = true;
    List<Future> tasks = [];
    if (isSuperUser || isObserver) {
      tasks.add(fetchDaftarSiswa(namaKelas));
      tasks.add(fetchHalaqohData(namaKelas));
    } else { // isTeacher
      tasks.add(fetchDataMapelDanJadwal(namaKelas));
      tasks.add(fetchDaftarSiswa(namaKelas));
      tasks.add(checkIsWaliKelas(namaKelas));
    }
    await Future.wait(tasks);
    isLoadingMapelDanJadwal.value = false;
  }

  

  Future<void> fetchDataMapelDanJadwal(String namaKelas) async {
    try {
      isLoadingMapelDanJadwal.value = true; // Ganti nama state loading
      daftarMapelDiajar.clear();
      semuaMapelDiKelas.clear();
      
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      String idUser = auth.currentUser!.uid;
      String idSekolah = homeC.idSekolah;

      // --- SUMBER KEBENARAN TUNGGAL: Koleksi 'penugasan' ---
      final penugasanSnapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('penugasan').doc(namaKelas)
          .collection('matapelajaran').get();
          
      if (penugasanSnapshot.docs.isEmpty) {
        // Jika tidak ada satu pun mapel yang ditugaskan di kelas ini,
        // maka kedua daftar akan kosong, dan UI akan menampilkan pesan yang sesuai.
        print("INFO: Tidak ada data penugasan mapel untuk kelas $namaKelas.");
        return; // Hentikan fungsi
      }

      // --- Proses & Pisahkan Data ---
      List<Map<String, dynamic>> listMapelDiajar = [];
      List<Map<String, dynamic>> listSemuaMapel = [];

      for (var doc in penugasanSnapshot.docs) {
        final data = doc.data();
        final mapelInfo = {
          'namaMapel': data['namamatapelajaran'] ?? doc.id,
          'namaGuru': data['guru'] ?? 'Belum Diatur',
          'idKelas': data['idKelas'] ?? namaKelas, // Tambahkan idKelas untuk argumen navigasi
        };

        // Tambahkan ke daftar "Semua Mapel"
        listSemuaMapel.add(mapelInfo);

        // Jika ID guru di data ini cocok dengan user yang login, tambahkan ke daftar "Mapel Saya"
        if (data['idGuru'] == idUser) {
          listMapelDiajar.add(mapelInfo);
        }
      }
      
      // --- Logika Baru: Hapus duplikat dari daftar "Semua Mapel" ---
      final Set<String> namaMapelDiajar = listMapelDiajar.map((e) => e['namaMapel'] as String).toSet();
      listSemuaMapel.removeWhere((mapel) => namaMapelDiajar.contains(mapel['namaMapel']));
      // -----------------------------------------------------------------
      
      daftarMapelDiajar.assignAll(listMapelDiajar);
      semuaMapelDiKelas.assignAll(listSemuaMapel);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat mata pelajaran: $e");
    } finally {
      isLoadingMapelDanJadwal.value = false;
    }
  }


  Future<void> checkIsWaliKelas(String namaKelas) async {
    try {
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      final kelasDoc = await firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(namaKelas).get();
      
      if (kelasDoc.exists && kelasDoc.data() != null) {
        final String idWaliKelas = kelasDoc.data()!['idwalikelas'] ?? '';
        if (idWaliKelas == auth.currentUser!.uid) {
          isWaliKelas.value = true;
        } else {
          isWaliKelas.value = false;
        }
      } else {
        isWaliKelas.value = false;
      }
    } catch(e) {
      isWaliKelas.value = false;
      print("Error saat cek wali kelas: $e");
    }
  }

  /// 3. Mengambil daftar mata pelajaran dari Firestore berdasarkan kelas yang dipilih.
  Future<void> fetchDataMapel(String namaKelas) async {
    try {
      isLoadingMapel.value = true;
      daftarMapel.clear();
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      String semesterAktif = homeC.semesterAktifId.value;
      String idUser = auth.currentUser!.uid;
      String idSekolah = homeC.idSekolah;

      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('semester').doc(semesterAktif) // <-- INTEGRASI SEMESTER
          .collection('kelasnya').doc(namaKelas)
          .collection('matapelajaran').get();

      if (snapshot.docs.isNotEmpty) {
        daftarMapel.assignAll(snapshot.docs.map((doc) => doc.data()).toList());
      }
    } catch (e) { Get.snackbar("Error", "Gagal memuat mata pelajaran: $e"); } 
    finally { isLoadingMapel.value = false; }
  }

  /// Mengambil daftar siswa di kelas terpilih untuk ditampilkan di dialog absensi.
  Future<void> fetchDaftarSiswa(String namaKelas) async {
    try {
      daftarSiswaDiKelas.clear();
      absensiHariIni.clear();
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      String semesterAktif = homeC.semesterAktifId.value;
      
      final siswaSnapshot = await firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(namaKelas)
          .collection('semester').doc(semesterAktif)
          .collection('daftarsiswa').orderBy('namasiswa').get();
      
      if (siswaSnapshot.docs.isNotEmpty) {
        daftarSiswaDiKelas.assignAll(siswaSnapshot.docs.map((doc) => doc.data()).toList());
        await fetchAbsensiHariIni(namaKelas); // Ambil data absensi yang sudah ada
      }
    } catch (e) { Get.snackbar("Error", "Gagal memuat daftar siswa: $e"); }
  }

  /// Mengambil data absensi yang sudah tersimpan untuk hari ini.
  Future<void> fetchAbsensiHariIni(String namaKelas) async {
    String idTahunAjaran = homeC.idTahunAjaran.value!;
    String semesterAktif = homeC.semesterAktifId.value;
    String tgl = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final absensiDoc = await firestore
        .collection('Sekolah').doc(homeC.idSekolah).collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(namaKelas).collection('semester').doc(semesterAktif)
        .collection('absensi').doc(tgl).get();

    if (absensiDoc.exists && absensiDoc.data() != null) {
      final data = absensiDoc.data()!;
      // Isi map absensiHariIni dengan data dari Firestore
      if (data['siswa'] is Map) {
        absensiHariIni.value = Map<String, String>.from(data['siswa']);
      }
    }
  }

  /// Mengupdate status absensi siswa di dalam state.
  void updateAbsensi(String nisn, String status) {
    if (absensiHariIni[nisn] == status) {
      absensiHariIni.remove(nisn); // Jika status yang sama ditekan lagi, anggap "Hadir"
    } else {
      absensiHariIni[nisn] = status;
    }
  }

  /// Menyimpan data absensi ke Firestore.
  Future<void> simpanAbsensi() async {
    if (kelasTerpilih.value == null) return;
    isSavingAbsensi.value = true;
    try {
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      String semesterAktif = homeC.semesterAktifId.value;
      String namaKelas = kelasTerpilih.value!;
      String tgl = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final docRef = firestore
          .collection('Sekolah').doc(homeC.idSekolah).collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(namaKelas).collection('semester').doc(semesterAktif)
          .collection('absensi').doc(tgl);

      await docRef.set({
        'tanggal': Timestamp.now(),
        'kelas': namaKelas,
        'diinput_oleh': auth.currentUser!.uid,
        'siswa': absensiHariIni, // Simpan seluruh map absensi
      }, SetOptions(merge: true));

      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "Absensi untuk hari ini telah disimpan.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan absensi: $e");
    } finally {
      isSavingAbsensi.value = false;
    }
  }
}