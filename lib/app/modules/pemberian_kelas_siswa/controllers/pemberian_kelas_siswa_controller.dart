// lib/app/modules/pemberian_kelas_siswa/controllers/pemberian_kelas_siswa_controller.dart

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
    searchQuery.value = ''; // Reset pencarian saat ganti kelas
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

  // --- FUNGSI BARU: Mendapatkan stream siswa yang sudah ada di kelas ---
  Stream<QuerySnapshot<Map<String, dynamic>>> getSiswaDiKelasStream() {
    if (kelasTerpilih.value == null) {
      return const Stream.empty();
    }
    String idTahunAjaran = homeC.idTahunAjaran.value!;
    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(kelasTerpilih.value!)
        .collection('daftarsiswa')
        .snapshots();
  }

  // --- FUNGSI BARU: Menghapus siswa dari kelas (Batal Tambah) ---
  Future<void> removeSiswaFromKelas(String nisn) async {
    if (kelasTerpilih.value == null) return;
    
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      final String namaKelas = kelasTerpilih.value!;

      // Definisikan path yang akan dimodifikasi
      final siswaDiKelasRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(namaKelas).collection('daftarsiswa').doc(nisn);
      final siswaUtamaRef = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(nisn);

      WriteBatch batch = firestore.batch();

      // Operasi 1: Hapus dokumen siswa dari dalam sub-koleksi kelas
      batch.delete(siswaDiKelasRef);
      // Operasi 2: Update status siswa di dokumen utama kembali menjadi 'tidak aktif'
      batch.update(siswaUtamaRef, {'status': 'tidak aktif'});

      await batch.commit();
      
      Get.back(); // Tutup dialog loading
      Get.snackbar("Berhasil", "Siswa telah dihapus dari kelas $namaKelas.");

    } catch(e) {
      Get.back();
      Get.snackbar("Gagal", "Gagal menghapus siswa: $e");
    }
  }

  Future<void> inisialisasiSiswaDiKelas(String namaSiswa, String nisnSiswa) async {
    // =================================================================
    // BAGIAN 1: VALIDASI INPUT
    // =================================================================
    if (kelasTerpilih.value == null) {
      Get.snackbar("Gagal", "Kelas belum dipilih. Silakan pilih kelas di bagian atas.");
      return;
    }
    if (waliKelasSiswaC.text.isEmpty) {
      Get.snackbar("Gagal", "Wali kelas belum ditentukan. Silakan pilih wali kelas.");
      return;
    }

    isLoadingTambahKelas.value = true;

    // =================================================================
    // BAGIAN 2: PERSIAPAN DATA
    // =================================================================
    try {
      final String namaKelasSaatIni = kelasTerpilih.value!;
      final String tahunAjaran = await getTahunAjaranTerakhir();
      final String idTahunAjaran = tahunAjaran.replaceAll("/", "-");
      
      // Menentukan Fase berdasarkan nama kelas
      final String kelasAngka = namaKelasSaatIni.substring(0, 1);
      final String idFase = (kelasAngka == '1' || kelasAngka == '2') ? "fase_a" 
                          : (kelasAngka == '3' || kelasAngka == '4') ? "fase_b" 
                          : "fase_c";

      // =================================================================
      // BAGIAN 3: PENGAMBILAN DATA YANG DIPERLUKAN (PRE-FETCH)
      // =================================================================
      
      // Ambil data kurikulum (daftar mapel) dari Firestore
      final kurikulumDoc = await firestore.collection('konfigurasi_kurikulum').doc(idFase).get();
      if (!kurikulumDoc.exists || kurikulumDoc.data()?['matapelajaran'] == null) {
        throw Exception("Konfigurasi kurikulum untuk $idFase tidak ditemukan di Firestore.");
      }
      final List<String> daftarMapelWajib = List<String>.from(kurikulumDoc.data()!['matapelajaran']);

      // Ambil data wali kelas
      final guruDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').where('alias', isEqualTo: waliKelasSiswaC.text).limit(1).get();
      if (guruDoc.docs.isEmpty) throw Exception("Data wali kelas tidak ditemukan.");
      final String idWaliKelas = guruDoc.docs.first.id;
      final String namaWaliKelas = guruDoc.docs.first.data()['alias'];

      // =================================================================
      // BAGIAN 4: PROSES PENULISAN ATOMIK DENGAN WRITEBATCH
      // =================================================================
      WriteBatch batch = firestore.batch();

      // --- 4.1 Definisikan semua path dokumen yang akan kita sentuh ---
      final kelasTahunAjaranRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(namaKelasSaatIni);
      final siswaDiKelasRef = kelasTahunAjaranRef.collection('daftarsiswa').doc(nisnSiswa);
      final semesterRef = siswaDiKelasRef.collection('semester').doc('Semester I');
      final siswaUtamaRef = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(nisnSiswa);

      // --- 4.2 Siapkan data dasar untuk di-set ---
      final dataKelas = {'namakelas': namaKelasSaatIni, 'idwalikelas': idWaliKelas, 'walikelas': namaWaliKelas, 'fase': idFase.replaceAll('_', ' ').toUpperCase()};
      final dataSiswaDiKelas = {'namasiswa': namaSiswa, 'nisn': nisnSiswa, ...dataKelas};
      
      // --- 4.3 Tambahkan operasi tulis ke Batch ---
      
      // a. Set/Update dokumen kelas (merge:true agar tidak menimpa data pendamping)
      batch.set(kelasTahunAjaranRef, dataKelas, SetOptions(merge: true));

      // b. Set dokumen siswa di dalam kelas
      batch.set(siswaDiKelasRef, dataSiswaDiKelas);
      
      // c. Set dokumen semester
      batch.set(semesterRef, {'namaSemester': 'Semester I'});
      
      // d. Loop untuk "menanam" semua mata pelajaran wajib
      for (String namaMapel in daftarMapelWajib) {
        final mapelRef = semesterRef.collection('matapelajaran').doc(namaMapel);
        final dataMapel = {
          'namamatapelajaran': namaMapel,
          'nilai_akhir': null,
          'catatan_guru': null
        };
        batch.set(mapelRef, dataMapel);
      }
      
      // e. Update status siswa di koleksi utama
      batch.update(siswaUtamaRef, {'status': 'aktif'});

      // --- 4.4 Jalankan semua operasi tulis ---
      await batch.commit();

      Get.snackbar("Berhasil", "$namaSiswa telah diinisialisasi di kelas $namaKelasSaatIni.");

    } catch (e) {
      Get.snackbar('Gagal', e.toString());
    } finally {
      isLoadingTambahKelas.value = false;
    }
  }

  // Future<void> simpanKelasBaruLagi(String namaSiswa, String nisnSiswa) async {
  //   if (kelasTerpilih.value == null) {
  //     Get.snackbar("Gagal", "Kelas belum dipilih.");
  //     return;
  //   }
  //   if (waliKelasSiswaC.text.isEmpty) {
  //     Get.snackbar("Gagal", "Wali kelas belum ditentukan.");
  //     return;
  //   }

  //   isLoadingTambahKelas.value = true;
  //   final String namaKelasSaatIni = kelasTerpilih.value!; 

  //   try {
  //     String tahunajaranya = await getTahunAjaranTerakhir();
  //     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
  //     String kelasNya = namaKelasSaatIni.substring(0, 1);
  //     String faseNya = (kelasNya == '1' || kelasNya == '2') ? "Fase A" : (kelasNya == '3' || kelasNya == '4') ? "Fase B" : "Fase C";
      
  //     CollectionReference<Map<String, dynamic>> colKelas = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran');
  //     DocumentSnapshot<Map<String, dynamic>> docIdKelas = await colKelas.doc(namaKelasSaatIni).get();
      
  //     WriteBatch batch = firestore.batch();
  //     String idwalikelas;
  //     String walikelas;

  //     if (docIdKelas.exists && docIdKelas.data()?['walikelas'] != null) {
  //       walikelas = docIdKelas.data()!['walikelas'];
  //       idwalikelas = docIdKelas.data()!['idwalikelas'];
  //     } else {
  //       walikelas = waliKelasSiswaC.text;
  //       QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').where('alias', isEqualTo: walikelas).get();
  //       if (querySnapshot.docs.isEmpty) throw Exception('Wali kelas "$walikelas" tidak ditemukan.');
  //       idwalikelas = querySnapshot.docs.first.id;
  //     }
      
  //     final kelasDocRef = colKelas.doc(namaKelasSaatIni);
  //     final daftarSiswaDocRef = kelasDocRef.collection('daftarsiswa').doc(nisnSiswa);
  //     final siswaUtamaRef = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(nisnSiswa);
  //     final kelasAktifDocRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelasaktif').doc(namaKelasSaatIni);
  //     final pegawaiTahunAjaranRef = firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idwalikelas).collection('tahunajaran').doc(idTahunAjaran);
  //     final pegawaiKelasnyaRef = pegawaiTahunAjaranRef.collection('kelasnya').doc(namaKelasSaatIni);

  //     final dataKelas = {'namakelas': namaKelasSaatIni, 'fase': faseNya, 'walikelas': walikelas, 'idwalikelas': idwalikelas, 'tahunajaran': tahunajaranya, 'emailpenginput': emailAdmin, 'idpenginput': idUser, 'tanggalinput': FieldValue.serverTimestamp()};
  //     final dataDaftarSiswa = {'namasiswa': namaSiswa, 'nisn': nisnSiswa, 'status': 'aktif', ...dataKelas};
      
  //     batch.set(kelasDocRef, dataKelas, SetOptions(merge: true));
  //     batch.set(daftarSiswaDocRef, dataDaftarSiswa);
  //     batch.set(pegawaiTahunAjaranRef, {'tahunajaran': tahunajaranya}, SetOptions(merge: true));
  //     batch.set(pegawaiKelasnyaRef, {'namakelas': namaKelasSaatIni, 'fase': faseNya});
  //     batch.set(kelasAktifDocRef, {'namakelas': namaKelasSaatIni, 'fase': faseNya}, SetOptions(merge: true));
  //     batch.update(siswaUtamaRef, {'status': 'aktif'});

  //     await batch.commit();
  //     Get.snackbar("Berhasil", "$namaSiswa telah ditambahkan ke kelas $namaKelasSaatIni.");
  //   } catch (e) {
  //     Get.snackbar('Gagal Menambahkan Siswa', e.toString());
  //   } finally {
  //     isLoadingTambahKelas.value = false;
  //   }
  // }
}