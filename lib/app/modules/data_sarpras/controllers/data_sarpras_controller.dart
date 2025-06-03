import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
// import 'package:intl/intl.dart'; // Untuk format tanggal di controller jika perlu
import 'package:intl/date_symbol_data_local.dart'; // Untuk inisialisasi locale jika belum di main.dart

// Sesuaikan path jika berbeda
import '../../../data/models/sarpras_model.dart'; // Import model Sarpras

class DataSarprasController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  final isLoading = true.obs; // Mulai dengan loading true
  final RxList<SarprasModel> sarprasList = <SarprasModel>[].obs;
  final errorMessage = ''.obs; // Untuk menampilkan pesan error
  final isAllowedToView = false.obs; // Flag untuk hak akses

  // --- SIMULASI DATA USER & KONTEKS ---
  // Idealnya, ini didapatkan dari service autentikasi atau state global
  final String currentUserJabatan = "Kepala Sekolah"; // Contoh: "Kepala Sekolah", "Guru", "Admin TU"
  final List<String> allowedJabatan = ["Kepala Sekolah", "Wakasek Sarpras", "Admin Sarpras"]; // Jabatan yang boleh melihat

  // Hardcode NPSN dan Tahun Ajaran untuk contoh ini
  // Idealnya, ini didapatkan dari state global atau parameter rute
  final String npsn = "20404148";
  final String tahunAjaran = "2024-2025";
  // --- AKHIR SIMULASI ---

  @override
  void onInit() {
    super.onInit();
    initializeDateFormatting('id_ID', null); // Inisialisasi locale untuk DateFormat
    checkAccessAndFetchData();
  }

  void checkAccessAndFetchData() {
    if (allowedJabatan.contains(currentUserJabatan)) {
      isAllowedToView.value = true;
      fetchSarprasData();
    } else {
      isAllowedToView.value = false;
      isLoading.value = false; // Set loading false karena tidak ada data yang akan diambil
      errorMessage.value = "Anda tidak memiliki hak akses untuk melihat data ini.";
    }
  }

  Stream<List<SarprasModel>> streamSarprasData() {
    // Path ke koleksi sarprassekolah
    CollectionReference sarprasCollectionRef = _firestore
        .collection('Sekolah')
        .doc(npsn)
        .collection('tahunajaran')
        .doc(tahunAjaran)
        .collection('sarprassekolah');

    return sarprasCollectionRef
        .orderBy('timestamp', descending: true) // Urutkan berdasarkan timestamp terbaru
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        return <SarprasModel>[]; // Kembalikan list kosong jika tidak ada dokumen
      }
      return querySnapshot.docs
          .map((doc) =>
              SarprasModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    }).handleError((error) {
      print("Error streaming data sarpras: $error");
      errorMessage.value = "Terjadi kesalahan saat mengambil data: ${error.toString()}";
      return <SarprasModel>[]; // Kembalikan list kosong jika error
    });
  }


  void fetchSarprasData() {
    isLoading.value = true;
    errorMessage.value = ''; // Reset error message

    // Path ke koleksi sarprassekolah
    CollectionReference sarprasCollectionRef = _firestore
        .collection('Sekolah')
        .doc(npsn)
        .collection('tahunajaran')
        .doc(tahunAjaran)
        .collection('sarprassekolah');

    // Menggunakan stream untuk data real-time
    // Jika hanya ingin sekali fetch, gunakan .get()
    sarprasCollectionRef
        .orderBy('timestamp', descending: true) // Urutkan berdasarkan timestamp terbaru
        .snapshots() // Ini akan memberikan update real-time
        .listen((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        sarprasList.clear(); // Kosongkan list jika tidak ada data
        // errorMessage.value = "Belum ada data sarpras."; // Opsional: pesan jika kosong
      } else {
        sarprasList.value = querySnapshot.docs
            .map((doc) =>
                SarprasModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
      }
      isLoading.value = false;
    }, onError: (error) {
      print("Error fetching data sarpras: $error");
      errorMessage.value = "Terjadi kesalahan saat mengambil data: ${error.toString()}";
      isLoading.value = false;
    });
  }

  // Fungsi untuk refresh data (jika diperlukan untuk pull-to-refresh)
  Future<void> refreshData() async {
    if (isAllowedToView.value) {
      fetchSarprasData(); // Cukup panggil fetchSarprasData lagi
    }
  }

  // Jika Anda memiliki halaman BuatSarpras, bisa tambahkan navigasi ke sana
  void goToBuatSarpras() {
    Get.toNamed('/buat-sarpras'); // Sesuaikan dengan nama rute Anda
  }
}


