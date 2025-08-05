import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../modules/home/controllers/home_controller.dart';

class KelasInfo {
  final bool isSet;
  final String? namaWaliKelas;
  KelasInfo({required this.isSet, this.namaWaliKelas});
}

class PemberianKelasSiswaController extends GetxController {
  // --- DEPENDENSI ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final String idSekolah = '20404148';
  late String idUser;
  late String emailAdmin;

  // --- STATE MANAGEMENT ---
  final RxBool isLoading = true.obs;
  final RxBool isLoadingDetails = false.obs;
  final RxBool isLoadingTambahKelas = false.obs;
  final RxList<String> daftarKelas = <String>[].obs;
  final Rxn<String> kelasTerpilih = Rxn<String>();
  final Rxn<KelasInfo> kelasInfo = Rxn<KelasInfo>();
  final Rx<Stream<QuerySnapshot<Map<String, dynamic>>>> streamSiswa = Rx(const Stream.empty());
  final TextEditingController waliKelasSiswaC = TextEditingController();

  // --- STATE BARU UNTUK FITUR DAFTAR SISWA ---
  final RxString searchQuery = ''.obs;
  final RxBool isChangingWaliKelas = false.obs;

  @override
  void onInit() {
    super.onInit();
    idUser = auth.currentUser!.uid;
    emailAdmin = auth.currentUser!.email!;
    _initializeData();
  }

