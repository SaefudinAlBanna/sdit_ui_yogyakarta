// controllers/jadwal_pelajaran_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JadwalPelajaranController extends GetxController {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // --- STATE BARU UNTUK KELAS ---
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<String> selectedKelasId = Rxn<String>(); // Dibuat nullable

  // --- STATE LAMA ---
  final RxMap<String, RxList<Map<String, dynamic>>> jadwalPelajaranPerHari = <String, RxList<Map<String, dynamic>>>{}.obs;
  final RxBool isLoading = false.obs; // Awalnya false, loading saat aksi
  final RxString errorMessage = ''.obs;
  final List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
  final String idSekolah = "20404148";

  @override
  void onInit() {
    super.onInit();
    // Inisialisasi struktur map
    for (var hari in daftarHari) {
      jadwalPelajaranPerHari[hari] = <Map<String, dynamic>>[].obs;
    }
    // Langsung muat daftar kelas
    _fetchDaftarKelas();
  }

  /// FUNGSI BARU: Mengambil daftar kelas dari Firestore
  Future<void> _fetchDaftarKelas() async {
    isLoading.value = true;
    try {
      final snapshot = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('kelas')
          .get();
      if (snapshot.docs.isNotEmpty) {
        daftarKelas.value = snapshot.docs.map((doc) => {
          'id': doc.id,
          'nama': doc.data()['namakelas'] ?? 'Tanpa Nama',
        }).toList();
      }
    } catch (e) {
      errorMessage.value = "Gagal mengambil daftar kelas: $e";
    } finally {
      isLoading.value = false;
    }
  }

  /// FUNGSI BARU: Dipanggil saat dropdown kelas berubah
  Future<void> onKelasChanged(String? kelasId) async {
    if (kelasId == null || kelasId.isEmpty) {
      selectedKelasId.value = null;
      _clearJadwal();
      return;
    }
    selectedKelasId.value = kelasId;
    await fetchJadwalPelajaran();
  }

  Future<String> getTahunAjaranTerakhir() async {
    CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran');
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
        await colTahunAjaran.get();
    List<Map<String, dynamic>> listTahunAjaran =
        snapshotTahunAjaran.docs.map((e) => e.data()).toList();
    String tahunAjaranTerakhir =
        listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
    return tahunAjaranTerakhir;
  }
  
  /// DIUBAH TOTAL: Fungsi fetch jadwal sekarang dinamis berdasarkan kelas
  Future<void> fetchJadwalPelajaran() async {
    if (selectedKelasId.value == null) {
      errorMessage.value = "Silakan pilih kelas terlebih dahulu.";
      return;
    }
    
    isLoading.value = true;
    errorMessage.value = '';
    _clearJadwal();

    try {
      String tahunajaranya = await getTahunAjaranTerakhir();
      String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

      final docSnap = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelastahunajaran')
          .doc(selectedKelasId.value!) // <-- PATH BARU YANG DINAMIS
          .get();

      if (docSnap.exists && docSnap.data() != null) {
        final docData = docSnap.data() as Map<String, dynamic>;
        if (docData.containsKey('jadwal')) {
          Map<String, dynamic> dataFromFirestore = docData['jadwal'];
          dataFromFirestore.forEach((hari, listPelajaranData) {
            if (jadwalPelajaranPerHari.containsKey(hari) && listPelajaranData is List) {
              final listPelajaranMap = List<Map<String, dynamic>>.from(
                listPelajaranData.map((item) => Map<String, dynamic>.from(item as Map))
              );
              listPelajaranMap.sort((a, b) => (a['jamKe'] as int? ?? 0).compareTo(b['jamKe'] as int? ?? 0));
              jadwalPelajaranPerHari[hari]?.addAll(listPelajaranMap);
            }
          });
        } else {
           errorMessage.value = 'Belum ada jadwal yang diatur untuk kelas ini.';
        }
      } else {
        errorMessage.value = 'Belum ada jadwal yang diatur untuk kelas ini.';
      }
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  
  void _clearJadwal() {
    for (var hari in daftarHari) {
      jadwalPelajaranPerHari[hari]?.clear();
    }
    errorMessage.value = ''; // Juga bersihkan pesan error
  }
  
  Future<void> refreshJadwal() async {
    if (selectedKelasId.value != null) {
      await fetchJadwalPelajaran();
    } else {
      Get.snackbar("Info", "Pilih kelas terlebih dahulu untuk me-refresh jadwal.");
    }
  }
}


// CATATAN

// // Saat navigasi dari halaman lain
// String sekolahIdPilihan = "xxxx"; // Dari pilihan user
// String thAjaranPilihan = "yyyy-yyyy"; // Dari pilihan user

// Get.toNamed(
//   Routes.JADWAL_PELAJARAN,
//   arguments: {
//     'idSekolah': sekolahIdPilihan,
//     'tahunAjaran': thAjaranPilihan,
//   },
// );


// Kemudian di JadwalPelajaranController, ambil argumen ini di onInit():
// // Dalam JadwalPelajaranController
// @override
// void onInit() {
//   super.onInit();
//   if (Get.arguments != null) {
//     idSekolah = Get.arguments['idSekolah'] as String? ?? "20404148"; // Fallback
//     tahunAjaran = Get.arguments['tahunAjaran'] as String? ?? "2024-2025"; // Fallback
//   } else {
//     // Handle jika argumen tidak ada, bisa set default atau tampilkan error
//     print("Argumen idSekolah dan tahunAjaran tidak ditemukan, menggunakan default.");
//   }

//   // Inisialisasi map dengan list kosong untuk setiap hari
//   for (var hari in daftarHari) {
//     jadwalPelajaranPerHari[hari] = <Map<String, dynamic>>[].obs;
//   }
//   fetchJadwalPelajaran();
// }