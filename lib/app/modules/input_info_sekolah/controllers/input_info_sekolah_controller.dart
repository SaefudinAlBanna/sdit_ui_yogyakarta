// controllers/input_info_sekolah_controller.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class InputInfoSekolahController extends GetxController {
  // --- UI Controllers ---
  final TextEditingController judulC = TextEditingController();
  final TextEditingController inputC = TextEditingController();

  final String _bucketName = 'info.sekolah';

  // --- Services ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final supabase.SupabaseClient supabaseClient = supabase.Supabase.instance.client;

  // --- State ---
  final Rx<File?> imageFile = Rx<File?>(null);
  final RxBool isLoading = false.obs;
  String? idTahunAjaran;
  final String idSekolah = "20404148";
  
  @override
  void onInit() {
    super.onInit();
    _getTahunAjaran();
  }

   Future<void> _getTahunAjaran() async {
    try {
      final snapshot = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .orderBy('namatahunajaran', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        String tahunAjaranTerakhir = snapshot.docs.first.data()['namatahunajaran'];
        idTahunAjaran = tahunAjaranTerakhir.replaceAll("/", "-");
      } else {
        // Handle jika tidak ada tahun ajaran sama sekali
        Get.snackbar("Error Kritis", "Data Tahun Ajaran tidak ditemukan.");
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mendapatkan data tahun ajaran: $e");
    }
  }

  /// Memilih gambar dari galeri atau kamera
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        imageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memilih gambar: $e');
    }
  }
  
  void removeImage() {
    imageFile.value = null;
  }

  /// Mengupload gambar ke Supabase Storage
  Future<String?> _uploadImageToSupabase(File file, String docId) async {
    try {
       final String filePath = '$_bucketName/$docId.jpg';
      await supabaseClient.storage.from(_bucketName).upload( // <-- Gunakan konstanta
        filePath,
        file,
        fileOptions: const supabase.FileOptions(cacheControl: '3600', upsert: true),
      );
      return supabaseClient.storage.from(_bucketName).getPublicUrl(filePath); // <-- Gunakan konstanta
    } catch (e) {
      Get.snackbar('Upload Gagal', 'Terjadi kesalahan saat mengupload gambar, Maksimal 200 KB.');
      print("pesan error Upload Gagal = $e");
      return null;
    }
  }

  /// Menyimpan semua informasi ke Firestore
  Future<void> simpanInfo() async {
    if (judulC.text.trim().isEmpty) {
      Get.snackbar('Validasi Gagal', 'Judul informasi tidak boleh kosong.');
      return;
    }
    if (inputC.text.trim().isEmpty) {
      Get.snackbar('Validasi Gagal', 'Isi informasi tidak boleh kosong.');
      return;
    }
    
     // --- PENGECEKAN KEAMANAN TAMBAHAN ---
    if (idTahunAjaran == null) {
      Get.snackbar("Error", "Data tahun ajaran belum siap. Mohon coba lagi sesaat.");
      return;
    }
    
    isLoading.value = true;
    
    try {
      final user = auth.currentUser;
      if (user == null || idTahunAjaran == null) {
        throw Exception("Sesi tidak valid atau tahun ajaran tidak ditemukan.");
      }

      // 1. Buat ID unik untuk dokumen Firestore
      final String docId = '${DateTime.now().millisecondsSinceEpoch}-${user.uid}';

      // 2. Upload gambar jika ada, dan dapatkan URL-nya
      String? imageUrl;
      if (imageFile.value != null) {
        imageUrl = await _uploadImageToSupabase(imageFile.value!, docId);
        if (imageUrl == null) { // Jika upload gagal, hentikan proses
          isLoading.value = false;
          return;
        }
      }

      // 3. Ambil data pegawai (penulis)
      final docPegawai = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(user.uid).get();
      final String namaPenginput = docPegawai.data()?['alias'] ?? 'Admin';
      final String jabatanPenginput = docPegawai.data()?['role'] ?? 'Staf';

      // 4. Siapkan data untuk disimpan
      final Map<String, dynamic> dataToSave = {
        'iduser': user.uid,
        'idsekolah': idSekolah,
        'namapenginput': namaPenginput,
        'jabatanpenginput': jabatanPenginput,
        'judulinformasi': judulC.text.trim(),
        'informasisekolah': inputC.text.trim(),
        'tanggalinput': DateTime.now().toIso8601String(),
        'imageUrl': imageUrl ?? '', // Simpan URL atau string kosong
      };

      // 5. Simpan ke Firestore
      await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('informasisekolah').doc(docId)
          .set(dataToSave);
      
      Get.back();
      Get.snackbar('Sukses', 'Informasi berhasil dipublikasikan!', backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      
      Get.snackbar('Error', 'Gagal menyimpan informasi: $e');
      print("pesan error : $e");
    } finally {
      isLoading.value = false;
    }
  }
}


