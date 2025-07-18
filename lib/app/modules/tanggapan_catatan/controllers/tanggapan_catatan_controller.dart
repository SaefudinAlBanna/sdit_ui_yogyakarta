// lib/app/modules/tanggapan_catatan/controllers/tanggapan_catatan_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TanggapanCatatanController extends GetxController {
  // --- Firebase & User Info ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late final String idUser;
  late final String emailAdmin;
  final String idSekolah = "20404148";
  String? idTahunAjaran;
  String? userRole;

  // --- State untuk UI ---
  final RxBool isLoading = true.obs;
  final RxString selectedKelasId = ''.obs;
  final RxString selectedSiswaId = ''.obs;

  final RxList<Map<String, String>> daftarKelas = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> daftarSiswa = <Map<String, String>>[].obs;
  
  // --- Text Controllers untuk Dialog ---
  final TextEditingController judulC = TextEditingController();
  final TextEditingController catatanC = TextEditingController();
  final TextEditingController tindakanC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }
  
  Future<void> _initialize() async {
    idUser = auth.currentUser!.uid;
    emailAdmin = auth.currentUser!.email!;
    // --- AMBIL ROLE PENGGUNA DARI FIRESTORE ---
    try {
      final docUser = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
      if (docUser.exists) {
        userRole = docUser.data()?['role']; // <-- Simpan role ke variabel
      } else {
        // Handle jika data pegawai tidak ditemukan (misalnya, login sebagai admin/superadmin)
        // Anda bisa set role default atau tampilkan pesan error
        print("Data pegawai tidak ditemukan untuk UID: $idUser");
      }
    } catch (e) {
      print("Error saat mengambil role: $e");
      Get.snackbar("Error", "Gagal memuat data peran pengguna.");
    }
    // ---------------------------------------------
    final tahunAjaran = await _getTahunAjaranTerakhir();
    idTahunAjaran = tahunAjaran.replaceAll("/", "-");
    await fetchDaftarKelas();
    isLoading.value = false;
  }

  Future<String> _getTahunAjaranTerakhir() async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').orderBy('namatahunajaran', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) return "TA-Tidak-Ditemukan";
    return snapshot.docs.first.data()['namatahunajaran'] as String;
  }

  Future<void> fetchDaftarKelas() async {
  if (idTahunAjaran == null) return;
  
  // Kita siapkan variabel query terlebih dahulu
  Query<Map<String, dynamic>> query;

  final kelasCollection = firestore
      .collection('Sekolah').doc(idSekolah)
      .collection('tahunajaran').doc(idTahunAjaran!)
      .collection('kelastahunajaran');

  // Sekarang, kita tentukan query berdasarkan role pengguna
  if (userRole == "Kepala Sekolah" || userRole == "Guru BK") { // Kepala Sekolah & Guru BK bisa lihat semua kelas
    query = kelasCollection.orderBy('namakelas'); // Mengambil semua kelas, diurutkan berdasarkan nama
  } else if (userRole == "Guru Kelas") {
    // INI BAGIAN PENTINGNYA: Filter kelas berdasarkan idwalikelas
    query = kelasCollection.where('idwalikelas', isEqualTo: idUser);
  } else {
    // Jika role lain (atau tidak terdefinisi), jangan tampilkan kelas apa pun.
    daftarKelas.clear();
    return;
  }

  try {
    final snapshot = await query.get();

    // Pastikan ada field 'nama' di dokumen kelas Anda untuk tampilan yang lebih baik
    final kelas = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'nama': (doc.data()['namakelas'] as String?) ?? doc.id // Gunakan field 'nama', jika tidak ada, pakai ID
      };
    }).toList();
    
    daftarKelas.assignAll(kelas);

    // Jika Guru Kelas hanya menjadi wali untuk 1 kelas, langsung pilih kelas & load siswanya
    if (userRole == "Guru Kelas" && daftarKelas.length == 1) {
        onKelasChanged(daftarKelas.first['id']);
    }

  } catch (e) {
    print("Error fetching kelas: $e");
    Get.snackbar("Error", "Gagal memuat daftar kelas. Pastikan index Firestore sudah dibuat jika diperlukan.");
  }
}

  void onKelasChanged(String? kelasId) async {
    if (kelasId == null || kelasId.isEmpty) return;
    selectedKelasId.value = kelasId;
    selectedSiswaId.value = ''; // Reset pilihan siswa
    daftarSiswa.clear();

    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran!).collection('kelastahunajaran').doc(kelasId).collection('daftarsiswa').get();
    final siswa = snapshot.docs.map((doc) => {'id': doc.id, 'nama': doc.data()['namasiswa'] as String}).toList();
    daftarSiswa.assignAll(siswa);
  }

  void onSiswaChanged(String? siswaId) {
    if (siswaId == null || siswaId.isEmpty) return;
    selectedSiswaId.value = siswaId;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCatatanSiswa() {
    if (selectedSiswaId.value.isEmpty || idTahunAjaran == null) {
      return const Stream.empty();
    }
    // Path ini mengarah ke catatan yang disimpan di bawah koleksi siswa
    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('siswa').doc(selectedSiswaId.value)
        .collection('tahunajaran').doc(idTahunAjaran!)
        .collection('catatansiswa').orderBy('tanggalinput', descending: true)
        .snapshots();
  }
  
  final TextEditingController tanggapanC = TextEditingController();

  void openTanggapanDialog(Map<String, dynamic> catatan) {
    // final String role = "Kepala Sekolah"; // atau "wali_kelas", ini harusnya didapat dari data login user
     final String? role = userRole; // atau "wali_kelas", ini harusnya didapat dari data login user
    String fieldToUpdate = "";
    String dialogTitle = "";

    if (role == "Kepala Sekolah") {
      fieldToUpdate = "tanggapankepalasekolah";
      dialogTitle = "Tanggapan Kepala Sekolah";
    } else if (role == "Guru Kelas") {
      fieldToUpdate = "tanggapanwalikelas";
      dialogTitle = "Tanggapan Wali Kelas";
      } else if (role == "Guru BK") { // Tambahkan jika Guru BK juga bisa memberi tanggapan utama
      fieldToUpdate = "tindakangurubk"; // atau field lain yang sesuai
      dialogTitle = "Tindakan Guru BK";
    
    } else {
      Get.snackbar("Error", "Peran Anda ($role) tidak dikenali untuk memberi tanggapan.");
      return;
    }

    tanggapanC.text = catatan[fieldToUpdate] ?? ''; // Isi tanggapan lama jika ada

    Get.dialog(
      AlertDialog(
        title: Text(dialogTitle),
        content: TextField(controller: tanggapanC, decoration: const InputDecoration(labelText: 'Tulis tanggapan...'), maxLines: 4),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Batal")),
          ElevatedButton(onPressed: () => _simpanTanggapan(catatan, fieldToUpdate), child: const Text("Simpan")),
        ],
      ),
    );
  }

  Future<void> _simpanTanggapan(Map<String, dynamic> catatan, String fieldToUpdate) async {
  if (tanggapanC.text.isEmpty) {
    Get.snackbar("Peringatan", "Tanggapan tidak boleh kosong.");
    return;
  }

  try {
    // Ambil ID yang dibutuhkan dari data catatan yang sudah ada
    final docIdCatatan = catatan['docId']; // Pastikan Anda menyimpan docId di dalam data catatan
    final idSiswa = selectedSiswaId.value; // Gunakan siswa yang sedang dipilih

    if (idSiswa.isEmpty || docIdCatatan == null || idTahunAjaran == null) {
      Get.snackbar("Error", "Informasi siswa atau catatan tidak lengkap.");
      return;
    }

    // Ini adalah SATU-SATUNYA path yang kita tuju
    final catatanDocRef = firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('siswa').doc(idSiswa)
        .collection('tahunajaran').doc(idTahunAjaran!)
        .collection('catatansiswa').doc(docIdCatatan);

    // Update field yang sesuai
    await catatanDocRef.update({
      fieldToUpdate: tanggapanC.text,
    });

    Get.back(); // Tutup dialog
    Get.snackbar("Sukses", "Tanggapan berhasil disimpan.");
    tanggapanC.clear();

  } catch (e) {
    print("error : $e");
    Get.snackbar("Error", "Gagal menyimpan tanggapan: ${e.toString()}");
  }
}
}