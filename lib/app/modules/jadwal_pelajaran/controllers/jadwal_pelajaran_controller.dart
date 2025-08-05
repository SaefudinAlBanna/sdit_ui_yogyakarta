import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/controllers/home_controller.dart'; // Pastikan path ini benar

class JadwalPelajaranController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // [PERBAIKAN] Gunakan HomeController sebagai sumber kebenaran untuk data global
  final HomeController homeC = Get.find<HomeController>();

  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<String> selectedKelasId = Rxn<String>();

  final RxMap<String, RxList<Map<String, dynamic>>> jadwalPelajaranPerHari = <String, RxList<Map<String, dynamic>>>{}.obs;
  final RxBool isLoading = true.obs; // Default true untuk loading awal
  final RxString errorMessage = ''.obs;
  final List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
  final String idSekolah = "20404148";

  @override
  void onInit() {
    super.onInit();
    // Inisialisasi struktur map untuk setiap hari
    for (var hari in daftarHari) {
      jadwalPelajaranPerHari[hari] = <Map<String, dynamic>>[].obs;
    }
    // Langsung muat daftar kelas yang aktif di tahun ajaran ini
    _fetchDaftarKelasAktif();
  }

  /// [DIUBAH] Mengambil daftar kelas yang AKTIF di tahun ajaran ini
  Future<void> _fetchDaftarKelasAktif() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value;
      if (idTahunAjaran == null) {
        errorMessage.value = "Tahun ajaran tidak aktif.";
        return;
      }
      
      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran') // Mengambil dari sumber yang benar
          .orderBy('namakelas')
          .get();

      if (snapshot.docs.isNotEmpty) {
        daftarKelas.value = snapshot.docs.map((doc) => {
          'id': doc.id,
          'nama': doc.data()['namakelas'] ?? doc.id,
        }).toList();
      } else {
        errorMessage.value = "Tidak ada kelas yang terdaftar di tahun ajaran ini.";
      }
    } catch (e) {
      errorMessage.value = "Gagal mengambil daftar kelas: $e";
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Dipanggil saat dropdown kelas berubah, tidak ada perubahan di sini
  Future<void> onKelasChanged(String? kelasId) async {
    if (kelasId == null || kelasId.isEmpty) {
      selectedKelasId.value = null;
      _clearJadwal();
      return;
    }
    selectedKelasId.value = kelasId;
    await fetchJadwalPelajaran();
  }
  
  // [Dihapus] Fungsi getTahunAjaranTerakhir() tidak diperlukan lagi, kita pakai data dari HomeController

  /// [DIUBAH TOTAL] Fungsi fetch jadwal sekarang menggunakan path dan struktur data yang benar
  Future<void> fetchJadwalPelajaran() async {
    if (selectedKelasId.value == null) {
      errorMessage.value = "Silakan pilih kelas terlebih dahulu.";
      return;
    }
    
    isLoading.value = true;
    errorMessage.value = '';
    _clearJadwal();

    try {
      final idTahunAjaran = homeC.idTahunAjaran.value;
      if (idTahunAjaran == null) {
        errorMessage.value = "Tahun ajaran tidak aktif.";
        isLoading.value = false;
        return;
      }

      // [FIX 1] Menggunakan path koleksi 'jadwalkelas' yang benar
      final docSnap = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('jadwalkelas') // <-- PATH YANG BENAR
          .doc(selectedKelasId.value!)
          .get();

      if (docSnap.exists && docSnap.data() != null) {
        // [FIX 2] Langsung proses data dokumen, tanpa mencari field 'jadwal'
        final Map<String, dynamic> dataFromFirestore = docSnap.data()!;
        
        dataFromFirestore.forEach((hari, listPelajaranData) {
          if (jadwalPelajaranPerHari.containsKey(hari) && listPelajaranData is List) {
            
            // [FIX 3] Lakukan TRANSFORMASI DATA di sini
            final listPelajaranMap = listPelajaranData.map((item) {
              final mapItem = Map<String, dynamic>.from(item as Map);
              final jam = mapItem['jam'] as String? ?? '00:00-00:00';
              final jamParts = jam.split('-');

              return {
                'mapel': mapItem['namaMapel'] ?? 'Mapel tidak ada',
                'mulai': jamParts.isNotEmpty ? jamParts[0] : '--:--',
                'selesai': jamParts.length > 1 ? jamParts[1] : '--:--',
                // Gabungkan nama guru menjadi satu string
                'guru': (mapItem['listNamaGuru'] as List<dynamic>?)?.join(', ') ?? 'Guru tidak ada', 
              };
            }).toList();

            // Urutkan berdasarkan waktu 'mulai'
            listPelajaranMap.sort((a, b) => (a['mulai']).compareTo(b['mulai']));
            
            // Tambahkan nomor 'jamKe' setelah diurutkan
            for (int i = 0; i < listPelajaranMap.length; i++) {
                listPelajaranMap[i]['jamKe'] = i + 1;
            }

            jadwalPelajaranPerHari[hari]?.addAll(listPelajaranMap);
          }
        });
        
        // Cek lagi apakah setelah diproses hasilnya tetap kosong
        if (jadwalPelajaranPerHari.values.every((list) => list.isEmpty)) {
            errorMessage.value = 'Jadwal ditemukan, namun isinya kosong.';
        }

      } else {
        errorMessage.value = 'Belum ada jadwal yang diatur untuk kelas ini.';
      }
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan saat memuat jadwal: ${e.toString()}';
      print(e); // Cetak error ke konsol untuk debugging
    } finally {
      isLoading.value = false;
    }
  }
  
  void _clearJadwal() {
    for (var hari in daftarHari) {
      jadwalPelajaranPerHari[hari]?.clear();
    }
    errorMessage.value = '';
  }
  
  // Fungsi refresh tidak perlu diubah
  Future<void> refreshJadwal() async {
    if (selectedKelasId.value != null) {
      await fetchJadwalPelajaran();
    }
  }
}


