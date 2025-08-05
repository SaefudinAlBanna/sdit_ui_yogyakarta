import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../home/controllers/home_controller.dart';

// Model untuk UI diletakkan di sini

// [BARU] Enum untuk merepresentasikan status setiap tugas
enum StatusTugas { BelumDiisi, SudahDiisi, TugasPengganti, Dibatalkan }

// [BARU] Model Data untuk UI
class JadwalTugasItem {
  final String jam;
  final String idMapel;
  final String namaMapel;
  final String idKelas;
  final List<String> listIdGuruAsli;
  final List<String> listNamaGuruAsli;
  
  // Info pengganti (bisa null)
  final String? idGuruPengganti;
  final String? namaGuruPengganti;
  
  // Status dan data jurnal
  final StatusTugas status;
  final String? materiDiisi;
  final String? catatanDiisi;

  JadwalTugasItem({
    required this.jam, required this.idMapel, required this.namaMapel,
    required this.idKelas, required this.listIdGuruAsli, required this.listNamaGuruAsli,
    this.idGuruPengganti, this.namaGuruPengganti,
    required this.status, this.materiDiisi, this.catatanDiisi,
  });
}

class JurnalKelasItem {
  final String namaKelas;
  final TextEditingController catatanController;
  RxBool isSelected;
  Rxn<String> selectedJam;

  JurnalKelasItem({required this.namaKelas})
      : isSelected = false.obs,
        selectedJam = Rxn<String>(),
        catatanController = TextEditingController();

  void dispose() {
    catatanController.dispose();
  }
}


class JurnalAjarHarianController extends GetxController {
  
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final String idSekolah = "20404148";
  late String idUser;

  // --- STATE UTAMA YANG BARU ---
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  
  // Inilah satu-satunya state list yang akan dilihat oleh View
  final RxList<JadwalTugasItem> daftarTugasHariIni = <JadwalTugasItem>[].obs;
  
