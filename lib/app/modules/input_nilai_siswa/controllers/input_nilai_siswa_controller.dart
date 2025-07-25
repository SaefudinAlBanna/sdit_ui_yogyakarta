import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../modules/home/controllers/home_controller.dart';
import '../../../models/nilai_harian_model.dart';
import '../../../models/tujuan_pembelajaran_model.dart'; // <-- TAMBAHAN: Import model TP
import '../../../models/atp_model.dart'; 

class InputNilaiSiswaController extends GetxController {
  
  // --- DEPENDENSI & DATA DASAR ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  late String idKelas, namaMapel, idSiswa, namaSiswa;
  late String idTahunAjaran, semesterAktif;
  late DocumentReference siswaMapelRef;
  // late CollectionReference tpCollectionRef; // <-- TAMBAHAN: Path ke koleksi Tujuan Pembelajaran

  // --- STATE MANAGEMENT ---
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  // --- STATE HAK AKSES WALI KELAS --
  final RxBool isWaliKelas = false.obs;
  final RxList<Map<String, dynamic>> rekapNilaiMapelLain = <Map<String, dynamic>>[].obs;

  // --- STATE DATA NILAI ---
  final RxList<NilaiHarian> daftarNilaiHarian = <NilaiHarian>[].obs;
  final RxMap<String, int> bobotNilai = <String, int>{}.obs;
  final Rxn<int> nilaiPTS = Rxn<int>();
  final Rxn<int> nilaiPAS = Rxn<int>();
  final Rxn<double> nilaiAkhir = Rxn<double>();

  // --- TAMBAHAN: STATE UNTUK KURIKULUM MERDEKA ---
  final RxBool isLoadingTP = true.obs;
  // Daftar semua TP yang tersedia untuk mapel ini di tahun ajaran ini
  final RxList<TujuanPembelajaranModel> daftarTP = <TujuanPembelajaranModel>[].obs;
  // Menyimpan status capaian TP untuk siswa ini (map dari idTP ke status "Tercapai" / "Perlu Bimbingan")
  final RxMap<String, String> capaianSiswa = <String, String>{}.obs;
  // Controller untuk deskripsi manual jika tidak ada TP
  final TextEditingController deskripsiCapaianC = TextEditingController();


  // --- TEXT EDITING CONTROLLERS ---
  final TextEditingController nilaiC = TextEditingController();
  final TextEditingController catatanC = TextEditingController();
  final TextEditingController harianC = TextEditingController();
  final TextEditingController ulanganC = TextEditingController();
  final TextEditingController ptsC = TextEditingController();
  final TextEditingController pasC = TextEditingController();
  final TextEditingController tambahanC = TextEditingController();

  bool isInitSuccess = false;

  @override
  void onInit() {
    super.onInit();
    final Map<String, dynamic>? args = Get.arguments;
    if (args == null) {
      _handleInitError("Data navigasi tidak ditemukan.");
      return;
    }
    
    idKelas = args['idKelas'] ?? '';
    namaMapel = args['idMapel'] ?? '';
    idSiswa = args['idSiswa'] ?? '';
    namaSiswa = args['namaSiswa'] ?? '';
    
    if (idKelas.isEmpty || namaMapel.isEmpty || idSiswa.isEmpty) {
      _handleInitError("Informasi kelas/mapel/siswa tidak lengkap.");
      return;
    }
    
    idTahunAjaran = homeC.idTahunAjaran.value!;
    semesterAktif = homeC.semesterAktifId.value;

    if (idTahunAjaran.isEmpty || semesterAktif.isEmpty) {
      _handleInitError("Data sesi tahun ajaran belum siap.");
      return;
    }
    
    // Path utama ke "buku rapor" siswa per mapel
    siswaMapelRef = firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').doc(idSiswa)
        .collection('matapelajaran').doc(namaMapel);

    // --- TAMBAHAN: Path ke koleksi Tujuan Pembelajaran ---
    // Diasumsikan struktur ini ada
    // tpCollectionRef = firestore.collection('Sekolah').doc(homeC.idSekolah)
    //     .collection('tahunajaran').doc(idTahunAjaran)
    //     .collection('perangkatajar').doc(namaMapel)
    //     .collection('tujuanpembelajaran');

    isInitSuccess = true;
    loadInitialData();
  }

  @override
  void onClose() {
    harianC.dispose(); ulanganC.dispose(); ptsC.dispose(); pasC.dispose();
    tambahanC.dispose();
    nilaiC.dispose();
    catatanC.dispose();
    deskripsiCapaianC.dispose(); // <-- TAMBAHAN: Dispose controller baru
    super.onClose();
  }
  
