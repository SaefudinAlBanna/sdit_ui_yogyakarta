import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../modules/home/controllers/home_controller.dart';

class DaftarSiswaPermapelController extends GetxController {
  
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  late String idKelas;
  late String namaMapel;
  
  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> daftarSiswa = <Map<String, dynamic>>[].obs;
  final RxString appBarTitle = "Memuat...".obs;

  final RxBool isDialogLoading = false.obs;
  
  final TextEditingController judulTugasC = TextEditingController();
  final TextEditingController deskripsiTugasC = TextEditingController();

  final Rxn<String> tugasTerpilihId = Rxn<String>();
  // final TextEditingController nilaiMassalC = TextEditingController();
  final TextEditingController catatanNilaiC = TextEditingController();
  final RxList<String> siswaTerpilihUntukNilai = <String>[].obs;

  Map<String, TextEditingController> nilaiIndividualControllers = {};

  final RxBool isWaliKelas = false.obs;

  // ... (onInit, onClose, _checkIsWaliKelas, fetchSiswaDanNilai tidak berubah) ...
  
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
    // nilaiMassalC.dispose(); 
    catatanNilaiC.dispose();
    nilaiIndividualControllers.forEach((_, controller) => controller.dispose());
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
  
  /// [DIUBAH] Menyimpan tugas DAN membuat notifikasi untuk semua siswa di kelas.
  Future<void> buatTugasBaru(String kategori) async {
    if (judulTugasC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Judul tidak boleh kosong."); return;
    }
    isDialogLoading.value = true;
    DocumentReference? newTugasRef; // Untuk menyimpan referensi tugas baru
    try {
      String kategoriDisimpan = (kategori == "PR") ? "Harian/PR" : kategori;
      final ref = await _getTugasUlanganCollectionRef();
      // Simpan referensi dari dokumen yang baru dibuat
      newTugasRef = await ref.add({
        'judul': judulTugasC.text.trim(),
        'kategori': kategoriDisimpan,
        'deskripsi': deskripsiTugasC.text.trim(),
        'tanggal_dibuat': Timestamp.now(),
        'status': 'diumumkan',
        'namaMapel': namaMapel,
      });

      // --- [NOTIFIKASI TUGAS BARU] ---
      try {
        final WriteBatch notifBatch = firestore.batch();
        final judulNotif = (kategori == "PR") ? "PR Baru: $namaMapel" : "Ulangan Baru: $namaMapel";
        final isiNotif = "Ananda mendapatkan tugas baru: '${judulTugasC.text.trim()}'.";

        for (var siswa in daftarSiswa) {
          final nisn = siswa['idSiswa'] as String;
          final siswaDocRef = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('siswa').doc(nisn);
          
          notifBatch.set(siswaDocRef.collection('notifikasi').doc(), {
            'judul': judulNotif,
            'isi': isiNotif,
            'tipe': (kategori == "PR") ? 'TUGAS_BARU' : 'ULANGAN_BARU',
            'tanggal': FieldValue.serverTimestamp(),
            'isRead': false,
            'deepLink': '/akademik/tugas/${newTugasRef.id}', // Gunakan ID tugas
          });
          notifBatch.update(siswaDocRef, {'unreadNotificationCount': FieldValue.increment(1)});
        }
        await notifBatch.commit();
        print("Log: Notifikasi tugas baru berhasil dikirim ke ${daftarSiswa.length} siswa.");
      } catch (e) {
        print("Error [Non-Fatal] saat kirim notifikasi tugas: $e");
      }
      // -----------------------------
      
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "$kategori baru telah dibuat.");
    } catch(e) { Get.snackbar("Error", "Gagal membuat tugas: $e"); } 
    finally { isDialogLoading.value = false; judulTugasC.clear(); deskripsiTugasC.clear(); }
  }


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

    Future<void> simpanNilaiMassal() async {
      // 1. Validasi Input Awal
      if (tugasTerpilihId.value == null) { Get.snackbar("Peringatan", "Pilih tugas/ulangan terlebih dahulu."); return; }
      if (siswaTerpilihUntukNilai.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu siswa."); return; }

      isDialogLoading.value = true;
      String judulTugas = 'Tugas/Ulangan'; // Nilai default
      try {
        // [PERSIAPAN] Kumpulkan data siswa yang nilainya valid untuk notifikasi nanti
        List<Map<String, dynamic>> siswaDenganNilaiValid = [];

        // --- TAHAP 1: SIMPAN NILAI KE DATABASE ---
        final WriteBatch nilaiBatch = firestore.batch();

        // Ambil Dokumen Tugas untuk Mendapatkan Kategori & Judul
        final refTugas = (await _getTugasUlanganCollectionRef()).doc(tugasTerpilihId.value!);
        final docTugas = await refTugas.get();
        if (!docTugas.exists) throw Exception("Dokumen tugas/ulangan tidak ditemukan.");

        final String kategoriTugas = docTugas.data()?['kategori'] ?? 'Lainnya';
        judulTugas = docTugas.data()?['judul'] ?? judulTugas;

        // Loop untuk setiap siswa yang DIPILIH
        for (String nisn in siswaTerpilihUntukNilai) {
          final nilaiController = nilaiIndividualControllers[nisn];
          final String nilaiString = nilaiController?.text.trim() ?? '';

          // Hanya proses siswa yang nilainya diisi
          if (nilaiString.isNotEmpty) {
            int? nilai = int.tryParse(nilaiString);
            if (nilai == null || nilai < 0 || nilai > 100) {
              print("Nilai tidak valid untuk siswa $nisn: $nilaiString. Dilewati.");
              continue; // Lewati siswa ini dan lanjutkan ke berikutnya
            }

            // Jika nilai valid, tambahkan ke batch dan daftar notifikasi
            final refNilai = (await _getSiswaMapelRef(nisn)).collection('nilai_harian').doc();
            nilaiBatch.set(refNilai, {
              'id_tugas_ulangan': tugasTerpilihId.value,
              'nilai': nilai,
              'catatan': catatanNilaiC.text.trim(),
              'tanggal': Timestamp.now(),
              'kategori': kategoriTugas,
            });

            // Simpan info siswa ini untuk TAHAP 2 (Notifikasi & Timeline)
            final siswaInfo = daftarSiswa.firstWhere((s) => s['idSiswa'] == nisn);
            siswaDenganNilaiValid.add({
              'nisn': nisn,
              'namaSiswa': siswaInfo['namasiswa'],
              'nilai': nilai,
              'refNilaiId': refNilai.id, // Simpan ID nilai untuk referensi
            });
          }
        }

        // Jika tidak ada siswa dengan nilai valid, hentikan proses
        if (siswaDenganNilaiValid.isEmpty) {
          Get.snackbar("Info", "Tidak ada nilai yang diisi. Tidak ada data yang disimpan.");
          isDialogLoading.value = false;
          return;
        }

        // Update status tugas menjadi "selesai_dinilai"
        nilaiBatch.update(refTugas, {'status': 'selesai_dinilai'});
        await nilaiBatch.commit();

        // --- TAHAP 2: BUAT NOTIFIKASI & TIMELINE ---
        try {
          final WriteBatch notifBatch = firestore.batch();

          for (var siswa in siswaDenganNilaiValid) {
            final nisn = siswa['nisn'];
            final siswaDocRef = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('siswa').doc(nisn);
            final siswaMapelRef = await _getSiswaMapelRef(nisn);

            // Operasi 1: Buat Notifikasi
            notifBatch.set(siswaDocRef.collection('notifikasi').doc(), {
              'judul': "Nilai Baru: $namaMapel",
              'isi': "Ananda ${siswa['namaSiswa']} mendapatkan nilai ${siswa['nilai']} untuk '$judulTugas'.",
              'tipe': 'NILAI_MAPEL',
              'tanggal': FieldValue.serverTimestamp(),
              'isRead': false,
              'deepLink': '/akademik/nilai/$nisn',
            });

            // Operasi 2: Update Counter Notifikasi
            notifBatch.update(siswaDocRef, {'unreadNotificationCount': FieldValue.increment(1)});

            // Operasi 3: Buat Catatan di Timeline Akademik
            notifBatch.set(siswaMapelRef.collection('timeline_akademik').doc(), {
              'tipe': 'NILAI_MASUK',
              'judul': 'Penilaian: $judulTugas',
              'deskripsi': 'Ananda mendapatkan nilai ${siswa['nilai']}.',
              'tanggal': FieldValue.serverTimestamp(),
              'refId': siswa['refNilaiId'],
            });
          }
          await notifBatch.commit();
          print("Log: Notifikasi & Timeline berhasil dibuat untuk ${siswaDenganNilaiValid.length} siswa.");
        } catch (e) {
          print("Error [Non-Fatal] saat membuat notifikasi & timeline: $e");
        }

        Get.back(); // Tutup dialog
        Get.snackbar("Berhasil", "Nilai untuk ${siswaDenganNilaiValid.length} siswa berhasil disimpan.");
        fetchDataSiswa(); // Refresh tampilan di halaman sebelumnya

      } catch(e) {
        Get.snackbar("Error", "Gagal menyimpan nilai: ${e.toString()}");
      } finally {
        isDialogLoading.value = false;
        tugasTerpilihId.value = null;
        catatanNilaiC.clear();
        siswaTerpilihUntukNilai.clear();
        nilaiIndividualControllers.forEach((_, controller) => controller.clear());
      }
    }

  

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

        nilaiIndividualControllers.forEach((_, c) => c.dispose());
        nilaiIndividualControllers.clear();
          for (var siswa in daftarSiswa) {
        nilaiIndividualControllers[siswa['idSiswa']] = TextEditingController();
          
        }
        
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

  void toggleSiswaSelection(String nisn) {
    if (siswaTerpilihUntukNilai.contains(nisn)) {
      siswaTerpilihUntukNilai.remove(nisn);
    } else {
      siswaTerpilihUntukNilai.add(nisn);
    }
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