  // State untuk dialog input
  final TextEditingController materimapelC = TextEditingController();
  final TextEditingController catatanjurnalC = TextEditingController();
  // State untuk melacak tugas mana yang sedang dipilih untuk diisi massal
  final RxList<JadwalTugasItem> tugasTerpilih = <JadwalTugasItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    idUser = homeC.idUser;
    loadTugasHarian(); // Langsung panggil fungsi utama kita
  }

  // [FUNGSI UTAMA] Otak dari Dasbor Jurnal
  Future<void> loadTugasHarian() async {
    isLoading.value = true;
    try {
      final today = DateTime.now();
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semester = homeC.semesterAktifId.value;
      final namaHari = DateFormat('EEEE', 'id_ID').format(today);
      final tanggalStr = DateFormat('yyyy-MM-dd').format(today);

      // 1. Ambil semua jadwal permanen & tugas pengganti untuk user ini hari ini
      final jadwalPermanenSnap = await firestore.collectionGroup('jadwalkelas').where(namaHari, isNotEqualTo: null).get();
      final tugasPenggantiSnap = await firestore.collection('sesi_pengganti_kbm').where('idGuruPengganti', isEqualTo: idUser).where('tanggal', isEqualTo: tanggalStr).get();

      // 2. Ambil data pengecualian (jadwal yang sudah digantikan orang lain)
      final jadwalDibatalkanSnap = await firestore.collection('sesi_pengganti_kbm').where('idGuruAsli', isEqualTo: idUser).where('tanggal', isEqualTo: tanggalStr).get();
      final Set<String> jadwalBatalKeys = jadwalDibatalkanSnap.docs.map((doc) => "${doc.data()['idKelas']}_${doc.data()['jam']}").toSet();

      // 3. Ambil semua jurnal yang sudah diisi oleh user ini hari ini
      final jurnalTerisiSnap = await firestore.collectionGroup('jurnalkelas').where('idpenginput', isEqualTo: idUser).where('uidtanggal', isEqualTo: DateFormat.yMd('id_ID').format(today).replaceAll('/', '-')).get();
      final Map<String, Map<String, dynamic>> jurnalTerisiMap = {
        for (var doc in jurnalTerisiSnap.docs) "${doc.data()['kelas']}_${doc.data()['jampelajaran']}": doc.data()
      };
      
      List<JadwalTugasItem> tugasFinal = [];

      // Proses Jadwal Permanen
      for (var doc in jadwalPermanenSnap.docs) {
        final idKelas = doc.id;
        final jadwalHari = doc.data()[namaHari] as List;
        for (var slot in jadwalHari) {
          if ((slot['listIdGuru'] as List).contains(idUser)) {
            final key = "${idKelas}_${slot['jam']}";
            if (jadwalBatalKeys.contains(key)) continue; // Lewati jika sudah digantikan

            final status = jurnalTerisiMap.containsKey(key) ? StatusTugas.SudahDiisi : StatusTugas.BelumDiisi;
            tugasFinal.add(JadwalTugasItem(
              jam: slot['jam'], idMapel: slot['idMapel'], namaMapel: slot['namaMapel'],
              idKelas: idKelas, listIdGuruAsli: List<String>.from(slot['listIdGuru']),
              listNamaGuruAsli: List<String>.from(slot['listNamaGuru']),
              status: status,
              materiDiisi: jurnalTerisiMap[key]?['materipelajaran'],
              catatanDiisi: jurnalTerisiMap[key]?['catatanjurnal'],
            ));
          }
        }
      }

      // Proses Tugas Pengganti
      for (var doc in tugasPenggantiSnap.docs) {
        final data = doc.data();
        final key = "${data['idKelas']}_${data['jam']}";
        final status = jurnalTerisiMap.containsKey(key) ? StatusTugas.SudahDiisi : StatusTugas.TugasPengganti;
        tugasFinal.add(JadwalTugasItem(
          jam: data['jam'], idMapel: data['idMapel'], namaMapel: "Nama Mapel Pengganti", // Perlu denormalisasi
          idKelas: data['idKelas'], listIdGuruAsli: [data['idGuruAsli']],
          listNamaGuruAsli: [data['namaGuruAsli']], idGuruPengganti: data['idGuruPengganti'],
          namaGuruPengganti: data['namaGuruPengganti'], status: status,
          materiDiisi: jurnalTerisiMap[key]?['materipelajaran'],
          catatanDiisi: jurnalTerisiMap[key]?['catatanjurnal'],
        ));
      }
      
      // Urutkan berdasarkan jam
      tugasFinal.sort((a, b) => a.jam.compareTo(b.jam));
      daftarTugasHariIni.assignAll(tugasFinal);

    } catch (e) {
      print(e);
      Get.snackbar("Error Fatal", "Gagal membangun dasbor jurnal: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi untuk aksi simpan, dll akan kita buat setelah view-nya jadi.
  // --- FUNGSI AKSI UNTUK VIEW ---

  void toggleTugasSelection(JadwalTugasItem tugas) {
    if (tugasTerpilih.contains(tugas)) {
      tugasTerpilih.remove(tugas);
    } else {
      // Hanya izinkan memilih tugas yang belum diisi
      if (tugas.status == StatusTugas.BelumDiisi || tugas.status == StatusTugas.TugasPengganti) {
        tugasTerpilih.add(tugas);
      } else {
        Get.snackbar("Info", "Jurnal untuk tugas ini sudah diisi.");
      }
    }
  }

  // Membuka dialog untuk mengisi jurnal
  void openJurnalDialog({List<JadwalTugasItem>? targetTugas}) {
    // Jika targetTugas tidak disediakan, berarti ini aksi individual
    final List<JadwalTugasItem> tugasUntukDiisi = targetTugas ?? tugasTerpilih;
    if (tugasUntukDiisi.isEmpty) return;

    final bool isSingleMode = tugasUntukDiisi.length == 1;

    // Set nilai awal jika ini mode edit
    materimapelC.text = isSingleMode ? (tugasUntukDiisi.first.materiDiisi ?? '') : '';
    catatanjurnalC.text = isSingleMode ? (tugasUntukDiisi.first.catatanDiisi ?? '') : '';

    Get.defaultDialog(
      title: isSingleMode ? "Input Jurnal: ${tugasUntukDiisi.first.namaMapel}" : "Input Jurnal Massal",
      content: Column(
        children: [
          TextField(
            controller: materimapelC,
            decoration: const InputDecoration(labelText: 'Materi yang Diajarkan'),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
          ),
          // Kolom catatan hanya muncul di mode individual
          if (isSingleMode) ...[
            const SizedBox(height: 16),
            TextField(
              controller: catatanjurnalC,
              decoration: const InputDecoration(labelText: 'Catatan Spesifik (Opsional)'),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
            ),
          ]
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => simpanJurnal(tugasUntukDiisi),
        child: const Text("Simpan"),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  // Fungsi simpan yang diperbarui untuk menangani target
  Future<void> simpanJurnal(List<JadwalTugasItem> listTugas) async {
    if (materimapelC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Materi pelajaran wajib diisi.");
      return;
    }

    isSaving.value = true;
    Get.back(); // Tutup dialog
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semesterAktif = homeC.semesterAktifId.value;
      final now = DateTime.now();
      final docIdTanggalJurnal = DateFormat.yMd('id_ID').format(now).replaceAll('/', '-');
      // final namaGuru = homeC.userTugas.contains('Guru') ? (await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get()).data()?['alias'] : 'Guru';
      String namaGuru = "Sistem"; // Default value
      final userDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
      if(userDoc.exists) {
          namaGuru = userDoc.data()?['alias'] ?? 'Guru';
      }
      
      final batch = firestore.batch();

      for (var tugas in listTugas) {
        final dataJurnal = {
          'namamapel': tugas.namaMapel,
          'materipelajaran': materimapelC.text.trim(),
          'catatanjurnal': listTugas.length == 1 ? catatanjurnalC.text.trim() : '', // Catatan hanya untuk mode single
          'kelas': tugas.idKelas,
          'jampelajaran': tugas.jam,
          'tanggalinput': now.toIso8601String(),
          'idpenginput': idUser,
          'namapenginput': namaGuru,
          'uidtanggal': docIdTanggalJurnal,
          'timestamp': now,
          'semester': semesterAktif,
        };

        // Path penyimpanan (sama seperti sebelumnya, tapi lebih dinamis)
        final refKelas = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(tugas.idKelas).collection('semester').doc(semesterAktif).collection('tanggaljurnal').doc(docIdTanggalJurnal).collection('jurnalkelas').doc(tugas.jam);
        batch.set(refKelas, dataJurnal);
        
        final refGuru = firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).collection('tahunajaran').doc(idTahunAjaran).collection('semester').doc(semesterAktif).collection('tanggaljurnal').doc(docIdTanggalJurnal).collection('jurnalkelas').doc(tugas.jam);
        batch.set(refGuru, dataJurnal);
        
        // Disarankan untuk membuat ID flat yang lebih bisa diprediksi
        final refFlat = firestore.collection('Sekolah').doc(idSekolah).collection('jurnal_flat').doc("${tugas.idKelas}_$docIdTanggalJurnal-${tugas.jam}");
        batch.set(refFlat, dataJurnal);
      }

      await batch.commit();
      Get.snackbar("Berhasil", "Jurnal untuk ${listTugas.length} tugas berhasil disimpan.");
      loadTugasHarian(); // Muat ulang dasbor
      tugasTerpilih.clear(); // Kosongkan pilihan

    } catch (e) {
      Get.snackbar("Gagal Menyimpan", "Terjadi kesalahan: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }
}




// class JurnalAjarHarianController extends GetxController {
  
//   // --- STATE MANAGEMENT YANG SUDAH BERSIH ---
//   var isLoading = true.obs;
//   var isSaving = false.obs;
//   var daftarKelasUntukJurnal = <JurnalKelasItem>[].obs;
//   var selectedMapel = Rxn<String>();
//   late TextEditingController materimapelC;

//   // --- INSTANCE & INFO DASAR ---
//   final FirebaseAuth auth = FirebaseAuth.instance;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   late final String idUser;
//   late final String emailAdmin;
//   final String idSekolah = '20404148'; // Ganti jika perlu
//   final HomeController homeController = Get.find<HomeController>();

//   // --- FUNGSI INIT & DISPOSE ---
//   @override
//   void onInit() {
//     super.onInit();
//     materimapelC = TextEditingController();

//     final user = auth.currentUser;
//     if (user != null) {
//       idUser = user.uid;
//       emailAdmin = user.email!;
//     } else {
//       Get.offAllNamed('/login');
//       idUser = '';
//       emailAdmin = '';
//       Get.snackbar("Error", "Sesi Anda telah berakhir. Silakan login kembali.");
//     }
//     _loadInitialData();
//   }

//   Future<void> _loadInitialData() async {
//     try {
//       isLoading.value = true;
//       final kelasDiajar = await getDataKelasYangDiajar();
//       daftarKelasUntukJurnal.assignAll(
//         kelasDiajar.map((nama) => JurnalKelasItem(namaKelas: nama)).toList()
//       );
//     } catch(e) {
//       Get.snackbar("Error", "Gagal memuat data kelas: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   @override
//   void onClose() {
//     materimapelC.dispose();
//     // [DIPERBAIKI] Loop untuk membersihkan semua controller
//     for (var item in daftarKelasUntukJurnal) {
//       item.dispose();
//     }
//     super.onClose();
//   }

//   // --- LOGIKA UNTUK UI ---
//   void onMapelChanged(String? value) {
//     selectedMapel.value = value;
//   }

//   // --- PENGAMBILAN DATA DARI FIRESTORE ---
//   Future<QuerySnapshot<Map<String, dynamic>>> getJamPelajaran() {
//     // Diurutkan berdasarkan nomor urut untuk tampilan yang logis
//     return firestore.collection('Sekolah').doc(idSekolah).collection('jampelajaran').orderBy('urutan').get();
//   }

//   Future<List<String>> getDataKelasYangDiajar() async {
//     final idTahunAjaran = homeController.idTahunAjaran.value;
//     if (idTahunAjaran == null) return [];
//     try {
//       final snapshot = await firestore
//           .collection('Sekolah').doc(idSekolah)
//           .collection('pegawai').doc(idUser)
//           .collection('tahunajaran').doc(idTahunAjaran)
//           .collection('semester').doc(homeController.semesterAktifId.value)
//           .collection('kelasnya').get();
          
//       final kelasList = snapshot.docs.map((doc) => doc.id).toList();
//       kelasList.sort();
//       return kelasList;
//     } catch (e) { return []; }
//   }

//   Future<List<String>> getDataMapel() async {
//     final kelasTerpilih = daftarKelasUntukJurnal
//         .where((p) => p.isSelected.value)
//         .map((p) => p.namaKelas)
//         .toList();

//     if (kelasTerpilih.isEmpty) return [];
//     final idTahunAjaran = homeController.idTahunAjaran.value;
//     if (idTahunAjaran == null) return [];
//     try {
//       Set<String> allMapel = {};
//       for (String namaKelas in kelasTerpilih) {
//         final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).collection('tahunajaran').doc(idTahunAjaran).collection('semester').doc(homeController.semesterAktifId.value).collection('kelasnya').doc(namaKelas).collection('matapelajaran').get();
//         for (var doc in snapshot.docs) { allMapel.add(doc.id); }
//       }
//       final mapelList = allMapel.toList();
//       mapelList.sort();
//       return mapelList;
//     } catch (e) { return []; }
//   }

//   // --- FUNGSI SIMPAN DATA ---
//   Future<void> simpanJurnal() async {
//     final List<JurnalKelasItem> tugasValid = daftarKelasUntukJurnal
//         .where((item) => item.isSelected.value && item.selectedJam.value != null)
//         .toList();
//     if (tugasValid.isEmpty) { Get.snackbar("Peringatan", "Pilih minimal satu kelas dan tentukan jam pelajarannya."); return; }
//     if (selectedMapel.value == null) { Get.snackbar("Peringatan", "Mata pelajaran wajib dipilih."); return; }
//     if (materimapelC.text.trim().isEmpty) { Get.snackbar("Peringatan", "Materi pelajaran wajib diisi."); return; }

//     isSaving.value = true;
//     try {
//       final idTahunAjaran = homeController.idTahunAjaran.value!;
//       final semesterAktif = homeController.semesterAktifId.value;
//       final now = DateTime.now();
//       final docIdTanggalJurnal = DateFormat.yMd('id_ID').format(now).replaceAll('/', '-');
//       final guruDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
//       final namaGuru = guruDoc.data()?['alias'] as String? ?? 'Guru';
      
//       final dataJurnalTemplate = {
//         'namamapel': selectedMapel.value,
//         'materipelajaran': materimapelC.text.trim(),
//         'tanggalinput': now.toIso8601String(),
//         'idpenginput': idUser,
//         'emailpenginput': emailAdmin,
//         'namapenginput': namaGuru,
//         'uidtanggal': docIdTanggalJurnal,
//         'timestamp': now,
//         'semester': semesterAktif,
//       };

//       final batch = firestore.batch();
//       for (var item in tugasValid) {
//         final dataJurnalFinal = {
//           ...dataJurnalTemplate,
//           'kelas': item.namaKelas,
//           'jampelajaran': item.selectedJam.value,
//           'catatanjurnal': item.catatanController.text.trim(),
//         };

//         final refKelas = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(item.namaKelas).collection('semester').doc(semesterAktif).collection('tanggaljurnal').doc(docIdTanggalJurnal).collection('jurnalkelas').doc(item.selectedJam.value!);
//         batch.set(refKelas, dataJurnalFinal);
//         final refGuru = firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).collection('tahunajaran').doc(idTahunAjaran).collection('semester').doc(semesterAktif).collection('tanggaljurnal').doc(docIdTanggalJurnal).collection('jurnalkelas').doc(item.selectedJam.value!);
//         batch.set(refGuru, dataJurnalFinal);
//         final refFlat = firestore.collection('Sekolah').doc(idSekolah).collection('jurnal_flat').doc();
//         batch.set(refFlat, dataJurnalFinal);
//       }
//       await batch.commit();

//       Get.back();
//       Get.snackbar("Berhasil", "Jurnal untuk ${tugasValid.length} jadwal telah disimpan.");
    
//     } catch (e) {
//       Get.snackbar("Gagal Menyimpan", "Terjadi kesalahan: ${e.toString()}");
//     } finally {
//       isSaving.value = false;
//     }
//   }
  
//   // --- STREAM RIWAYAT JURNAL ---
//   Stream<QuerySnapshot<Map<String, dynamic>>> getJurnalHariIni() {
//     try {
//       final idTahunAjaran = homeController.idTahunAjaran.value!;
//       final semesterAktif = homeController.semesterAktifId.value;
//       final now = DateTime.now();
//       final docIdJurnal = DateFormat.yMd('id_ID').format(now).replaceAll('/', '-');

//       return firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).collection('tahunajaran').doc(idTahunAjaran).collection('semester').doc(semesterAktif).collection('tanggaljurnal').doc(docIdJurnal).collection('jurnalkelas').orderBy('tanggalinput', descending: true).snapshots();
//     } catch (e) {
//       return Stream.error(e);
//     }
//   }
// }