  void _handleInitError(String message) {
    isInitSuccess = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar("Error Kritis", message, backgroundColor: Colors.red.shade800, colorText: Colors.white);
      if (Get.key.currentState?.canPop() ?? false) Get.back();
    });
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        fetchBobotNilai(),
        fetchNilaiDanDeskripsiSiswa(), // <-- MODIFIKASI: Mengambil nilai & deskripsi
        fetchNilaiHarian(),
        checkIsWaliKelas(),
        fetchTujuanPembelajaran(), // <-- TAMBAHAN: Ambil data TP
      ]);
      hitungNilaiAkhir();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data awal siswa: $e");
    } finally {
      isLoading.value = false;
    }
  }

  //========================================================================
  // --- FUNGSI PENGAMBILAN DATA (FETCH) ---
  //========================================================================

  Future<void> fetchBobotNilai() async {
    final doc = await firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('penugasan').doc(idKelas)
        .collection('matapelajaran').doc(namaMapel).get();
    if (doc.exists && doc.data()?['bobot_nilai'] != null) {
      bobotNilai.value = Map<String, int>.from(doc.data()!['bobot_nilai']);
    } else {
      bobotNilai.value = {'harian': 20, 'ulangan': 20, 'pts': 20, 'pas': 20, 'tambahan': 20};
    }
  }

  Future<void> fetchNilaiDanDeskripsiSiswa() async {
    final doc = await siswaMapelRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      nilaiPTS.value = data['nilai_pts'];
      nilaiPAS.value = data['nilai_pas'];
      // --- TAMBAHAN: Ambil deskripsi dan capaian TP yang tersimpan ---
      deskripsiCapaianC.text = data['deskripsi_capaian'] ?? '';
      if (data['capaian_tp'] != null) {
        capaianSiswa.value = Map<String, String>.from(data['capaian_tp']);
      }
    }
  }

  Future<void> fetchNilaiHarian() async {
    final snapshot = await siswaMapelRef.collection('nilai_harian').orderBy('tanggal', descending: true).get();
    daftarNilaiHarian.assignAll(snapshot.docs.map((doc) => NilaiHarian.fromFirestore(doc)).toList());
  }

  Future<void> checkIsWaliKelas() async {
    final kelasDoc = await firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(idKelas).get();
    if (kelasDoc.exists && kelasDoc.data()?['idwalikelas'] == homeC.idUser) {
      isWaliKelas.value = true;
      fetchRekapNilaiMapelLain(); 
    }
  }

  //   Future<void> checkIsWaliKelas() async {
//     final kelasDoc = await firestore.collection('Sekolah').doc(homeC.idSekolah)
//         .collection('tahunajaran').doc(idTahunAjaran)
//         .collection('kelastahunajaran').doc(idKelas).get();
    
