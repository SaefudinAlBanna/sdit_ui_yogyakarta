import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../modules/home/controllers/home_controller.dart';

class DaftarSiswaPermapelController extends GetxController {
  
  // --- DEPENDENSI & ARGUMEN ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  late String idKelas;
  late String namaMapel;
  
  // --- STATE TAMPILAN UTAMA ---
  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> daftarSiswa = <Map<String, dynamic>>[].obs;
  final RxString appBarTitle = "Memuat...".obs;

  // --- STATE UNTUK DIALOG/BOTTOMSHEET ---
  final RxBool isDialogLoading = false.obs;
  
  // State untuk "Buat Tugas/Ulangan"
  final TextEditingController judulTugasC = TextEditingController();
  final TextEditingController deskripsiTugasC = TextEditingController();

  // State untuk "Input Nilai Massal"
  final Rxn<String> tugasTerpilihId = Rxn<String>();
  final TextEditingController nilaiMassalC = TextEditingController();
  final TextEditingController catatanNilaiC = TextEditingController();
  final RxList<String> siswaTerpilihUntukNilai = <String>[].obs;

  final RxBool isWaliKelas = false.obs;

  @override
  void onInit() {
    super.onInit();
    final Map<String, dynamic> args = Get.arguments;
    idKelas = args['idKelas'];
    namaMapel = args['namaMapel'];
    appBarTitle.value = '$namaMapel - $idKelas';
    fetchSiswaDanNilai();
    fetchDataSiswa();
    _checkIsWaliKelas(); 
  }
  
  @override
  void onClose() {
    judulTugasC.dispose(); deskripsiTugasC.dispose();
    nilaiMassalC.dispose(); catatanNilaiC.dispose();
    super.onClose();
  }

  Future<void> _checkIsWaliKelas() async {
  try {
    // 1. Ambil dokumen kelas dari Firestore
    final String idTahunAjaran = homeC.idTahunAjaran.value!;
    final kelasDoc = await firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .get();

    if (kelasDoc.exists) {
      // 2. Bandingkan ID wali kelas di dokumen dengan ID pengguna yang login
      final idWaliDb = kelasDoc.data()?['idwalikelas'] ?? '';
      if (idWaliDb == homeC.idUser) {
        isWaliKelas.value = true;
      } else {
        isWaliKelas.value = false;
      }
    }
  } catch (e) {
    // Jika ada error, anggap bukan wali kelas
    isWaliKelas.value = false;
    print("Error saat cek wali kelas: $e");
  }
 }

   Future<void> fetchSiswaDanNilai() async {
    // ... (Logika ini akan kita implementasikan setelah input nilai selesai)
    // Untuk sekarang, kita fokus pada pengambilan daftar siswa saja.
    try {
      isLoading.value = true;
      String idTahunAjaran = homeC.idTahunAjaran.value!;
      String semesterAktif = homeC.semesterAktifId.value;

      final snapshot = await firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(idKelas)
          .collection('semester').doc(semesterAktif).collection('daftarsiswa').get();

      if (snapshot.docs.isNotEmpty) {
        final listSiswa = snapshot.docs.map((doc) {
          var data = doc.data();
          data['idSiswa'] = doc.id;
          return data;
        }).toList();
        daftarSiswa.assignAll(listSiswa);
      }
    } catch (e) { Get.snackbar("Error", "Gagal mengambil data siswa: $e"); } 
    finally { isLoading.value = false; }
  }

  //========================================================================
  // --- LOGIKA UNTUK TUGAS & ULANGAN (FITUR BARU) ---
  //========================================================================

