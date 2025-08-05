import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/home/controllers/home_controller.dart';
import 'package:uuid/uuid.dart';
import '../../../models/pengumuman_model.dart';
import '../../../models/siswa_model.dart';

class PembinaEkskulController extends GetxController {
  final String instanceEkskulId;
  PembinaEkskulController({required this.instanceEkskulId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final Uuid _uuid = const Uuid();

  // State
  final RxBool isLoading = false.obs;
  
  // State Pengumuman
  final RxList<PengumumanModel> daftarPengumuman = <PengumumanModel>[].obs;
  final TextEditingController judulC = TextEditingController();
  final TextEditingController isiC = TextEditingController();

  // State Anggota
  final RxList<SiswaModel> daftarAnggota = <SiswaModel>[].obs;

  // --- STATE BARU UNTUK FORM CATATAN MASSAL ---
  final TextEditingController catatanMassalC = TextEditingController();
  final Rxn<String> kategoriMassal = Rxn<String>();
  final Rxn<DateTime> tanggalMassal = Rxn<DateTime>(DateTime.now());
  final List<String> kategoriOptions = ['Prestasi', 'Keaktifan', 'Sikap', 'Pelanggaran', 'Umum'];

   final RxBool isModeInputCepatAktif = false.obs;
  // State untuk menampung siswa yang dipilih di mode input cepat
  final RxList<SiswaModel> siswaTerpilihUntukCatatan = <SiswaModel>[].obs;

  // Path Collections
  late final CollectionReference _pengumumanRef;
  late final CollectionReference _anggotaRef;
  late final CollectionReference _catatanPrestasiRef; // <-- Path Baru

  
  @override
  void onInit() {
    super.onInit();
    final idSekolah = homeC.idSekolah;
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    
    final ekskulDocRef = _firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('ekstrakurikuler').doc(instanceEkskulId);

    // Inisialisasi semua path dari satu referensi utama
    _pengumumanRef = ekskulDocRef.collection('pengumuman');
    _anggotaRef = ekskulDocRef.collection('anggota');
    _catatanPrestasiRef = ekskulDocRef.collection('catatan_prestasi'); // <-- Inisialisasi
        
    fetchPengumuman();
    fetchAnggota();
  }

  /// Mengaktifkan atau menonaktifkan mode input cepat.
  void toggleInputCepat(bool isActive) {
    isModeInputCepatAktif.value = isActive;
    // Selalu bersihkan pilihan saat mode diubah
    siswaTerpilihUntukCatatan.clear();
    catatanMassalC.clear();
    kategoriMassal.value = null;
    tanggalMassal.value = DateTime.now();
  }

  /// Menangani pemilihan siswa di mode input cepat.
  void toggleSiswaTerpilih(SiswaModel siswa, bool isSelected) {
    if (isSelected) {
      siswaTerpilihUntukCatatan.add(siswa);
    } else {
      siswaTerpilihUntukCatatan.removeWhere((s) => s.nisn == siswa.nisn);
    }
  }

  /// Menggantikan `saveCatatanMassal`. Menyimpan catatan hanya untuk siswa yang dipilih.
  Future<void> saveCatatanUntukTerpilih() async {
    // 1. Validasi Input Form dan Seleksi
    if (catatanMassalC.text.isEmpty || kategoriMassal.value == null) {
      Get.snackbar("Peringatan", "Kategori dan Deskripsi wajib diisi.");
      return;
    }
    if (siswaTerpilihUntukCatatan.isEmpty) {
      Get.snackbar("Info", "Tidak ada siswa yang dipilih.");
      return;
    }

    final user = await _firestore.collection('Sekolah').doc(homeC.idSekolah).collection('pegawai').doc(homeC.idUser).get();
    final namaPembina = user.data()?['nama'] ?? 'Pembina';
    final batch = _firestore.batch();
    
    // Loop hanya untuk siswa yang ada di `siswaTerpilihUntukCatatan`
    for (final anggota in siswaTerpilihUntukCatatan) {
      final idCatatanBaru = _uuid.v4();
      final catatanRef = _catatanPrestasiRef.doc(idCatatanBaru);
      final data = { /* ... data sama seperti sebelumnya ... */ };
      batch.set(catatanRef, data);
    }
    
    try {
      await batch.commit();
      Get.snackbar(
        "Berhasil", 
        "Catatan berhasil ditambahkan untuk ${siswaTerpilihUntukCatatan.length} anggota terpilih.",
        snackPosition: SnackPosition.BOTTOM
      );
      // Reset form dan pilihan setelah berhasil
      siswaTerpilihUntukCatatan.clear();
      catatanMassalC.clear();
      
    } catch (e) {
      Get.snackbar("Error Kritis", "Gagal menyimpan catatan: $e");
    }
  }

  Future<void> fetchAnggota() async {
    isLoading.value = true;
    try {
      final snapshot = await _anggotaRef.orderBy('namaSiswa').get();
      // Kita buat SiswaModel sederhana dari data di sub-koleksi anggota
      daftarAnggota.value = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SiswaModel(
          nisn: doc.id,
          nama: data['namaSiswa'] ?? '',
          idKelas: data['idKelasSiswa'] ?? '',
          namaKelas: data['kelasSiswa'] ?? '',
        );
      }).toList();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar anggota: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPengumuman() async {
    isLoading.value = true;
    try {
      final snapshot = await _pengumumanRef.orderBy('tanggalDibuat', descending: true).get();
      daftarPengumuman.value = snapshot.docs
          .map((doc) => PengumumanModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat pengumuman: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePengumuman({String? pengumumanId}) async {
    if (judulC.text.isEmpty || isiC.text.isEmpty) {
      Get.snackbar("Peringatan", "Judul dan Isi tidak boleh kosong.");
      return;
    }

    final isUpdate = pengumumanId != null;
    final id = pengumumanId ?? _uuid.v4();
    final now = Timestamp.now();
    
    // Ambil data pembina yang sedang login
    final user = await _firestore.collection('Sekolah').doc(homeC.idSekolah).collection('pegawai').doc(homeC.idUser).get();
    final namaPembina = user.data()?['nama'] ?? 'Pembina';

    final data = {
      'judul': judulC.text,
      'isi': isiC.text,
      'dibuatOlehUid': homeC.idUser,
      'dibuatOlehNama': namaPembina,
      if (!isUpdate) 'tanggalDibuat': now,
      'tanggalDiubah': now,
    };
    
    try {
      if (isUpdate) {
        await _pengumumanRef.doc(id).update(data);
      } else {
        await _pengumumanRef.doc(id).set(data);
      }
      
      Get.back(); // Tutup dialog
      fetchPengumuman(); // Refresh list
      Get.snackbar("Berhasil", "Pengumuman berhasil disimpan.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan pengumuman: $e");
    }
  }

  Future<void> deletePengumuman(String pengumumanId) async {
    try {
      await _pengumumanRef.doc(pengumumanId).delete();
      fetchPengumuman(); // Refresh list
      Get.snackbar("Berhasil", "Pengumuman berhasil dihapus.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus pengumuman: $e");
    }
  }
}