//     if (kelasDoc.exists) {
//       final idWaliDb = kelasDoc.data()?['idwalikelas'] ?? '';
//       if (idWaliDb == homeC.idUser) {
//         isWaliKelas.value = true;
//         // Jika dia wali kelas, langsung muat rekap nilai mapel lain
//         fetchRekapNilaiMapelLain(); 
//       }
//     }
//   }

  Future<void> fetchRekapNilaiMapelLain() async {
    final snapshot = await siswaMapelRef.parent.get();
    rekapNilaiMapelLain.assignAll(snapshot.docs
        .where((doc) => doc.id != namaMapel)
        .map((doc) => {'mapel': doc.id, 'nilai_akhir': (doc.data() as Map<String, dynamic>)['nilai_akhir'] ?? '-'})
        .toList());
  }
  
  // --- TAMBAHAN: FUNGSI BARU UNTUK MENGAMBIL TP ---
  Future<void> fetchTujuanPembelajaran() async {
    try {
      isLoadingTP.value = true;
      daftarTP.clear(); // Kosongkan daftar sebelum memulai

      // 1. Dapatkan kelas siswa dalam bentuk angka untuk query
      // Misal idKelas adalah "Kelas 7A", kita butuh angka 7 nya.
      // Kita asumsikan format kelas selalu "Angka" atau "AngkaHuruf".
      // Ini adalah contoh parsing sederhana, bisa disesuaikan.
      final kelasAngka = int.tryParse(idKelas.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if(kelasAngka == 0) {
        debugPrint("Tidak bisa parse angka dari idKelas: $idKelas");
        isLoadingTP.value = false;
        return;
      }
      
      // 2. Query koleksi 'atp' untuk menemukan dokumen yang cocok
      final snapshot = await firestore
          .collection('Sekolah').doc(homeC.idSekolah).collection('atp')
          .where('idTahunAjaran', isEqualTo: idTahunAjaran)
          .where('namaMapel', isEqualTo: namaMapel)
          .where('kelas', isEqualTo: kelasAngka)
          .limit(1) // Ambil 1 saja, karena seharusnya hanya ada 1 ATP aktif
          .get();

      // 3. Jika dokumen ATP ditemukan, "bongkar" isinya
      if (snapshot.docs.isNotEmpty) {
        final atpDoc = snapshot.docs.first;
        final atpModel = AtpModel.fromJson(atpDoc.data());

        // 4. "Bongkar" dan gabungkan semua TP dari setiap Unit Pembelajaran
        // `expand` adalah cara elegan untuk mengubah List<List<String>> menjadi List<String>
        final semuaTp = atpModel.unitPembelajaran
            .expand((unit) => unit.tujuanPembelajaran)
            .toList();

        // 5. Konversi List<String> menjadi List<TujuanPembelajaranModel>
        // Ini agar bisa digunakan oleh View yang sudah ada tanpa banyak perubahan.
        // Kita gunakan string TP itu sendiri sebagai ID dan Deskripsi.
        daftarTP.assignAll(semuaTp.map(
          (tpString) => TujuanPembelajaranModel(id: tpString, deskripsi: tpString)
        ).toList());
      }
      // Jika tidak ditemukan, daftarTP akan tetap kosong, 
      // dan UI akan otomatis menampilkan input manual.
      
    } catch (e) {
      Get.snackbar("Info", "Gagal memuat Tujuan Pembelajaran dari ATP: $e");
      debugPrint("Error fetchTujuanPembelajaran: $e");
    } finally {
      isLoadingTP.value = false;
    }
  }

  //========================================================================
  // --- FUNGSI SIMPAN & HITUNG (LOGIKA INTI) ---
  //========================================================================

  Future<void> simpanBobotNilai() async {
    final Map<String, int> bobotBaru = {
      'harian': int.tryParse(harianC.text) ?? 0, 'ulangan': int.tryParse(ulanganC.text) ?? 0,
      'pts': int.tryParse(ptsC.text) ?? 0, 'pas': int.tryParse(pasC.text) ?? 0,
      'tambahan': int.tryParse(tambahanC.text) ?? 0,
    };
    if (bobotBaru.values.reduce((a, b) => a + b) != 100) {
      Get.snackbar("Peringatan", "Total bobot harus 100%.");
      return;
    }

    isSaving.value = true;
    try {
      final ref = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tahunajaran')
          .doc(idTahunAjaran).collection('penugasan').doc(idKelas).collection('matapelajaran').doc(namaMapel);
      await ref.set({'bobot_nilai': bobotBaru}, SetOptions(merge: true));
      Get.back();
      Get.snackbar("Berhasil", "Bobot nilai telah disimpan.");
      await fetchBobotNilai();
      hitungNilaiAkhir();
    } catch (e) { Get.snackbar("Error", "Gagal menyimpan bobot: $e"); } 
    finally { isSaving.value = false; }
  }

  Future<void> simpanNilaiHarian(String kategori) async {
    int? nilai = int.tryParse(nilaiC.text.trim());
    if (nilai == null || nilai > 100 || nilai < 0) {
      Get.snackbar("Peringatan", "Nilai harus angka antara 0-100."); return;
    }
    isSaving.value = true;
    try {
      await siswaMapelRef.collection('nilai_harian').add({
        'kategori': kategori, 'nilai': nilai,
        'catatan': catatanC.text, 'tanggal': Timestamp.now(),
      });
      await fetchNilaiHarian();
      hitungNilaiAkhir();
      Get.back();
    } catch(e) { Get.snackbar("Error", "Gagal menyimpan nilai: $e"); } 
    finally { isSaving.value = false; }
  }

  Future<void> simpanNilaiUtama(String jenisNilai) async {
    int? nilai = int.tryParse(nilaiC.text.trim());
    if (nilai == null || nilai > 100 || nilai < 0) {
      Get.snackbar("Peringatan", "Nilai harus angka antara 0-100."); return;
    }
    isSaving.value = true;
    try {
      await siswaMapelRef.set({jenisNilai: nilai}, SetOptions(merge: true));
      await fetchNilaiDanDeskripsiSiswa();
      hitungNilaiAkhir();
      Get.back();
    } catch(e) { Get.snackbar("Error", "Gagal menyimpan nilai: $e"); }
    finally { isSaving.value = false; }
  }
  
  // --- TAMBAHAN: FUNGSI BARU UNTUK MENYIMPAN CAPAIAN ---
  
  /// Menyimpan status capaian untuk satu Tujuan Pembelajaran.
  Future<void> simpanCapaianTP(String idTP, String status) async {
    capaianSiswa[idTP] = status;
    try {
      // Tidak ada perubahan di sini, karena 'capaian_tp' adalah map,
      // dan kita sudah menggunakan ID TP (yaitu string TP itu sendiri) sebagai key.
      await siswaMapelRef.set({
        'capaian_tp': {idTP: status}
      }, SetOptions(merge: true));
    } catch (e) {
      capaianSiswa.remove(idTP);
      Get.snackbar("Error", "Gagal menyimpan capaian: $e");
    }
  }

  Future<void> deleteNilaiHarian(String idNilai) async {
  // Tampilkan dialog konfirmasi untuk mencegah salah hapus
  Get.defaultDialog(
    title: "Konfirmasi Hapus",
    middleText: "Apakah Anda yakin ingin menghapus nilai ini secara permanen?",
    confirm: TextButton(
      style: TextButton.styleFrom(backgroundColor: Colors.red),
      onPressed: () async {
        if (Get.isDialogOpen!) Get.back(); // Tutup dialog konfirmasi

        try {
          // 1. Hapus dokumen dari Firestore
          await siswaMapelRef.collection('nilai_harian').doc(idNilai).delete();
          
          // 2. Hapus dari state lokal agar UI langsung update
          daftarNilaiHarian.removeWhere((nilai) => nilai.id == idNilai);

          // 3. Hitung ulang nilai akhir
          hitungNilaiAkhir();
          
          Get.snackbar("Berhasil", "Nilai telah dihapus.", backgroundColor: Colors.green);
        } catch (e) {
          Get.snackbar("Error", "Gagal menghapus nilai: $e", backgroundColor: Colors.red);
        }
      },
      child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
    ),
    cancel: TextButton(
      onPressed: () => Get.back(),
      child: const Text("Batal"),
    ),
  );
}

/// Memperbarui satu dokumen nilai harian di Firestore.
Future<void> updateNilaiHarian(String idNilai) async {
  // Validasi input dari dialog
  int? nilai = int.tryParse(nilaiC.text.trim());
  if (nilai == null || nilai < 0 || nilai > 100) {
    Get.snackbar("Peringatan", "Nilai harus berupa angka antara 0-100.");
    return;
  }
  
  isSaving.value = true;
  try {
    // 1. Siapkan data baru
    final Map<String, dynamic> dataToUpdate = {
      'nilai': nilai,
      'catatan': catatanC.text,
      'tanggal': Timestamp.now(), // Perbarui tanggal modifikasi
    };

    // 2. Update dokumen di Firestore
    await siswaMapelRef.collection('nilai_harian').doc(idNilai).update(dataToUpdate);

    // 3. Muat ulang semua data nilai harian untuk memastikan konsistensi
    await fetchNilaiHarian();
    
    // 4. Hitung ulang nilai akhir
    hitungNilaiAkhir();
    
    if (Get.isDialogOpen!) Get.back(); // Tutup dialog input
    Get.snackbar("Berhasil", "Nilai berhasil diperbarui.", backgroundColor: Colors.green);

  } catch (e) {
    Get.snackbar("Error", "Gagal memperbarui nilai: $e", backgroundColor: Colors.red);
  } finally {
    isSaving.value = false;
  }
}

  /// Menyimpan deskripsi capaian manual.
  Future<void> simpanDeskripsiCapaian() async {
  // --- TAMBAHAN VALIDASI DIMULAI ---
  if (deskripsiCapaianC.text.trim().isEmpty) {
    Get.snackbar(
      "Peringatan",
      "Deskripsi capaian tidak boleh kosong.",
      backgroundColor: Colors.orange.shade800,
      colorText: Colors.white,
    );
    return; // Hentikan eksekusi fungsi jika kosong
  }
  // --- AKHIR VALIDASI ---

  isSaving.value = true;
  try {
    await siswaMapelRef.set({
      'deskripsi_capaian': deskripsiCapaianC.text
    }, SetOptions(merge: true));
    Get.snackbar(
      "Berhasil", 
      "Deskripsi capaian telah disimpan.",
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
    );
  } catch (e) {
    Get.snackbar("Error", "Gagal menyimpan deskripsi: $e");
  } finally {
    isSaving.value = false;
  }
}


  /// [FUNGSI AJAIB] Menghitung nilai akhir berdasarkan semua data yang ada.
  void hitungNilaiAkhir() {
    if (bobotNilai.isEmpty) return;
    double avgHarian = _calculateAverage("Harian/PR");
    double avgUlangan = _calculateAverage('Ulangan Harian');
    double totalTambahan = _calculateSum('Nilai Tambahan');
    int pts = nilaiPTS.value ?? 0;
    int pas = nilaiPAS.value ?? 0;
    
    int bobotHarian = bobotNilai['harian'] ?? 0;
    int bobotUlangan = bobotNilai['ulangan'] ?? 0;
    int bobotPts = bobotNilai['pts'] ?? 0;
    int bobotPas = bobotNilai['pas'] ?? 0;
    int bobotTambahan = bobotNilai['tambahan'] ?? 0;

    double finalScore = 
      (avgHarian * bobotHarian) +
      (avgUlangan * bobotUlangan) +
      (pts * bobotPts) +
      (pas * bobotPas) +
      (totalTambahan * bobotTambahan);

    // Pastikan total bobot tidak 0 untuk menghindari pembagian dengan nol
    int totalBobot = bobotHarian + bobotUlangan + bobotPts + bobotPas + bobotTambahan;
    if (totalBobot == 0) {
      nilaiAkhir.value = 0;
    } else {
      nilaiAkhir.value = finalScore / totalBobot;
    }

    // Otomatis simpan nilai akhir ke Firestore setiap ada perubahan
    siswaMapelRef.set({'nilai_akhir': nilaiAkhir.value}, SetOptions(merge: true));
  }
  
  double _calculateAverage(String kategori) {
    var listNilai = daftarNilaiHarian.where((n) {
      if (kategori == "Harian/PR") return n.kategori == "Harian/PR" || n.kategori == "PR";
      return n.kategori == kategori;
    }).toList();
    if (listNilai.isEmpty) return 0;
    return listNilai.fold(0, (sum, item) => sum + item.nilai) / listNilai.length;
  }

  double _calculateSum(String kategori) {
    var listNilai = daftarNilaiHarian.where((n) => n.kategori == kategori).toList();
    if (listNilai.isEmpty) return 0;
    return listNilai.fold(0, (sum, item) => sum + item.nilai).toDouble();
  }
}