  @override
  void onClose() {
    waliKelasSiswaC.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    try {
      isLoading.value = true;
      final kelas = await homeC.getDataKelas();
      daftarKelas.assignAll(kelas);
      _activateSiswaStream();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data awal: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> gantiKelasTerpilih(String namaKelas) async {
    if (kelasTerpilih.value == namaKelas) return;
    searchQuery.value = ''; 
    kelasTerpilih.value = namaKelas;
    await fetchKelasDetails(namaKelas);
  }

  Future<void> fetchKelasDetails(String namaKelas) async {
    try {
      isLoadingDetails.value = true;
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      final docRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(namaKelas);
      final docSnap = await docRef.get();
      if (docSnap.exists && docSnap.data()?['walikelas'] != null && docSnap.data()!['walikelas'].isNotEmpty) {
        String namaWali = docSnap.data()!['walikelas'];
        waliKelasSiswaC.text = namaWali;
        kelasInfo.value = KelasInfo(isSet: true, namaWaliKelas: namaWali);
      } else {
        waliKelasSiswaC.clear();
        kelasInfo.value = KelasInfo(isSet: false);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat detail kelas: $e");
      kelasInfo.value = KelasInfo(isSet: false);
    } finally {
      isLoadingDetails.value = false;
    }
  }

  void onWaliKelasSelected(String? waliKelas) {
    if (waliKelas != null && waliKelas.isNotEmpty) {
      waliKelasSiswaC.text = waliKelas;
      kelasInfo.value = KelasInfo(isSet: true, namaWaliKelas: waliKelas);
    }
  }
  
  void _activateSiswaStream() {
    streamSiswa.value = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').where('status', isNotEqualTo: 'aktif').snapshots();
  }

  Future<String> getTahunAjaranTerakhir() async {
    return homeC.idTahunAjaran.value ?? (await homeC.getTahunAjaranTerakhir());
  }

  Future<List<String>> getDataWaliKelasBaru() async {
    String idTahunAjaran = homeC.idTahunAjaran.value!;
    QuerySnapshot<Map<String, dynamic>> snapKelasSaatIni = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').get();
    final Set<String> waliKelasYangSudahAda = snapKelasSaatIni.docs.map((doc) => doc.data()['walikelas'] as String?).where((wali) => wali != null && wali.isNotEmpty).cast<String>().toSet();
    QuerySnapshot<Map<String, dynamic>> snapSemuaGuru = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').where('role', isEqualTo: 'Guru Kelas').get();
    final List<String> waliKelasTersedia = snapSemuaGuru.docs.map((doc) => doc.data()['alias'] as String).where((namaAlias) => !waliKelasYangSudahAda.contains(namaAlias)).toList();
    return waliKelasTersedia;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSiswaDiKelasStream() {
    if (kelasTerpilih.value == null) {
      return const Stream.empty();
    }
    String idTahunAjaran = homeC.idTahunAjaran.value!;
    String semesterAktifId = homeC.semesterAktifId.value; 

    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(kelasTerpilih.value!)
        .collection('semester').doc(semesterAktifId) 
        .collection('daftarsiswa')
        .snapshots();
  }

  Future<void> removeSiswaFromKelas(String nisn) async {
    if (kelasTerpilih.value == null) return;
    
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      String semesterAktifId = homeC.semesterAktifId.value; 
      final String namaKelas = kelasTerpilih.value!;

      final siswaDiKelasRef = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(namaKelas)
        .collection('semester').doc(semesterAktifId) 
        .collection('daftarsiswa').doc(nisn);
      
      final siswaUtamaRef = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(nisn);

      WriteBatch batch = firestore.batch();
      batch.delete(siswaDiKelasRef);
      // --- [MODIFIKASI] ---
      // Saat siswa dihapus, set status dan hapus field kelasnya.
      batch.update(siswaUtamaRef, {'status': 'tidak aktif', 'kelas': FieldValue.delete()});
      await batch.commit();
      
      Get.back();
      Get.snackbar("Berhasil", "Siswa telah dihapus dari kelas $namaKelas.");

    } catch(e) {
      Get.back();
      Get.snackbar("Gagal", "Gagal menghapus siswa: $e");
    }
  }

  Future<void> inisialisasiSemuaSiswaKeKelas() async {
    if (kelasTerpilih.value == null || waliKelasSiswaC.text.isEmpty) {
      Get.snackbar("Gagal", "Pilih kelas dan tentukan wali kelas terlebih dahulu.");
      return;
    }
    // ... (Logika konfirmasi dialog tetap sama)
    Get.defaultDialog(
      title: "Konfirmasi Aksi Massal",
      middleText: "Anda yakin ingin menambahkan SEMUA siswa yang belum memiliki kelas ke ${kelasTerpilih.value}?",
      textConfirm: "Ya, Tambahkan Semua",
      onConfirm: () async {
        Get.back();
        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
        isLoadingTambahKelas.value = true;
        try {
          // ... (Blok persiapan data tetap sama)
          final String namaKelasSaatIni = kelasTerpilih.value!;
          final String idTahunAjaran = homeC.idTahunAjaran.value!;
          final String semesterAktifId = homeC.semesterAktifId.value;
          // ...
          final guruDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').where('alias', isEqualTo: waliKelasSiswaC.text).limit(1).get();
          if (guruDoc.docs.isEmpty) throw Exception("Data wali kelas tidak ditemukan.");
          final String idWaliKelas = guruDoc.docs.first.id;
          final String namaWaliKelas = guruDoc.docs.first.data()['alias'];
          final String kelasAngka = namaKelasSaatIni.substring(0, 1);
          final String idFaseRaw = (kelasAngka == '1' || kelasAngka == '2') ? "fase_a" : (kelasAngka == '3' || kelasAngka == '4') ? "fase_b" : "fase_c";
          final String faseFormatted = "Fase ${idFaseRaw.substring(idFaseRaw.length - 1).toUpperCase()}";
          final dataKelas = {'namakelas': namaKelasSaatIni, 'idwalikelas': idWaliKelas, 'walikelas': namaWaliKelas, 'fase': faseFormatted};

          final siswaBaruSnapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('siswa').where('status', isNotEqualTo: 'aktif').get();
          if (siswaBaruSnapshot.docs.isEmpty) {
            Get.back(); Get.snackbar("Info", "Tidak ada siswa baru yang bisa ditambahkan.");
            isLoadingTambahKelas.value = false; return;
          }
          
          WriteBatch batch = firestore.batch();
          final kelasTahunAjaranRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(namaKelasSaatIni);

          for (var docSiswa in siswaBaruSnapshot.docs) {
            final nisnSiswa = docSiswa.id;
            final namaSiswa = docSiswa.data()['nama'] ?? 'Tanpa Nama';
            
            final siswaDiSemesterRef = kelasTahunAjaranRef
                .collection('semester').doc(semesterAktifId)
                .collection('daftarsiswa').doc(nisnSiswa);
                
            final siswaUtamaRef = docSiswa.reference;
            final dataSiswa = {'namasiswa': namaSiswa, 'nisn': nisnSiswa, ...dataKelas, 'statuskelompok': "baru"};
            
            batch.set(kelasTahunAjaranRef, dataKelas, SetOptions(merge: true));
            batch.set(siswaDiSemesterRef, dataSiswa);
            // --- [MODIFIKASI] ---
            // Tambahkan field 'kelas' saat status diupdate.
            batch.update(siswaUtamaRef, {'status': 'aktif', 'kelas': namaKelasSaatIni});
          }
          
          await batch.commit();
          Get.back();
          Get.snackbar("Berhasil", "${siswaBaruSnapshot.docs.length} siswa telah ditambahkan ke kelas $namaKelasSaatIni.");
        } catch (e) {
          Get.back();
          Get.snackbar('Gagal', e.toString().replaceAll('Exception: ', ''));
        } finally {
          isLoadingTambahKelas.value = false;
        }
      },
      textCancel: "Batal"
    );
  }

  Future<void> inisialisasiSiswaDiKelas(String namaSiswa, String nisnSiswa) async {
    if (kelasTerpilih.value == null || waliKelasSiswaC.text.isEmpty) {
      Get.snackbar("Gagal", "Pilih kelas dan tentukan wali kelas terlebih dahulu.");
      return;
    }
    isLoadingTambahKelas.value = true;
    try {
      // ... (Blok persiapan data tetap sama)
      final String namaKelasSaatIni = kelasTerpilih.value!;
      final String idTahunAjaran = homeC.idTahunAjaran.value!;
      final String semesterAktifId = homeC.semesterAktifId.value;
      // ...
      final guruDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').where('alias', isEqualTo: waliKelasSiswaC.text).limit(1).get();
      if (guruDoc.docs.isEmpty) throw Exception("Data wali kelas dengan nama '${waliKelasSiswaC.text}' tidak ditemukan.");
      final String idWaliKelas = guruDoc.docs.first.id;
      final String namaWaliKelas = guruDoc.docs.first.data()['alias'];
      final String kelasAngka = namaKelasSaatIni.substring(0, 1);
      final String idFaseRaw = (kelasAngka == '1' || kelasAngka == '2') ? "fase_a" : (kelasAngka == '3' || kelasAngka == '4') ? "fase_b" : "fase_c";
      final String faseFormatted = "Fase ${idFaseRaw.substring(idFaseRaw.length - 1).toUpperCase()}";
      final dataKelas = {'namakelas': namaKelasSaatIni, 'idwalikelas': idWaliKelas, 'walikelas': namaWaliKelas, 'fase': faseFormatted};

      WriteBatch batch = firestore.batch();
      
      final kelasTahunAjaranRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(namaKelasSaatIni);
      
      final siswaDiSemesterRef = kelasTahunAjaranRef
          .collection('semester').doc(semesterAktifId)
          .collection('daftarsiswa').doc(nisnSiswa);
          
      final siswaUtamaRef = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(nisnSiswa);
      
      final dataSiswa = {'namasiswa': namaSiswa, 'nisn': nisnSiswa, ...dataKelas, 'statuskelompok': "baru"};
      
      batch.set(kelasTahunAjaranRef, dataKelas, SetOptions(merge: true));
      batch.set(siswaDiSemesterRef, dataSiswa);
      // --- [MODIFIKASI] ---
      // Tambahkan field 'kelas' saat status diupdate.
      batch.update(siswaUtamaRef, {'status': 'aktif', 'kelas': namaKelasSaatIni});
      
      await batch.commit();
      Get.snackbar("Berhasil", "$namaSiswa telah ditambahkan ke kelas $namaKelasSaatIni.");
    } catch (e) {
      Get.snackbar('Gagal', e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoadingTambahKelas.value = false;
    }
  }

  // --- [TAMBAHAN] ---
  /// Fungsi untuk mengupdate field 'kelas' pada semua siswa berdasarkan
  /// data dari tahun ajaran & semester aktif.
  /// Fungsi ini bersifat massal dan bisa dijalankan sekali saja.
  Future<void> updateKelasSiswaMassal() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()), 
      barrierDismissible: false,
    );
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value;
      final semesterAktifId = homeC.semesterAktifId.value;

      if (idTahunAjaran == null) {
        throw Exception("Tahun ajaran aktif tidak ditemukan.");
      }

      WriteBatch batch = firestore.batch();
      int siswaUpdatedCount = 0;

      // 1. Dapatkan semua kelas di tahun ajaran ini
      final kelasSnapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').get();

      if (kelasSnapshot.docs.isEmpty) {
        throw Exception("Tidak ada data kelas ditemukan di tahun ajaran ini.");
      }

      // 2. Iterasi setiap kelas
      for (final kelasDoc in kelasSnapshot.docs) {
        final namaKelas = kelasDoc.id;
        
        // 3. Dapatkan semua siswa di dalam kelas & semester tersebut
        final daftarSiswaSnapshot = await kelasDoc.reference
            .collection('semester').doc(semesterAktifId)
            .collection('daftarsiswa').get();

        // 4. Untuk setiap siswa, siapkan update di batch
        for (final siswaDiKelasDoc in daftarSiswaSnapshot.docs) {
          final nisn = siswaDiKelasDoc.id;
          final siswaUtamaRef = firestore
              .collection('Sekolah').doc(idSekolah)
              .collection('siswa').doc(nisn);
          
          // Tambahkan operasi update ke batch
          batch.update(siswaUtamaRef, {'kelas': namaKelas});
          siswaUpdatedCount++;
        }
      }

      // 5. Commit semua perubahan sekaligus
      await batch.commit();

      Get.back(); // Tutup dialog loading
      Get.snackbar(
        "Berhasil", 
        "Data kelas untuk $siswaUpdatedCount siswa telah berhasil di-update.",
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.back(); // Tutup dialog loading
      Get.snackbar(
        "Gagal", 
        "Terjadi kesalahan: ${e.toString().replaceAll('Exception: ', '')}",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllGuruKelas() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('pegawai')
        .where('role', isEqualTo: 'Guru Kelas')
        .get();
        
    return snapshot.docs.map((doc) => {
      'uid': doc.id,
      'nama': doc.data()['alias'] ?? 'Tanpa Nama',
    }).toList();
  }

  Future<String?> checkExistingWaliKelas(String guruUid, String kelasSaatIni) async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelastahunajaran')
        .where('idwalikelas', isEqualTo: guruUid)
        .limit(1).get();
        
    if (snapshot.docs.isNotEmpty) {
      final existingKelas = snapshot.docs.first.id;
      // Pastikan bukan kelas yang sedang kita edit
      if (existingKelas != kelasSaatIni) {
        return existingKelas;
      }
    }
    return null;
  }

  Future<void> changeWaliKelas(String namaKelas, Map<String, dynamic> guruBaru) async {
    isChangingWaliKelas.value = true;
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      final String idTahunAjaran = homeC.idTahunAjaran.value!;
      final String semesterAktif = homeC.semesterAktifId.value;
      final String guruBaruUid = guruBaru['uid'];
      final String guruBaruNama = guruBaru['nama'];
      
      WriteBatch batch = firestore.batch();
      
      // 1. Path ke dokumen kelas utama
      final kelasRef = firestore.collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(namaKelas);
          
      // 2. Path ke koleksi daftar siswa di dalam kelas tersebut
      final siswaCollectionRef = kelasRef.collection('semester').doc(semesterAktif).collection('daftarsiswa');
      
      // Ambil semua siswa di kelas itu untuk diupdate
      final siswaSnapshot = await siswaCollectionRef.get();

      // UPDATE #1: Update dokumen kelas utama
      batch.update(kelasRef, {
        'idwalikelas': guruBaruUid,
        'walikelas': guruBaruNama,
      });

      // UPDATE #2: Update setiap dokumen siswa di dalam kelas tersebut
      for (final siswaDoc in siswaSnapshot.docs) {
        batch.update(siswaDoc.reference, {
          'idwalikelas': guruBaruUid,
          'walikelas': guruBaruNama,
        });
      }
      
      // Commit semua perubahan sekaligus
      await batch.commit();
      
      Get.back(); // Tutup dialog loading
      Get.snackbar("Berhasil", "Wali kelas untuk $namaKelas telah diganti menjadi $guruBaruNama.");

      // Refresh data di UI
      await fetchKelasDetails(namaKelas);

    } catch (e) {
      Get.back();
      Get.snackbar("Gagal", "Terjadi kesalahan: $e");
    } finally {
      isChangingWaliKelas.value = false;
    }
  }
}