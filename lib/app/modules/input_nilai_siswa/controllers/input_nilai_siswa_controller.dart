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

  // Future<void> simpanNilaiHarian(String kategori) async {
  //   int? nilai = int.tryParse(nilaiC.text.trim());
  //   if (nilai == null || nilai > 100 || nilai < 0) {
  //     Get.snackbar("Peringatan", "Nilai harus angka antara 0-100."); return;
  //   }
  //   isSaving.value = true;
  //   try {
  //     await siswaMapelRef.collection('nilai_harian').add({
  //       'kategori': kategori, 'nilai': nilai,
  //       'catatan': catatanC.text, 'tanggal': Timestamp.now(),
  //     });
  //     await fetchNilaiHarian();
  //     hitungNilaiAkhir();
  //     Get.back();
  //   } catch(e) { Get.snackbar("Error", "Gagal menyimpan nilai: $e"); } 
  //   finally { isSaving.value = false; }
  // }

  Future<void> simpanNilaiHarian(String kategori) async {
    int? nilai = int.tryParse(nilaiC.text.trim());
    if (nilai == null || nilai > 100 || nilai < 0) { 
      Get.snackbar("Peringatan", "Nilai harus angka antara 0-100.");
      return; }
    isSaving.value = true;
    try {
      final ref = await siswaMapelRef.collection('nilai_harian').add({
        'kategori': kategori, 'nilai': nilai,
        'catatan': catatanC.text, 'tanggal': Timestamp.now(),
      });

      // --- [TIMELINE] Mencatat event nilai baru ---
      final catatan = catatanC.text.isNotEmpty ? catatanC.text : "Nilai $kategori";
      await _buatCatatanTimeline(
        tipe: 'NILAI_MASUK',
        judul: 'Penilaian Baru: $kategori',
        deskripsi: 'Ananda mendapatkan nilai $nilai untuk "$catatan".',
        refId: ref.id
      );
      // -----------------------------------------

      await fetchNilaiHarian();
      hitungNilaiAkhir();
      Get.back();
    } catch(e) { /* ... */ } 
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
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Apakah Anda yakin ingin menghapus nilai ini?",
      confirm: TextButton(
        onPressed: () async {
          if (Get.isDialogOpen!) Get.back();
          try {
            // Ambil data nilai dulu untuk dicatat di timeline
            final docToDelete = await siswaMapelRef.collection('nilai_harian').doc(idNilai).get();
            // final dataLama = docToDelete.data();

            await siswaMapelRef.collection('nilai_harian').doc(idNilai).delete();
            
            // --- [TIMELINE] Mencatat event penghapusan nilai ---
            // if (dataLama != null) {
            //   final catatan = dataLama['catatan']?.isNotEmpty ?? false ? dataLama['catatan'] : "Nilai ${dataLama['kategori']}";
            //   await _buatCatatanTimeline(
            //     tipe: 'NILAI_DIHAPUS',
            //     judul: 'Nilai Dihapus',
            //     deskripsi: 'Nilai ${dataLama['nilai']} untuk "$catatan" telah dihapus oleh guru.',
            //     refId: idNilai
            //   );
            // }
            // // ----------------------------------------------

            daftarNilaiHarian.removeWhere((nilai) => nilai.id == idNilai);
            hitungNilaiAkhir();
            Get.snackbar("Berhasil", "Nilai telah dihapus.");
          } catch (e) { 
            Get.snackbar("Error", "Gagal menghapus nilai: $e", backgroundColor: Colors.red);
           }
        },
        child: const Text("Ya, Hapus", style: TextStyle(color: Colors.red)),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

/// Memperbarui satu dokumen nilai harian di Firestore.
// Future<void> updateNilaiHarian(String idNilai) async {
//   // Validasi input dari dialog
//   int? nilai = int.tryParse(nilaiC.text.trim());
//   if (nilai == null || nilai < 0 || nilai > 100) {
//     Get.snackbar("Peringatan", "Nilai harus berupa angka antara 0-100.");
//     return;
//   }
  
//   isSaving.value = true;
//   try {
//     // 1. Siapkan data baru
//     final Map<String, dynamic> dataToUpdate = {
//       'nilai': nilai,
//       'catatan': catatanC.text,
//       'tanggal': Timestamp.now(), // Perbarui tanggal modifikasi
//     };

//     // 2. Update dokumen di Firestore
//     await siswaMapelRef.collection('nilai_harian').doc(idNilai).update(dataToUpdate);

//     // 3. Muat ulang semua data nilai harian untuk memastikan konsistensi
//     await fetchNilaiHarian();
    
//     // 4. Hitung ulang nilai akhir
//     hitungNilaiAkhir();
    
//     if (Get.isDialogOpen!) Get.back(); // Tutup dialog input
//     Get.snackbar("Berhasil", "Nilai berhasil diperbarui.", backgroundColor: Colors.green);

//   } catch (e) {
//     Get.snackbar("Error", "Gagal memperbarui nilai: $e", backgroundColor: Colors.red);
//   } finally {
//     isSaving.value = false;
//   }
// }

    Future<void> updateNilaiHarian(String idNilai) async {
    int? nilai = int.tryParse(nilaiC.text.trim());
    if (nilai == null || nilai < 0 || nilai > 100) { 
      Get.snackbar("Peringatan", "Nilai harus berupa angka antara 0-100.");
      return; }
    
    isSaving.value = true;
    try {
      final dataToUpdate = { 'nilai': nilai, 'catatan': catatanC.text, 'tanggal': Timestamp.now() };
      await siswaMapelRef.collection('nilai_harian').doc(idNilai).update(dataToUpdate);

      // --- [TIMELINE] Mencatat event pembaruan nilai ---
      // final catatan = catatanC.text.isNotEmpty ? catatanC.text : "Nilai Harian";
      // await _buatCatatanTimeline(
      //   tipe: 'NILAI_DIPERBARUI',
      //   judul: 'Nilai Diperbarui',
      //   deskripsi: 'Nilai untuk "$catatan" telah diperbarui menjadi $nilai.',
      //   refId: idNilai
      // );
      // -----------------------------------------------

      await fetchNilaiHarian();
      hitungNilaiAkhir();
      if (Get.isDialogOpen!) Get.back();
      Get.snackbar("Berhasil", "Nilai berhasil diperbarui.");
      } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui nilai: $e", backgroundColor: Colors.red);
    } finally {
      isSaving.value = false;
    }
  }

   Future<void> _buatCatatanTimeline({
      required String tipe,
      required String judul,
      required String deskripsi,
      String? refId, // ID dari dokumen asli (nilai/tugas) untuk referensi
      }) async {
        try {
      await siswaMapelRef.collection('timeline_akademik').add({
        'tipe': tipe,
        'judul': judul,
        'deskripsi': deskripsi,
        'tanggal': FieldValue.serverTimestamp(),
        'refId': refId, // Simpan ID untuk kemungkinan navigasi di masa depan
        });
      } catch (e) {
          // Gagal membuat catatan timeline tidak boleh menghentikan alur utama.
          print("Error [Non-Fatal] saat membuat catatan timeline: $e");
          Get.snackbar("Error", "Gagal membuat catatan timeline tidak boleh menghentikan alur utama. $e", backgroundColor: Colors.red);
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