// // controllers/jadwal_pelajaran_controller.dart
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class JadwalPelajaranController extends GetxController {
//   FirebaseFirestore firestore = FirebaseFirestore.instance;

//   // --- STATE BARU UNTUK KELAS ---
//   final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
//   final Rxn<String> selectedKelasId = Rxn<String>(); // Dibuat nullable

//   // --- STATE LAMA ---
//   final RxMap<String, RxList<Map<String, dynamic>>> jadwalPelajaranPerHari = <String, RxList<Map<String, dynamic>>>{}.obs;
//   final RxBool isLoading = false.obs; // Awalnya false, loading saat aksi
//   final RxString errorMessage = ''.obs;
//   final List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
//   final String idSekolah = "20404148";

//   @override
//   void onInit() {
//     super.onInit();
//     // Inisialisasi struktur map
//     for (var hari in daftarHari) {
//       jadwalPelajaranPerHari[hari] = <Map<String, dynamic>>[].obs;
//     }
//     // Langsung muat daftar kelas
//     _fetchDaftarKelas();
//   }

//   /// FUNGSI BARU: Mengambil daftar kelas dari Firestore
//   Future<void> _fetchDaftarKelas() async {
//     isLoading.value = true;
//     try {
//       final snapshot = await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('kelas')
//           .get();
//       if (snapshot.docs.isNotEmpty) {
//         daftarKelas.value = snapshot.docs.map((doc) => {
//           'id': doc.id,
//           'nama': doc.data()['namakelas'] ?? 'Tanpa Nama',
//         }).toList();
//       }
//     } catch (e) {
//       errorMessage.value = "Gagal mengambil daftar kelas: $e";
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// FUNGSI BARU: Dipanggil saat dropdown kelas berubah
//   Future<void> onKelasChanged(String? kelasId) async {
//     if (kelasId == null || kelasId.isEmpty) {
//       selectedKelasId.value = null;
//       _clearJadwal();
//       return;
//     }
//     selectedKelasId.value = kelasId;
//     await fetchJadwalPelajaran();
//   }

//   Future<String> getTahunAjaranTerakhir() async {
//     CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran');
//     QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
//         await colTahunAjaran.get();
//     List<Map<String, dynamic>> listTahunAjaran =
//         snapshotTahunAjaran.docs.map((e) => e.data()).toList();
//     String tahunAjaranTerakhir =
//         listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
//     return tahunAjaranTerakhir;
//   }
  
//   /// DIUBAH TOTAL: Fungsi fetch jadwal sekarang dinamis berdasarkan kelas
//   Future<void> fetchJadwalPelajaran() async {
//     if (selectedKelasId.value == null) {
//       errorMessage.value = "Silakan pilih kelas terlebih dahulu.";
//       return;
//     }
    
//     isLoading.value = true;
//     errorMessage.value = '';
//     _clearJadwal();

//     try {
//       String tahunajaranya = await getTahunAjaranTerakhir();
//       String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//       final docSnap = await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .collection('kelastahunajaran')
//           .doc(selectedKelasId.value!) // <-- PATH BARU YANG DINAMIS
//           .get();

//       if (docSnap.exists && docSnap.data() != null) {
//         final docData = docSnap.data() as Map<String, dynamic>;
//         if (docData.containsKey('jadwal')) {
//           Map<String, dynamic> dataFromFirestore = docData['jadwal'];
//           dataFromFirestore.forEach((hari, listPelajaranData) {
//             if (jadwalPelajaranPerHari.containsKey(hari) && listPelajaranData is List) {
//               final listPelajaranMap = List<Map<String, dynamic>>.from(
//                 listPelajaranData.map((item) => Map<String, dynamic>.from(item as Map))
//               );
//               listPelajaranMap.sort((a, b) => (a['jamKe'] as int? ?? 0).compareTo(b['jamKe'] as int? ?? 0));
//               jadwalPelajaranPerHari[hari]?.addAll(listPelajaranMap);
//             }
//           });
//         } else {
//            errorMessage.value = 'Belum ada jadwal yang diatur untuk kelas ini.';
//         }
//       } else {
//         errorMessage.value = 'Belum ada jadwal yang diatur untuk kelas ini.';
//       }
//     } catch (e) {
//       errorMessage.value = 'Terjadi kesalahan: ${e.toString()}';
//     } finally {
//       isLoading.value = false;
//     }
//   }
  
//   void _clearJadwal() {
//     for (var hari in daftarHari) {
//       jadwalPelajaranPerHari[hari]?.clear();
//     }
//     errorMessage.value = ''; // Juga bersihkan pesan error
//   }
  
//   Future<void> refreshJadwal() async {
//     if (selectedKelasId.value != null) {
//       await fetchJadwalPelajaran();
//     } else {
//       Get.snackbar("Info", "Pilih kelas terlebih dahulu untuk me-refresh jadwal.");
//     }
//   }
// }