// // lib/app/modules/input_nilai_siswa/controllers/input_nilai_siswa_controller.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../modules/home/controllers/home_controller.dart';
// import '../../../models/nilai_harian_model.dart'; // <-- Kita akan buat model ini nanti

// class InputNilaiSiswaController extends GetxController {
  
//   // --- DEPENDENSI & DATA DASAR ---
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final HomeController homeC = Get.find<HomeController>();
//   late String idKelas, namaMapel, idSiswa, namaSiswa;
//   late String idTahunAjaran, semesterAktif;
//   late DocumentReference siswaMapelRef; // Path utama ke buku rapor siswa

//   // --- STATE MANAGEMENT ---
//   final RxBool isLoading = true.obs;
//   final RxBool isSaving = false.obs;

//  // --- STATE BARU UNTUK HAK AKSES WALI KELAS --
//   final RxBool isWaliKelas = false.obs;
//   // Menyimpan rekap semua nilai akhir jika user adalah wali kelas
//   final RxList<Map<String, dynamic>> rekapNilaiMapelLain = <Map<String, dynamic>>[].obs;

//   // State untuk menyimpan data nilai
//   final RxList<NilaiHarian> daftarNilaiHarian = <NilaiHarian>[].obs;
//   final RxMap<String, int> bobotNilai = <String, int>{}.obs;
  