// Penjelasan Kunci:
// Hak Akses (DataSarprasController):
// currentUserJabatan: Variabel ini mensimulasikan jabatan user saat ini. Anda perlu menggantinya dengan logika nyata untuk mendapatkan jabatan user dari sistem autentikasi Anda.
// allowedJabatan: Daftar jabatan yang diizinkan melihat data.
// checkAccessAndFetchData(): Metode ini pertama kali memeriksa apakah currentUserJabatan ada dalam allowedJabatan. Jika ya, isAllowedToView diset true dan data diambil. Jika tidak, isAllowedToView diset false dan pesan error ditampilkan.
// Pengambilan Data (DataSarprasController):
// fetchSarprasData(): Menggunakan .snapshots() dari Firestore untuk mendapatkan stream data. Ini berarti UI akan otomatis diperbarui jika ada perubahan data di Firestore.
// Data di-map ke List<SarprasModel>.
// Error handling sederhana disertakan.
// Tampilan Data (DataSarprasView):
// Menggunakan Obx untuk merebuild UI berdasarkan perubahan state di controller (isLoading, isAllowedToView, errorMessage, sarprasList).
// Jika tidak diizinkan (!controller.isAllowedToView.value), tampilkan pesan larangan.
// Jika loading, tampilkan CircularProgressIndicator.
// Jika ada error, tampilkan pesan error.
// Jika daftar kosong, tampilkan pesan "Belum ada data".
// Jika ada data, tampilkan menggunakan ListView.builder dengan Card dan ListTile untuk setiap item sarpras.
// RefreshIndicator ditambahkan untuk fungsionalitas "tarik untuk segarkan".
// FloatingActionButton untuk navigasi ke halaman tambah data, hanya muncul jika user memiliki hak.
// Model (SarprasModel):
// Membantu mengelola data dengan lebih baik, memberikan type safety, dan memungkinkan Anda menambahkan helper method seperti tanggalPengadaanFormatted.
// Penting untuk Keamanan Sebenarnya:
// Pembatasan akses di sisi klien (Flutter) seperti ini bagus untuk UX, tetapi tidak aman secara absolut. User yang pintar bisa saja mem-bypass logika ini di klien.
// Untuk keamanan yang sesungguhnya, Anda harus menerapkan Firestore Security Rules di Firebase Console. Rules ini dievaluasi di server Firebase dan akan benar-benar membatasi siapa yang bisa membaca atau menulis data tertentu, terlepas dari apa yang dilakukan di sisi klien.
// Contoh sederhana Firestore Security Rule (perlu disesuaikan dengan struktur data user Anda):

//-- code
// rules_version = '2';
// service cloud.firestore {
//   match /databases/{database}/documents {
//     // Fungsi untuk mendapatkan data user (misalnya, dari koleksi 'users' berdasarkan UID)
//     // Anda perlu menyesuaikan ini dengan bagaimana Anda menyimpan info jabatan user
//     function getUserData() {
//       return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
//     }

//     match /Sekolah/{npsn}/tahunajaran/{tahunAjaran}/sarprassekolah/{sarprasId} {
//       // Izinkan baca jika user terautentikasi DAN jabatannya ada di daftar yang diizinkan
//       allow read: if request.auth != null &&
//                      (getUserData().jabatan == "Kepala Sekolah" ||
//                       getUserData().jabatan == "Wakasek Sarpras" ||
//                       getUserData().jabatan == "Admin Sarpras");
//       // Izinkan tulis (create, update, delete) jika user adalah admin atau jabatan tertentu
//       allow write: if request.auth != null &&
//                       (getUserData().jabatan == "Admin Sarpras" || getUserData().jabatan == "Wakasek Sarpras");
//     }
//   }
// }

// Anda perlu menyimpan field jabatan di dokumen user (misalnya, di koleksi users/{userId}) agar Security Rules bisa mengaksesnya.
// Setelah menerapkan kode di atas, navigasikan ke DataSarprasView. Jika currentUserJabatan di controller termasuk dalam allowedJabatan, Anda akan melihat daftar sarpras. Jika tidak, Anda akan melihat pesan larangan.