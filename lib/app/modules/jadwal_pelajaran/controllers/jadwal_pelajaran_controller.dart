// controllers/jadwal_pelajaran_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JadwalPelajaranController extends GetxController {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // RxMap untuk menyimpan jadwal pelajaran per hari
  // Key: Nama Hari (String), Value: List pelajaran (RxList<Map<String, dynamic>>)
  final RxMap<String, RxList<Map<String, dynamic>>> jadwalPelajaranPerHari =
      <String, RxList<Map<String, dynamic>>>{}.obs;

  RxBool isLoading = true.obs; // Awalnya true karena kita akan fetch data
  RxString errorMessage = ''.obs; // Untuk menyimpan pesan error jika ada

  // Daftar hari yang diharapkan ada di jadwal (sesuaikan jika perlu)
  // Ini juga akan menentukan urutan tab
  List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  // ID Sekolah dan Tahun Ajaran
  // TODO: Idealnya, ini didapatkan dari argumen navigasi atau state global
  String idSekolah = "20404148";
  String tahunAjaran = "2024-2025";

  @override
  void onInit() {
    super.onInit();
    // Inisialisasi map dengan list kosong untuk setiap hari
    for (var hari in daftarHari) {
      jadwalPelajaranPerHari[hari] = <Map<String, dynamic>>[].obs;
    }
    fetchJadwalPelajaran();
  }

  Future<void> fetchJadwalPelajaran() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      DocumentSnapshot docSnap = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(tahunAjaran)
          .collection('jadwalpelajaran')
          .doc(tahunAjaran)
          .get();

      if (docSnap.exists && docSnap.data() != null) {
        Map<String, dynamic> dataFromFirestore = docSnap.data() as Map<String, dynamic>;

        // Bersihkan data lama sebelum mengisi dengan yang baru (jika ada re-fetch)
        for (var hari in daftarHari) {
          jadwalPelajaranPerHari[hari]?.clear();
        }

        dataFromFirestore.forEach((hari, listPelajaranData) {
          if (jadwalPelajaranPerHari.containsKey(hari) && listPelajaranData is List) {
            // Konversi List<dynamic> (dari firestore) menjadi List<Map<String, dynamic>>
            final listPelajaranMap = List<Map<String, dynamic>>.from(
              listPelajaranData.map((item) => Map<String, dynamic>.from(item as Map))
            );

            // Opsional: Urutkan berdasarkan jamKe jika ada dan diperlukan
            listPelajaranMap.sort((a, b) {
              int jamKeA = a['jamKe'] as int? ?? 0;
              int jamKeB = b['jamKe'] as int? ?? 0;
              return jamKeA.compareTo(jamKeB);
            });

            jadwalPelajaranPerHari[hari]?.addAll(listPelajaranMap);
          }
        });
        // Refresh seluruh map jika perlu, atau biarkan Obx pada masing-masing RxList yang bekerja
        jadwalPelajaranPerHari.refresh();

      } else {
        errorMessage.value = 'Jadwal pelajaran tidak ditemukan untuk tahun ajaran ini.';
        // Pastikan list tetap kosong jika tidak ada data
        for (var hari in daftarHari) {
            jadwalPelajaranPerHari[hari]?.clear();
        }
        jadwalPelajaranPerHari.refresh();
      }
    } catch (e) {
      print("Error fetching jadwal: $e"); // Log error
      errorMessage.value = 'Terjadi kesalahan saat mengambil data jadwal.';
       // Pastikan list tetap kosong jika error
        for (var hari in daftarHari) {
            jadwalPelajaranPerHari[hari]?.clear();
        }
        jadwalPelajaranPerHari.refresh();
    } finally {
      isLoading.value = false;
    }
  }

  // Opsional: Fungsi untuk refresh data
  Future<void> refreshJadwal() async {
    await fetchJadwalPelajaran();
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