//   // State untuk nilai utama
//   final Rxn<int> nilaiPTS = Rxn<int>();
//   final Rxn<int> nilaiPAS = Rxn<int>();
//   final Rxn<double> nilaiAkhir = Rxn<double>(); // Nilai rapor

//   // --- TEXT EDITING CONTROLLERS UNTUK DIALOG ---
//   final TextEditingController nilaiC = TextEditingController();
//   final TextEditingController catatanC = TextEditingController();

//   // --- TEXT EDITING CONTROLLERS UNTUK BOBOT NILAI ---
//   final TextEditingController harianC = TextEditingController();
//   final TextEditingController ulanganC = TextEditingController();
//   final TextEditingController ptsC = TextEditingController();
//   final TextEditingController pasC = TextEditingController();
//   final TextEditingController tambahanC = TextEditingController();

//   bool isInitSuccess = false;

//    @override
//   void onInit() {
//     super.onInit();
//     // nilaiC = TextEditingController();
//     // catatanC = TextEditingController();

//     // --- BLOK DEBUGGING DIMULAI ---
//     debugPrint("=========================================");
//     debugPrint("[DEBUG] onInit InputNilaiSiswaController");

//     final Map<String, dynamic>? args = Get.arguments;

//     if (args == null) {
//       debugPrint("   -> HASIL: Gagal, Get.arguments adalah null.");
//       _handleInitError("Data navigasi tidak ditemukan (args null).");
//       debugPrint("=========================================");
//       return;
//     }
    