  /// [BARU] Menyimpan tugas/ulangan baru ke "papan pengumuman" kelas.
  Future<void> buatTugasBaru(String kategori) async {
    if (judulTugasC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Judul tidak boleh kosong."); return;
    }
    isDialogLoading.value = true;
    try {
      String kategoriDisimpan = (kategori == "PR") ? "Harian/PR" : kategori;
      final ref = await _getTugasUlanganCollectionRef();
      await ref.add({
        'judul': judulTugasC.text.trim(),
        // 'kategori': kategori, // "PR" atau "Ulangan Harian"
        'kategori': kategoriDisimpan, // "PR" atau "Ulangan Harian"
        'deskripsi': deskripsiTugasC.text.trim(),
        'tanggal_dibuat': Timestamp.now(),
        'status': 'diumumkan',
        'namaMapel': namaMapel,
      });
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "$kategori baru telah dibuat.");
    } catch(e) { Get.snackbar("Error", "Gagal membuat tugas: $e"); } 
    finally { isDialogLoading.value = false; judulTugasC.clear(); deskripsiTugasC.clear(); }
  }

  /// [BARU] Mengambil daftar tugas/ulangan yang belum dinilai untuk dropdown.
  Future<List<Map<String, dynamic>>> getTugasUntukDinilai() async {
    try {
      final ref = await _getTugasUlanganCollectionRef();
      final snapshot = await ref
          .where('namaMapel', isEqualTo: namaMapel)
          .where('status', isEqualTo: 'diumumkan')
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'judul': doc.data()['judul'] ?? 'Tanpa Judul',
        'kategori': doc.data()['kategori'] ?? 'Lainnya',
      }).toList();
    } catch(e) {
      Get.snackbar("Error", "Gagal memuat daftar tugas: $e");
      return [];
    }
  }

  /// [BARU] Mengelola checkbox siswa saat input nilai massal.
  void toggleSiswaSelection(String nisn) {
    if (siswaTerpilihUntukNilai.contains(nisn)) {
      siswaTerpilihUntukNilai.remove(nisn);
    } else {
      siswaTerpilihUntukNilai.add(nisn);
    }
  }

  /// [BARU] Menyimpan nilai massal untuk tugas yang dipilih.
  Future<void> simpanNilaiMassal() async {
    // 1. Validasi Input Awal
    if (tugasTerpilihId.value == null) { Get.snackbar("Peringatan", "Pilih tugas/ulangan terlebih dahulu."); return; }
    if (nilaiMassalC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Nilai wajib diisi."); return; }
    if (siswaTerpilihUntukNilai.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu siswa."); return; }
    
    // Validasi nilai harus berupa angka dan tidak lebih dari 100
    int? nilai = int.tryParse(nilaiMassalC.text.trim());
    if (nilai == null) { Get.snackbar("Peringatan", "Nilai harus berupa angka."); return; }
    if (nilai > 100) { Get.snackbar("Peringatan", "Nilai maksimal adalah 100."); return; }

    isDialogLoading.value = true;
    try {
      final batch = firestore.batch();
      
      // 2. Ambil Dokumen Tugas untuk Mendapatkan Kategori
      final refTugas = (await _getTugasUlanganCollectionRef()).doc(tugasTerpilihId.value!);
      final docTugas = await refTugas.get();
      if (!docTugas.exists) {
        throw Exception("Dokumen tugas/ulangan tidak ditemukan.");
      }
      // --- KUNCI PERBAIKAN ADA DI SINI ---
      final String kategoriTugas = docTugas.data()?['kategori'] ?? 'Lainnya';
      // ------------------------------------

      // 3. Loop untuk setiap siswa yang terpilih
      for (String nisn in siswaTerpilihUntukNilai) {
        final refNilai = (await _getSiswaMapelRef(nisn)).collection('nilai_harian').doc(); // ID otomatis

        // Tambahkan 'kategori' ke dalam data yang akan disimpan
        batch.set(refNilai, {
          'id_tugas_ulangan': tugasTerpilihId.value,
          'nilai': nilai, // Gunakan nilai yang sudah divalidasi
          'catatan': catatanNilaiC.text.trim(),
          'tanggal': Timestamp.now(),
          'kategori': kategoriTugas, // <-- SIMPAN KATEGORI DI SINI
        });
        
        // Di sini kita bisa panggil fungsi terpisah untuk memicu perhitungan ulang
        // await hitungUlangNilaiAkhir(nisn); // (Ini bisa jadi fitur selanjutnya)
      }

      // 4. Update status tugas menjadi "selesai_dinilai"
      batch.update(refTugas, {'status': 'selesai_dinilai'});

      await batch.commit();

      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "Nilai berhasil disimpan.");
      
      // Panggil fetchSiswaDanNilai() untuk me-refresh tampilan nilai akhir di halaman ini
      fetchSiswaDanNilai(); 
      
    } catch(e) {
      Get.snackbar("Error", "Gagal menyimpan nilai: ${e.toString()}");
    } finally {
      isDialogLoading.value = false;
      // Kosongkan state setelah selesai
      tugasTerpilihId.value = null;
      nilaiMassalC.clear();
      catatanNilaiC.clear();
      siswaTerpilihUntukNilai.clear();
    }
  }

  /// [FINAL] Mengambil daftar siswa DAN nilai akhir mereka untuk mapel ini.
  Future<void> fetchDataSiswa() async {
    try {
      isLoading.value = true;
      daftarSiswa.clear();

      String idTahunAjaran = homeC.idTahunAjaran.value!;
      String semesterAktif = homeC.semesterAktifId.value;
      String idSekolah = homeC.idSekolah;
      
      // Langkah 1: Ambil daftar siswa dasar dari path semester
      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('semester').doc(semesterAktif)
          .collection('daftarsiswa')
          .orderBy('namasiswa') // Urutkan berdasarkan nama
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Langkah 2: Proses setiap siswa untuk mendapatkan nilai akhirnya
        List<Future<Map<String, dynamic>>> futures = snapshot.docs.map((docSiswa) async {
          var dataSiswa = docSiswa.data();
          dataSiswa['idSiswa'] = docSiswa.id;

          // --- KUNCI PERBAIKAN DI SINI ---
          // Path ke "buku rapor" siswa untuk mapel ini.
          final mapelDocRef = docSiswa.reference
              .collection('matapelajaran').doc(namaMapel);
          // -----------------------------
          
          final mapelDoc = await mapelDocRef.get();
          
          if (mapelDoc.exists && mapelDoc.data() != null) {
            dataSiswa['nilai_akhir'] = mapelDoc.data()!['nilai_akhir'];
          } else {
            dataSiswa['nilai_akhir'] = null; // Pastikan null jika belum ada
          }
          
          return dataSiswa;
        }).toList();

        // Langkah 3: Tunggu semua data nilai selesai diambil
        final listSiswaLengkap = await Future.wait(futures);
        daftarSiswa.assignAll(listSiswaLengkap);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil data siswa: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- HELPER PATH ---
  Future<CollectionReference<Map<String, dynamic>>> _getTugasUlanganCollectionRef() async {
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    final semesterAktif = homeC.semesterAktifId.value;
    return firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tahunajaran')
        .doc(idTahunAjaran).collection('kelastahunajaran').doc(idKelas)
        .collection('semester').doc(semesterAktif).collection('tugas_ulangan');
  }

  Future<DocumentReference<Map<String, dynamic>>> _getSiswaMapelRef(String nisn) async {
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    final semesterAktif = homeC.semesterAktifId.value;
    return firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tahunajaran')
        .doc(idTahunAjaran).collection('kelastahunajaran').doc(idKelas)
        .collection('semester').doc(semesterAktif).collection('daftarsiswa').doc(nisn)
        .collection('matapelajaran').doc(namaMapel);
  }
}