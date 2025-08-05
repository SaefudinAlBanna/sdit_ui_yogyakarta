// lib/app/modules/daftar_halaqohnya/controllers/daftar_halaqohnya_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/siswa_halaqoh.dart';
import '../../daftar_halaqoh_perfase/controllers/daftar_halaqoh_perfase_controller.dart';
import '../../home/controllers/home_controller.dart';

import '../../../services/halaqoh_service.dart';
import '../../../interfaces/input_nilai_massal_interface.dart';
import '../../../widgets/tandai_siap_ujian_sheet.dart';

class DaftarHalaqohnyaController extends GetxController 
    implements IInputNilaiMassalController, ITandaiSiapUjianController {


      // --- [BERSIH] GRUP 1: DEPENDENSI ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final HalaqohService halaqohService = Get.find();
  final String idSekolah = '20404148';

  // --- [BERSIH] GRUP 2: IMPLEMENTASI KONTRAK (PROPERTY) ---
  @override
  final RxBool isDialogLoading = false.obs;
  @override
  final RxList<String> santriTerpilihUntukUjian = <String>[].obs;
  @override
  final RxBool isSavingNilai = false.obs;
  @override
  final RxList<SiswaHalaqoh> daftarSiswa = <SiswaHalaqoh>[].obs;
  @override
  final RxList<String> santriTerpilihUntukNilai = <String>[].obs;
  @override
  Map<String, TextEditingController> nilaiMassalControllers = {};
  @override
  final TextEditingController suratC = TextEditingController();
  @override
  final TextEditingController ayatHafalC = TextEditingController();
  @override
  final TextEditingController capaianC = TextEditingController();
  @override
  final TextEditingController materiC = TextEditingController();
  @override
  RxString get keteranganHalaqoh => _keteranganHalaqoh;
  final RxString _keteranganHalaqoh = "".obs;
  
  // --- [BERSIH] GRUP 3: STATE & CONTROLLER SPESIFIK UNTUK HALAMAN INI ---
  // Variabel state halaman Pimpinan
  final RxString fase = ''.obs;
  final RxString namaPengampu = ''.obs;
  final RxString idPengampu = ''.obs;
  final RxString namaTempat = ''.obs;
  final Rxn<String> urlFotoPengampu = Rxn<String>();
  final RxBool isLoading = true.obs;
  
  // Variabel untuk fitur "Tambah Siswa"
  final RxMap<String, Map<String, dynamic>> siswaTerpilih = <String, Map<String, dynamic>>{}.obs;
  final RxString kelasAktifDiSheet = ''.obs;
  final RxList<String> availableKelas = <String>[].obs;
  final RxString searchQueryInSheet = ''.obs;
  final TextEditingController kelasSiswaC = TextEditingController();
  
  // Variabel untuk fitur "Update UMI"
  final TextEditingController umiC = TextEditingController();
  final TextEditingController bulkUpdateUmiC = TextEditingController();
  final RxList<String> siswaTerpilihUntukUpdateMassal = <String>[].obs;
  final List<String> listLevelUmi = ['Jilid 1', 'Jilid 2', 'Jilid 3', 'Jilid 4', 'Jilid 5', 'Jilid 6', 'Al-Quran', 'Gharib', 'Tajwid', 'Turjuman', 'Juz 30', 'Juz 29', 'Juz 28', 'Juz 1', 'Juz 2', 'Juz 3', 'Juz 4', 'Juz 5'];
  
  // --- [BERSIH] GRUP 4: WORKER & STREAM SUBSCRIPTION ---
  StreamSubscription? _siswaSubscription;

  // --- [BERSIH] GRUP 5: GETTERS ---
  bool get canPerformWriteActions => homeC.canManageTahsin 
    || homeC.userTugas.contains('Koordinator Halaqoh') 
    || homeC.kapten || homeC.isDalang;

  
  final TextEditingController nilaiC = TextEditingController();
  final TextEditingController capaianUjianC = TextEditingController();
  final TextEditingController levelUjianC = TextEditingController();


  @override
  Future<void> tandaiSiapUjianMassal() async {
    // Validasi sederhana, pastikan ada siswa yang dipilih.
    if (santriTerpilihUntukUjian.isEmpty) {
      Get.snackbar("Peringatan", "Pilih minimal satu santri.");
      return;
    }

    isDialogLoading.value = true;

    // Filter objek SiswaHalaqoh lengkap berdasarkan NISN yang terpilih di UI.
    final List<SiswaHalaqoh> siswaTerpilihObjek = daftarSiswa
        .where((siswa) => santriTerpilihUntukUjian.contains(siswa.nisn))
        .toList();

    // Siapkan info kelompok dari state controller ini.
    final infoKelompok = {
      'fase': fase.value,
      'idpengampu': idPengampu.value,
      'namapengampu': namaPengampu.value,
      'tempatmengaji': namaTempat.value,
    };

    // Panggil service untuk melakukan tugas berat.
    final bool isSuccess = await halaqohService.tandaiSiapUjianMassal(
      infoKelompok: infoKelompok,
      siswaTerpilih: siswaTerpilihObjek,
    );

    isDialogLoading.value = false;

    if (isSuccess) {
      Get.back(); // Tutup bottom sheet jika berhasil
      Get.snackbar("Berhasil", "${santriTerpilihUntukUjian.length} santri telah ditandai siap ujian.");
      santriTerpilihUntukUjian.clear(); // Bersihkan pilihan
    }
    // Jika gagal, service sudah akan menampilkan snackbar error.
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
  void onInit() {
    super.onInit();
    final Map<String, dynamic>? args = Get.arguments;
    if (args != null) {
      fase.value = args['fase'];
      namaPengampu.value = args['namapengampu'];
      idPengampu.value = args['idpengampu'];
      namaTempat.value = args['namatempat'];
      _loadInitialData();
    } else {
      Get.snackbar("Error", "Informasi Halaqoh tidak lengkap.");
      Get.offAllNamed('/home');
    }
  }

  @override
  void onClose() {
    _siswaSubscription?.cancel();
    // Dispose semua controller
    umiC.dispose(); bulkUpdateUmiC.dispose(); suratC.dispose(); ayatHafalC.dispose();
    capaianC.dispose(); materiC.dispose(); nilaiC.dispose(); kelasSiswaC.dispose();
    capaianUjianC.dispose(); levelUjianC.dispose();
    super.onClose();
  }

  void _loadInitialData() {
    _loadDataPengampu();
    _listenToDaftarSiswa();
  }

  DocumentReference _getPengampuDocRef() {
    return firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelompokmengaji').doc(fase.value)
        .collection('pengampu').doc(idPengampu.value);
  }

  CollectionReference _getDaftarSiswaCollectionRef() {
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    final semesterAktif = homeC.semesterAktifId.value;

    // --- PERBAIKAN UTAMA DI SINI ---
    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(fase.value)
        .collection('pengampu').doc(idPengampu.value) // <-- GUNAKAN UID DARI STATE
        .collection('tempat').doc(namaTempat.value)
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa');
  }



  Future<void> _loadDataPengampu() async {
    try {
      final pegawaiDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idPengampu.value).get();
      if (pegawaiDoc.exists) {
        urlFotoPengampu.value = pegawaiDoc.data()?['profileImageUrl'];
      }
    } catch (e) {
      if (kDebugMode) print("Gagal memuat foto pengampu: $e");
    }
  }

  

  Future<void> _listenToDaftarSiswa() async {
    isLoading.value = true;
    try {
      _siswaSubscription?.cancel();
      _siswaSubscription = _getDaftarSiswaCollectionRef().orderBy('namasiswa').snapshots().listen((snapshot) {
        
        var siswaList = snapshot.docs
            .map((doc) => SiswaHalaqoh.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();

        // --- [LOGIKA SORTING CERDAS] ---
        siswaList.sort((a, b) {
          bool aSiap = a.statusUjian == 'siap_ujian';
          bool bSiap = b.statusUjian == 'siap_ujian';

          if (aSiap && !bSiap) {
            return -1; // Siswa A (siap) didahulukan.
          }
          if (!aSiap && bSiap) {
            return 1; // Siswa B (siap) didahulukan.
          }
          // Jika statusnya sama (keduanya siap atau keduanya tidak), urutkan berdasarkan nama.
          return a.namaSiswa.compareTo(b.namaSiswa);
        });
        // --- [AKHIR LOGIKA SORTING] ---

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


  Future<void> gantiPengampu(Map<String, dynamic>? pengampuBaru) async {
    // 1. Validasi awal (tidak berubah)
    if (pengampuBaru == null || pengampuBaru['uid'] == null || pengampuBaru['alias'] == null) {
      Get.snackbar("Error", "Data pengampu tidak lengkap.");
      return;
    }
    final String idPengampuBaru = pengampuBaru['uid'];
    final String aliasPengampuBaru = pengampuBaru['alias'];
    if (idPengampu.value == idPengampuBaru) {
      Get.snackbar("Info", "Anda memilih pengampu yang sama.");
      return;
    }

    // 2. Tutup dialog pemilihan & tampilkan loading halaman penuh
    Get.back();
    isLoading.value = true;

    try {
      // 3. Semua logika WriteBatch untuk memindahkan data di Firestore (tidak berubah)
      // ... (kode batch.set, batch.delete, dll. tetap sama persis)
      final String idPengampuLama = idPengampu.value;
      final String idPengampuBaru = pengampuBaru!['uid'];
      final String aliasPengampuBaru = pengampuBaru['alias'];
      
      final pengampuLamaRef = _getPengampuDocRef();
      final tempatLamaRef = pengampuLamaRef.collection('tempat').doc(namaTempat.value);
      final siswaSnapshot = await _getDaftarSiswaCollectionRef().get();

      final pengampuBaruRef = firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
          .collection('kelompokmengaji').doc(fase.value)
          .collection('pengampu').doc(idPengampuBaru);
      final tempatBaruRef = pengampuBaruRef.collection('tempat').doc(namaTempat.value);

      final refShortcutLama = firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('pegawai').doc(idPengampuLama)
          .collection('tahunajarankelompok').doc(homeC.idTahunAjaran.value!)
          .collection('semester').doc(homeC.semesterAktifId.value)
          .collection('kelompokmengaji').doc(fase.value);
      
      final refShortcutBaru = firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('pegawai').doc(idPengampuBaru)
          .collection('tahunajarankelompok').doc(homeC.idTahunAjaran.value!)
          .collection('semester').doc(homeC.semesterAktifId.value)
          .collection('kelompokmengaji').doc(fase.value);

      WriteBatch batch = firestore.batch();
      final tempatDataSnapshot = await tempatLamaRef.get();
      if (!tempatDataSnapshot.exists) throw Exception("Data tempat lama tidak ditemukan.");
      
      final tempatData = Map<String, dynamic>.from(tempatDataSnapshot.data() ?? {});
      tempatData['namapengampu'] = aliasPengampuBaru;
      tempatData['idpengampu'] = idPengampuBaru;

      batch.set(pengampuBaruRef, {'namaPengampu': aliasPengampuBaru, 'uidPengampu': idPengampuBaru, 'createdAt': Timestamp.now()});
      batch.set(tempatBaruRef, tempatData);

      // (Logika pemindahan siswa tidak berubah)
      for (var siswaDoc in siswaSnapshot.docs) {
          final rawData = siswaDoc.data();
          if (rawData is! Map<String, dynamic>) continue;
          final siswaData = Map<String, dynamic>.from(rawData);
          siswaData['namapengampu'] = aliasPengampuBaru;
          siswaData['idpengampu'] = idPengampuBaru;
          final siswaRefBaru = tempatBaruRef.collection('semester').doc(homeC.semesterAktifId.value).collection('daftarsiswa').doc(siswaDoc.id);
          batch.set(siswaRefBaru, siswaData);
          batch.delete(siswaDoc.reference);
      }

      batch.delete(tempatLamaRef);
      batch.delete(pengampuLamaRef);
      
      batch.delete(refShortcutLama);
      batch.set(refShortcutBaru, {
        'fase': fase.value, 'tempatmengaji': namaTempat.value,
        'namapengampu': aliasPengampuBaru, 'idpengampu': idPengampuBaru,
        'lokasi_terakhir': tempatData['lokasi_terakhir'] ?? namaTempat.value,
      });

      // 4. Eksekusi semua perubahan ke server
      await batch.commit();

      // 5. Perbarui state di halaman INI
      idPengampu.value = idPengampuBaru;
      namaPengampu.value = aliasPengampuBaru;

      // --- [PERINTAH KUNCI UNTUK AUTO-REFRESH] ---
      // 6. Temukan controller halaman Pimpinan yang "tidur" dan panggil fungsinya.
      Get.find<DaftarHalaqohPerfaseController>().loadDataPengampu();
      // --- [AKHIR PERINTAH KUNCI] ---
      
      Get.snackbar("Berhasil", "Pengampu telah diganti menjadi $aliasPengampuBaru.");

      // 7. Refresh data di halaman ini sendiri
      await _listenToDaftarSiswa();

    } catch (e) {
      Get.snackbar("Error", "Gagal mengganti pengampu: ${e.toString()}");
      isLoading.value = false; // Matikan loading jika terjadi error
    }
  }


  Future<void> openSiswaPicker() async {
    // Reset semua state sheet sebelum dibuka
    siswaTerpilih.clear();
    searchQueryInSheet.value = '';
    availableKelas.clear();
    kelasAktifDiSheet.value = '';

    // Ambil data kelas yang sesuai dengan fase kelompok ini
    final kelas = await getDataKelasYangAda();
    availableKelas.assignAll(kelas);

    // Set kelas aktif default SETELAH data siap
    if (availableKelas.isNotEmpty) {
      kelasAktifDiSheet.value = availableKelas.first;
    }
  }

  void toggleSiswaSelection(Map<String, dynamic> siswaData) {
    final nisn = siswaData['nisn'];
    if (siswaTerpilih.containsKey(nisn)) {
      siswaTerpilih.remove(nisn);
    } else {
      siswaTerpilih[nisn] = siswaData;
    }
  }

  void gantiKelasDiSheet(String kelasBaru) {
    if (kelasAktifDiSheet.value == kelasBaru) return;

    if (siswaTerpilih.isNotEmpty) {
      Get.defaultDialog(
        title: "Simpan Pilihan?",
        middleText: "Anda memiliki ${siswaTerpilih.length} siswa terpilih. Simpan sebelum pindah kelas?",
        textConfirm: "Ya, Simpan & Pindah",
        textCancel: "Pindah & Hapus Pilihan",
        onConfirm: () async {
          Get.back();
          await simpanSiswaTerpilih();
          kelasAktifDiSheet.value = kelasBaru;
        },
        onCancel: () {
          siswaTerpilih.clear();
          kelasAktifDiSheet.value = kelasBaru;
        }
      );
    } else {
      kelasAktifDiSheet.value = kelasBaru;
    }
  }

  Future<void> simpanSiswaTerpilih() async {
    if (siswaTerpilih.isEmpty) return;

    isDialogLoading.value = true;
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      // Siapkan informasi kelompok dari state controller ini
      final tahunAjaranDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(homeC.idTahunAjaran.value!).get();
      final tahunajarannya = tahunAjaranDoc.data()!['namatahunajaran'];
      
      final infoKelompok = {
        'idTahunAjaran': homeC.idTahunAjaran.value!,
        'tahunajaran': tahunajarannya,
        'fase': fase.value,
        'idpengampu': idPengampu.value,
        'namapengampu': namaPengampu.value,
        'tempatmengaji': namaTempat.value,
      };

      // Panggil service yang sama persis
      final bool isSuccess = await halaqohService.addSiswaToKelompok(
        daftarSiswaTerpilih: siswaTerpilih.values.toList(),
        infoKelompok: infoKelompok,
      );

      Get.back(); // Tutup dialog loading

      if (isSuccess) {
        Get.snackbar("Berhasil", "${siswaTerpilih.length} siswa telah ditambahkan.");
        siswaTerpilih.clear();
      }
      // Jika gagal, service sudah menampilkan snackbar error.

    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Gagal menyiapkan info kelompok: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }

  Future<List<String>> getDataKelasYangAda() async {
    final idTahunAjaran = homeC.idTahunAjaran.value;
    List<String> kelasList = [];
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran')
        .where('fase', isEqualTo: fase.value).get(); // Menggunakan 'fase' dari properti kelas
    for (var doc in snapshot.docs) { kelasList.add(doc.id); }
    return kelasList;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSiswaBaru() {
    // Validasi awal tidak berubah
    if (kelasAktifDiSheet.value.isEmpty) {
      return const Stream.empty();
    }
    
    // Ambil semua data yang dibutuhkan untuk path yang lengkap
    final idTahunAjaran = homeC.idTahunAjaran.value;
    final semesterAktifId = homeC.semesterAktifId.value;

    // Pastikan data global tersedia sebelum membuat query
    if (idTahunAjaran == null) {
        Get.snackbar("Error", "Tahun Ajaran tidak terdeteksi.");
        return const Stream.empty();
    }

    // --- [PERBAIKAN] Gunakan path yang benar dengan semester ---
    return firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(kelasAktifDiSheet.value)
        .collection('semester').doc(semesterAktifId) // <-- Path semester ditambahkan
        .collection('daftarsiswa').where('statuskelompok', isEqualTo: 'baru')
        .snapshots();
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
      Get.back();
      Get.snackbar("Berhasil", "Data Umi telah diperbarui.");
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

      for (String nisn in siswaTerpilihUntukUpdateMassal) {
        batch.update(refDaftarSiswa.doc(nisn), {'ummi': bulkUpdateUmiC.text});
      }

      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "${siswaTerpilihUntukUpdateMassal.length} siswa telah diupdate.");
    } catch (e) {
      Get.snackbar("Error", "Gagal melakukan update massal: $e");
    } finally {
      isDialogLoading.value = false;
      siswaTerpilihUntukUpdateMassal.clear();
      bulkUpdateUmiC.clear();
    }
  }

  /// Mengelola checkbox santri. Dipanggil dari UI.
  
  @override
  void toggleSantriSelection(String nisn) {
    if (santriTerpilihUntukNilai.contains(nisn)) {
      santriTerpilihUntukNilai.remove(nisn);
    } else {
      santriTerpilihUntukNilai.add(nisn);
    }
  }

  @override
  Future<void> simpanNilaiMassal() async {
    if (santriTerpilihUntukNilai.isEmpty) {
      Get.snackbar("Peringatan", "Pilih minimal satu santri.");
      return;
    }
    if (materiC.text.trim().isEmpty) {
        Get.snackbar("Peringatan", "Materi wajib diisi.");
        return;
    }
    isSavingNilai.value = true;
    final infoKelompok = {
      'idTahunAjaran': homeC.idTahunAjaran.value!,
      'fase': fase.value,
      'idpengampu': idPengampu.value,
      'namapengampu': namaPengampu.value,
      'tempatmengaji': namaTempat.value,
      'lokasi_terakhir': namaTempat.value,
    };
    
    // [PERBAIKAN KUNCI] Ambil nilai dari Map, bukan controller tunggal
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

    final bool isSuccess = await halaqohService.inputNilaiMassal(
      infoKelompok: infoKelompok,
      semuaSiswaDiKelompok: daftarSiswa.map((s) => s.rawData).toList(),
      daftarNisnTerpilih: santriTerpilihUntukNilai.toList(),
      nilaiPerSiswa: nilaiPerSiswa, // Kirim map nilai yang sudah benar
      templateData: templateData,
    );

    isSavingNilai.value = false;

    if (isSuccess) {
      Get.back();
      Get.snackbar("Berhasil", "Nilai berhasil disimpan.");
      clearNilaiForm();
      // Bersihkan juga semua textfield nilai individual
      nilaiMassalControllers.forEach((_, controller) => controller.clear());
    }
  }

   Future<List<Map<String, dynamic>>> getTujuanHalaqoh() async {
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      
      // Cari semua pengampu di fase yang sama
      final pengampuSnapshot = await firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(fase.value)
          .collection('pengampu').get();

      List<Map<String, dynamic>> tujuanList = [];
      for (var pengampuDoc in pengampuSnapshot.docs) {
        // Jangan masukkan kelompok saat ini sebagai tujuan
        if (pengampuDoc.id == idPengampu.value) continue;

        // Ambil juga nama tempatnya
        final tempatSnapshot = await pengampuDoc.reference.collection('tempat').limit(1).get();
        if (tempatSnapshot.docs.isNotEmpty) {
          tujuanList.add({
            'idpengampu': pengampuDoc.id,
            'namapengampu': pengampuDoc.data()['namaPengampu'],
            'namatempat': tempatSnapshot.docs.first.id,
          });
        }
      }
      return tujuanList;
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar tujuan: $e");
      return [];
    }
  }

    // Future<void> pindahHalaqoh(SiswaHalaqoh siswa, Map<String, dynamic> tujuan) async {
    //   Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    //   try {
    //     final String idTahunAjaran = homeC.idTahunAjaran.value!;
    //     final String semesterAktif = homeC.semesterAktifId.value;

    //     final refSiswaAsal = _getDaftarSiswaCollectionRef().doc(siswa.nisn);

    //     final refSiswaTujuan = firestore
    //         .collection('Sekolah').doc(homeC.idSekolah)
    //         .collection('tahunajaran').doc(idTahunAjaran)
    //         .collection('kelompokmengaji').doc(fase.value)
    //         .collection('pengampu').doc(tujuan['idpengampu'])
    //         .collection('tempat').doc(tujuan['namatempat'])
    //         .collection('semester').doc(semesterAktif)
    //         .collection('daftarsiswa').doc(siswa.nisn);

    //     final refDiSiswaUtama = firestore
    //         .collection('Sekolah').doc(homeC.idSekolah)
    //         .collection('siswa').doc(siswa.nisn)
    //         .collection('tahunajarankelompok').doc(idTahunAjaran)
    //         .collection('semester').doc(semesterAktif)
    //         .collection('kelompokmengaji').doc(fase.value);

    //     WriteBatch batch = firestore.batch();

    //     // Ambil data siswa asal
    //     final siswaDoc = await refSiswaAsal.get();
    //     final rawData = siswaDoc.data();

    //     if (rawData == null || rawData is! Map<String, dynamic>) {
    //       throw Exception("Data siswa sumber tidak ditemukan atau tidak valid.");
    //     }

    //     // Salin dan modifikasi data siswa
    //     final Map<String, dynamic> siswaData = Map<String, dynamic>.from(rawData);

    //     siswaData['namapengampu'] = tujuan['namapengampu'];
    //     siswaData['idpengampu'] = tujuan['idpengampu'];
    //     siswaData['tempatmengaji'] = tujuan['namatempat'];

    //     // Tambahkan semua operasi batch
    //     batch.set(refSiswaTujuan, siswaData);
    //     batch.delete(refSiswaAsal);
    //     batch.set(refDiSiswaUtama, {
    //       'fase': fase.value,
    //       'namapengampu': tujuan['namapengampu'],
    //       'tempatmengaji': tujuan['namatempat'],
    //     });

    //     await batch.commit();

    //     Get.back(); // Tutup loading dialog
    //     Get.back(); // Kembali ke layar sebelumnya
    //     Get.snackbar("Berhasil", "${siswa.namaSiswa} telah dipindahkan.");
    //   } catch (e) {
    //     Get.back(); // Tutup loading dialog jika error
    //     Get.snackbar("Error", "Gagal memindahkan siswa: ${e.toString()}");
    //   }
    // }

    Future<void> pindahHalaqoh(SiswaHalaqoh siswa, Map<String, dynamic> tujuan) async {
      // 1. [BARU] Tutup dialog PEMILIHAN terlebih dahulu.
      Get.back();

      // 2. [BARU] Gunakan loading HALAMAN PENUH.
      isLoading.value = true;

      try {
        // 3. Semua logika WriteBatch tetap sama persis.
        final String idTahunAjaran = homeC.idTahunAjaran.value!;
        final String semesterAktif = homeC.semesterAktifId.value;
        final refSiswaAsal = _getDaftarSiswaCollectionRef().doc(siswa.nisn);
        final refSiswaTujuan = firestore
            .collection('Sekolah').doc(homeC.idSekolah)
            .collection('tahunajaran').doc(idTahunAjaran)
            .collection('kelompokmengaji').doc(fase.value)
            .collection('pengampu').doc(tujuan['idpengampu'])
            .collection('tempat').doc(tujuan['namatempat'])
            .collection('semester').doc(semesterAktif)
            .collection('daftarsiswa').doc(siswa.nisn);
        final refDiSiswaUtama = firestore
            .collection('Sekolah').doc(homeC.idSekolah)
            .collection('siswa').doc(siswa.nisn)
            .collection('tahunajarankelompok').doc(idTahunAjaran)
            .collection('semester').doc(semesterAktif)
            .collection('kelompokmengaji').doc(fase.value);

        WriteBatch batch = firestore.batch();
        final siswaDoc = await refSiswaAsal.get();
        final rawData = siswaDoc.data();
        if (rawData == null || rawData is! Map<String, dynamic>) {
          throw Exception("Data siswa sumber tidak ditemukan.");
        }
        final Map<String, dynamic> siswaData = Map<String, dynamic>.from(rawData);
        siswaData['namapengampu'] = tujuan['namapengampu'];
        siswaData['idpengampu'] = tujuan['idpengampu'];
        siswaData['tempatmengaji'] = tujuan['namatempat'];

        batch.set(refSiswaTujuan, siswaData);
        batch.delete(refSiswaAsal);
        batch.set(refDiSiswaUtama, { 'fase': fase.value, 'namapengampu': tujuan['namapengampu'], 'tempatmengaji': tujuan['namatempat'] });

        // 4. Eksekusi batch
        await batch.commit();
        
        // 5. [PENTING] Karena kita menggunakan Stream, kita tidak perlu me-refresh manual.
        // Stream akan secara otomatis mendeteksi bahwa satu siswa telah "hilang" dari daftar.
        // Cukup tampilkan notifikasi berhasil.
        Get.snackbar("Berhasil", "${siswa.namaSiswa} telah dipindahkan.");

      } catch (e) {
        Get.snackbar("Error", "Gagal memindahkan siswa: ${e.toString()}");
      } finally {
        // 6. [PENTING] Pastikan loading SELALU dimatikan, baik berhasil maupun gagal.
        isLoading.value = false;
      }
    }



  /// Membersihkan form template nilai.
  @override
  void clearNilaiForm() {
    suratC.clear();
    ayatHafalC.clear();
    capaianC.clear();
    materiC.clear();
    _keteranganHalaqoh.value = ""; // Gunakan variabel privat
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