//     // Cetak semua argumen yang diterima
//     debugPrint("   -> Argumen yang diterima: $args");
    
//     idKelas = args['idKelas'] ?? '';
//     namaMapel = args['idMapel'] ?? '';
//     idSiswa = args['idSiswa'] ?? '';
//     namaSiswa = args['namaSiswa'] ?? '';
    
//     debugPrint("   -> idKelas: '$idKelas'");
//     debugPrint("   -> namaMapel: '$namaMapel'");
//     debugPrint("   -> idSiswa: '$idSiswa'");
//     debugPrint("   -> namaSiswa: '$namaSiswa'");
    
//     // Periksa apakah ada argumen penting yang kosong
//     if (idKelas.isEmpty || namaMapel.isEmpty || idSiswa.isEmpty) {
//       debugPrint("   -> HASIL: Gagal, salah satu argumen penting kosong.");
//       _handleInitError("Informasi kelas/mapel/siswa tidak lengkap.");
//       debugPrint("=========================================");
//       return;
//     }
    
//     final idTahunAjaranDariHome = homeC.idTahunAjaran.value;
//     final semesterAktifDariHome = homeC.semesterAktifId.value;

//     if (idTahunAjaranDariHome == null || semesterAktifDariHome.isEmpty) {
//       debugPrint("   -> HASIL: Gagal, data dari HomeController belum siap.");
//       _handleInitError("Data sesi belum siap. Silakan coba lagi.");
//       debugPrint("=========================================");
//       return;
//     }
    
//     idTahunAjaran = idTahunAjaranDariHome;
//     semesterAktif = semesterAktifDariHome;
//     isInitSuccess = true;
//     debugPrint("   -> HASIL: Inisialisasi BERHASIL.");
//     debugPrint("=========================================");

//     siswaMapelRef = firestore.collection('Sekolah').doc(homeC.idSekolah)
//         .collection('tahunajaran').doc(idTahunAjaran)
//         .collection('kelastahunajaran').doc(idKelas)
//         .collection('semester').doc(semesterAktif)
//         .collection('daftarsiswa').doc(idSiswa)
//         .collection('matapelajaran').doc(namaMapel);
    
//     loadInitialData();
//   }

//   @override
//   void onClose() {
//     // Selalu dispose controller
//     harianC.dispose(); ulanganC.dispose(); ptsC.dispose(); pasC.dispose();
//     tambahanC.dispose();
//     nilaiC.dispose();
//     catatanC.dispose();
//     super.onClose();
//   }

//   Future<void> simpanBobotNilai() async {
//     final Map<String, int> bobotBaru = {
//       'harian': int.tryParse(harianC.text) ?? 0,
//       'ulangan': int.tryParse(ulanganC.text) ?? 0,
//       'pts': int.tryParse(ptsC.text) ?? 0,
//       'pas': int.tryParse(pasC.text) ?? 0,
//       'tambahan': int.tryParse(tambahanC.text) ?? 0,
//     };
    
//     int totalBobot = bobotBaru.values.reduce((a, b) => a + b);
//     if (totalBobot > 100) { // Beri toleransi jika total kurang, tapi tidak boleh lebih
//       Get.snackbar("Peringatan", "Total bobot tidak boleh melebihi 100%. Saat ini totalnya $totalBobot%.");
//       return;
//     }

//     isSaving.value = true;
//     try {
//       // Path ke dokumen penugasan, tempat bobot disimpan
//       final ref = firestore.collection('Sekolah').doc(homeC.idSekolah)
//           .collection('tahunajaran').doc(idTahunAjaran)
//           .collection('penugasan').doc(idKelas)
//           .collection('matapelajaran').doc(namaMapel);

//       await ref.set({'bobot_nilai': bobotBaru}, SetOptions(merge: true));
//       Get.back(); // Tutup dialog
//       Get.snackbar("Berhasil", "Bobot nilai telah disimpan.");
//       // Muat ulang data bobot dan hitung ulang nilai akhir
//       await fetchBobotNilai();
//       hitungNilaiAkhir();
//     } catch (e) { Get.snackbar("Error", "Gagal menyimpan bobot: $e"); }
//     finally { isSaving.value = false; }
//   }

//   void _handleInitError(String message) {
//     isInitSuccess = false;
//     // Tunda aksi UI hingga setelah build frame pertama selesai
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Get.snackbar("Error Kritis", message);
//       if (Get.key.currentState?.canPop() ?? false) {
//         Get.back();
//       }
//     });
//   }

