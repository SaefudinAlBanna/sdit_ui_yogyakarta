import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

class BuatSarprasController extends GetxController {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  final isLoading = false.obs;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // TextEditingControllers
  late TextEditingController namaBarangC;
  late TextEditingController jumlahC;
  late TextEditingController lokasiC;
  late TextEditingController keteranganC;
  late TextEditingController tanggalPengadaanC; // Untuk menampilkan tanggal terpilih

  // Rx Variables untuk Dropdown dan DatePicker
  final RxString selectedKondisi = "Baik".obs; // Nilai default
  final Rx<DateTime?> selectedTanggalPengadaan = Rx<DateTime?>(null);

  final List<String> kondisiOptions = ["Baik", "Rusak Ringan", "Rusak Berat"];

  // Hardcode NPSN dan Tahun Ajaran untuk contoh ini
  // Idealnya, ini didapatkan dari state global atau parameter rute
  final String npsn = "20404148";
  final String tahunAjaran = "2024-2025";

  @override
  void onInit() {
    super.onInit();
    namaBarangC = TextEditingController();
    jumlahC = TextEditingController();
    lokasiC = TextEditingController();
    keteranganC = TextEditingController();
    tanggalPengadaanC = TextEditingController();
  }

  @override
  void onClose() {
    namaBarangC.dispose();
    jumlahC.dispose();
    lokasiC.dispose();
    keteranganC.dispose();
    tanggalPengadaanC.dispose();
    super.onClose();
  }

  void setSelectedKondisi(String? newValue) {
    if (newValue != null) {
      selectedKondisi.value = newValue;
    }
  }

  Future<void> pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedTanggalPengadaan.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedTanggalPengadaan.value) {
      selectedTanggalPengadaan.value = picked;
      tanggalPengadaanC.text = DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
    }
  }

  Future<void> simpanSarpras() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      try {
        // Persiapkan data untuk Firestore
        Map<String, dynamic> dataSarpras = {
          'namaBarang': namaBarangC.text.trim(),
          'jumlah': int.tryParse(jumlahC.text.trim()) ?? 0,
          'kondisi': selectedKondisi.value,
          'lokasi': lokasiC.text.trim(),
          'tanggalPengadaan': selectedTanggalPengadaan.value != null
              ? Timestamp.fromDate(selectedTanggalPengadaan.value!)
              : null,
          'keterangan': keteranganC.text.trim(),
          'timestamp': FieldValue.serverTimestamp(), // Waktu server saat data dibuat
        };

        // Path ke koleksi sarprassekolah
        CollectionReference sarprasCollection = _firestore
            .collection('Sekolah')
            .doc(npsn)
            .collection('tahunajaran')
            .doc(tahunAjaran)
            .collection('sarprassekolah');

        await sarprasCollection.add(dataSarpras);

        Get.snackbar(
          "Berhasil",
          "Data sarpras berhasil disimpan.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Reset form atau navigasi ke halaman lain
        _resetForm();
        // Jika ingin kembali ke halaman sebelumnya: Get.back();

      } catch (e) {
        Get.snackbar(
          "Error",
          "Gagal menyimpan data: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        isLoading.value = false;
      }
    } else {
      Get.snackbar(
        "Perhatian",
        "Mohon lengkapi semua field yang wajib diisi.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void _resetForm() {
    namaBarangC.clear();
    jumlahC.clear();
    lokasiC.clear();
    keteranganC.clear();
    tanggalPengadaanC.clear();
    selectedTanggalPengadaan.value = null;
    selectedKondisi.value = "Baik"; // Reset ke nilai default
    formKey.currentState?.reset();
  }
}


// Penjelasan Kode:
// Controller (BuatSarprasController):
// Mengelola state inputan (menggunakan TextEditingController untuk text field, RxString untuk dropdown, Rx<DateTime?> untuk tanggal).
// isLoading untuk menampilkan indikator loading saat proses simpan.
// formKey untuk validasi form.
// kondisiOptions: Daftar opsi untuk dropdown kondisi.
// npsn dan tahunAjaran: Untuk contoh ini di-hardcode. Dalam aplikasi nyata, ini bisa didapatkan dari login user, pilihan global, atau parameter rute.
// onInit(): Inisialisasi TextEditingController.
// onClose(): Membersihkan TextEditingController untuk mencegah memory leak.
// setSelectedKondisi(): Mengupdate nilai selectedKondisi ketika dropdown berubah.
// pilihTanggal(): Menampilkan showDatePicker dan mengupdate selectedTanggalPengadaan serta tanggalPengadaanC.text.
// simpanSarpras():
// Memvalidasi form.
// Jika valid, set isLoading ke true.
// Membuat Map<String, dynamic> dari data inputan.
// Menyimpan data ke Firestore menggunakan path yang ditentukan.
// Menampilkan Snackbar untuk feedback sukses atau error.
// Memanggil _resetForm() untuk membersihkan inputan setelah sukses.
// finally block untuk memastikan isLoading kembali ke false.
// _resetForm(): Membersihkan semua field input dan mereset state form.
// View (BuatSarprasView):
// Menggunakan Scaffold, SingleChildScrollView (agar bisa di-scroll jika konten melebihi layar), dan Form.
// initializeDateFormatting('id_ID', null); dipanggil di build agar format tanggal Indonesia (untuk DateFormat) bisa digunakan. Sebaiknya ini dipanggil sekali saja di main.dart jika Anda sering menggunakannya di banyak tempat.
// Masing-masing input field menggunakan TextFormField (kecuali dropdown).
// DropdownButtonFormField digunakan untuk inputan kondisi, di-wrap dengan Obx agar reaktif terhadap perubahan di controller.
// TextFormField untuk tanggal pengadaan dibuat readOnly dan onTap akan memanggil controller.pilihTanggal().
// Validator ditambahkan ke field yang wajib diisi.
// Tombol "Simpan" di-wrap dengan Obx untuk menampilkan CircularProgressIndicator saat controller.isLoading.value adalah true dan men-disable tombol.
// _buildTextField adalah helper widget untuk mengurangi boilerplate kode TextFormField.
// Cara Menggunakan:
// Pastikan Anda sudah setup project Firebase di console Firebase dan menambahkan file konfigurasi (google-services.json untuk Android, GoogleService-Info.plist untuk iOS) ke project Flutter Anda. Jalankan flutterfire configure jika belum.
// Pastikan Firestore Database sudah dibuat di console Firebase.
// Navigasikan ke halaman BuatSarprasView dari aplikasi Anda (misalnya, dari sebuah tombol di dashboard).
// Isi form dan tekan tombol "Simpan Data Sarpras".
// Data akan tersimpan di Firestore sesuai path yang ditentukan.
// Ini adalah dasar yang cukup lengkap. Anda bisa menambahkan fitur lain seperti mengedit data sarpras, menampilkan daftar sarpras, filter, dll.