//   /// Memuat semua data yang diperlukan secara bersamaan.
//   Future<void> loadInitialData() async {
//     try {
//       isLoading.value = true;
//       await Future.wait([
//         fetchBobotNilai(),
//         fetchNilaiUtama(),
//         fetchNilaiHarian(),
//         checkIsWaliKelas(),
//       ]);
//       // Setelah semua data dimuat, langsung hitung nilai akhir
//       hitungNilaiAkhir();
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat data nilai siswa: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   //========================================================================
//   // --- FUNGSI PENGAMBILAN DATA (FETCH) ---
//   //========================================================================

//   Future<void> checkIsWaliKelas() async {
//     final kelasDoc = await firestore.collection('Sekolah').doc(homeC.idSekolah)
//         .collection('tahunajaran').doc(idTahunAjaran)
//         .collection('kelastahunajaran').doc(idKelas).get();
    
//     if (kelasDoc.exists) {
//       final idWaliDb = kelasDoc.data()?['idwalikelas'] ?? '';
//       if (idWaliDb == homeC.idUser) {
//         isWaliKelas.value = true;
//         // Jika dia wali kelas, langsung muat rekap nilai mapel lain
//         fetchRekapNilaiMapelLain(); 
//       }
//     }
//   }

//   Future<void> fetchRekapNilaiMapelLain() async {
//     // Fungsi ini hanya dijalankan jika user adalah wali kelas
//     rekapNilaiMapelLain.clear();
//     final snapshot = await siswaMapelRef.parent.get(); // .parent akan mengambil semua mapel
    
//     List<Map<String, dynamic>> rekap = [];
//     for (var doc in snapshot.docs) {
//       // Jangan tampilkan mapel yang sedang dibuka saat ini di daftar rekap
//       if (doc.id != namaMapel) {
//         rekap.add({
//           'mapel': doc.id,
//           'nilai_akhir': (doc.data() as Map<String, dynamic>)['nilai_akhir'] ?? '-',
//         });
//       }
//     }
//     rekapNilaiMapelLain.assignAll(rekap);
//   }

//   Future<void> fetchBobotNilai() async {
//     // Mengambil data bobot dari koleksi 'penugasan'
//     final doc = await firestore.collection('Sekolah').doc(homeC.idSekolah)
//         .collection('tahunajaran').doc(idTahunAjaran)
//         .collection('penugasan').doc(idKelas)
//         .collection('matapelajaran').doc(namaMapel).get();
//     if (doc.exists && doc.data()?['bobot_nilai'] != null) {
//       bobotNilai.value = Map<String, int>.from(doc.data()!['bobot_nilai']);
//     } else {
//       // Bobot default jika tidak diatur
//       bobotNilai.value = {'harian': 20, 'ulangan': 20, 'pts': 20, 'pas': 20, 'tambahan': 20};
//     }
//   }

//   Future<void> fetchNilaiUtama() async {
//     final doc = await siswaMapelRef.get();
//     if (doc.exists && doc.data() != null) {
//       final data = doc.data()! as Map<String, dynamic>;
//       nilaiPTS.value = data['nilai_pts'];
//       nilaiPAS.value = data['nilai_pas'];
//     }
//   }

//   Future<void> fetchNilaiHarian() async {
//     final snapshot = await siswaMapelRef.collection('nilai_harian').orderBy('tanggal', descending: true).get();
//     daftarNilaiHarian.assignAll(snapshot.docs.map((doc) => NilaiHarian.fromFirestore(doc)).toList());
//   }

//   //========================================================================
//   // --- FUNGSI SIMPAN & HITUNG (LOGIKA INTI) ---
//   //========================================================================

//   /// Menyimpan nilai untuk kategori Harian, Ulangan, atau Tambahan.
//   Future<void> simpanNilaiHarian(String kategori) async {
//     if (nilaiC.text.isEmpty) { Get.snackbar("Peringatan", "Nilai tidak boleh kosong."); return; }
//     isSaving.value = true;
//     try {

//       int? nilai = int.tryParse(nilaiC.text.trim());
//       if (nilai == null) { Get.snackbar("Peringatan", "Nilai harus berupa angka."); return; }
//       if (nilai > 100) { Get.snackbar("Peringatan", "Nilai maksimal adalah 100."); return; }

//       await siswaMapelRef.collection('nilai_harian').add({
//         'kategori': kategori,
//         'nilai': int.parse(nilaiC.text),
//         'catatan': catatanC.text,
//         'tanggal': Timestamp.now(),
//       });
//       await fetchNilaiHarian(); // Ambil ulang daftar nilai harian
//       hitungNilaiAkhir();   // Hitung ulang nilai akhir
//       Get.back(); // Tutup dialog
//     } catch(e) { Get.snackbar("Error", "Gagal menyimpan nilai: $e"); } 
//     finally { isSaving.value = false; }
//   }

//   /// Menyimpan nilai PTS atau PAS.
//   Future<void> simpanNilaiUtama(String jenisNilai) async { // jenisNilai: 'nilai_pts' atau 'nilai_pas'
//     if (nilaiC.text.isEmpty) { Get.snackbar("Peringatan", "Nilai tidak boleh kosong."); return; }
//     isSaving.value = true;
//     try {

//       int? nilai = int.tryParse(nilaiC.text.trim());
//       if (nilai == null) { Get.snackbar("Peringatan", "Nilai harus berupa angka."); return; }
//       if (nilai > 100) { Get.snackbar("Peringatan", "Nilai maksimal adalah 100."); return; }

//       await siswaMapelRef.set({
//         jenisNilai: int.parse(nilaiC.text)
//       }, SetOptions(merge: true)); // merge:true agar tidak menimpa nilai lain
      
//       await fetchNilaiUtama(); // Ambil ulang nilai PTS/PAS
//       hitungNilaiAkhir();   // Hitung ulang nilai akhir
//       Get.back();
//     } catch(e) { Get.snackbar("Error", "Gagal menyimpan nilai: $e"); }
//     finally { isSaving.value = false; }
//   }

//   /// [FUNGSI AJAIB] Menghitung nilai akhir berdasarkan semua data yang ada.
//   void hitungNilaiAkhir() {
//     if (bobotNilai.isEmpty) return;

//     // Hitung rata-rata untuk setiap kategori
//     double avgHarian = _calculateAverage('Harian/PR');
//     double avgUlangan = _calculateAverage('Ulangan Harian');
//     double totalTambahan = _calculateSum('Nilai Tambahan'); // Nilai tambahan biasanya dijumlah

//     // Ambil nilai PTS dan PAS, anggap 0 jika null
//     int pts = nilaiPTS.value ?? 0;
//     int pas = nilaiPAS.value ?? 0;

//     // Ambil bobot, anggap 0 jika null
//     int bobotHarian = bobotNilai['harian'] ?? 0;
//     int bobotUlangan = bobotNilai['ulangan'] ?? 0;
//     int bobotPts = bobotNilai['pts'] ?? 0;
//     int bobotPas = bobotNilai['pas'] ?? 0;
//     int bobotTambahan = bobotNilai['tambahan'] ?? 0;

//     // Hitung nilai akhir
//     double finalScore = 
//       (avgHarian * (bobotHarian / 100)) +
//       (avgUlangan * (bobotUlangan / 100)) +
//       (pts * (bobotPts / 100)) +
//       (pas * (bobotPas / 100)) +
//       (totalTambahan * (bobotTambahan / 100)); // Biasanya bobot tambahan kecil

//     nilaiAkhir.value = finalScore;

//     // Simpan nilai akhir ke Firestore (opsional, tapi sangat direkomendasikan)
//     siswaMapelRef.set({'nilai_akhir': finalScore}, SetOptions(merge: true));
//   }
  
//   // Helper untuk menghitung rata-rata
//   // double _calculateAverage(String kategori) {
//   //   final listNilai = daftarNilaiHarian.where((n) => n.kategori == kategori).toList();
//   //   if (listNilai.isEmpty) return 0;
//   //   final total = listNilai.fold(0, (sum, item) => sum + item.nilai);
//   //   return total / listNilai.length;
//   // }

//   // --Perbaikan
//    double _calculateAverage(String kategori) {
//     List<NilaiHarian> listNilai;
//     if (kategori == "Harian/PR") {
//       // Ambil semua nilai yang kategorinya "Harian/PR" ATAU "PR"
//       listNilai = daftarNilaiHarian.where((n) => n.kategori == "Harian/PR" || n.kategori == "PR").toList();
//     } else {
//       listNilai = daftarNilaiHarian.where((n) => n.kategori == kategori).toList();
//     }
    
//     if (listNilai.isEmpty) return 0;
//     final total = listNilai.fold(0, (sum, item) => sum + item.nilai);
//     return total / listNilai.length;
//   }

//   // Helper untuk menjumlahkan nilai
//   double _calculateSum(String kategori) {
//     final listNilai = daftarNilaiHarian.where((n) => n.kategori == kategori).toList();
//     if (listNilai.isEmpty) return 0;
//     return listNilai.fold(0, (sum, item) => (sum + item.nilai).toDouble());
//   }
// }