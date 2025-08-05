// File: lib/app/modules/admin_manajemen/controllers/laporan_ekskul_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/home/controllers/home_controller.dart';
import '../../../models/laporan_ekskul_model.dart';
import '../../../models/siswa_model.dart';
import '../../../models/laporan_ekskul_model.dart';
import '../views/laporan_detail_view.dart';

class LaporanEkskulController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  final RxBool isLoading = false.obs;
  final RxList<LaporanEkskulModel> daftarLaporan = <LaporanEkskulModel>[].obs;

  // --- STATE BARU UNTUK HALAMAN DETAIL ---
  final RxBool isLoadingDetail = false.obs;
  // Menyimpan info ekskul yang sedang dilihat detailnya
  final Rxn<LaporanEkskulModel> laporanTerpilih = Rxn<LaporanEkskulModel>();
  // Menyimpan daftar anggota dari ekskul yang dipilih
  final RxList<SiswaModel> daftarAnggotaDetail = <SiswaModel>[].obs;
  // Menyimpan data yang sudah diproses untuk chart
  final RxMap<String, int> sebaranKelas = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    generateLaporan();
  }

  Future<void> openDetailLaporan(LaporanEkskulModel laporan) async {
    // 1. Set state awal dan navigasi ke halaman detail
    isLoadingDetail.value = true;
    laporanTerpilih.value = laporan;
    daftarAnggotaDetail.clear();
    sebaranKelas.clear();
    Get.to(() => const LaporanDetailView());

    final idSekolah = homeC.idSekolah;
    final idTahunAjaran = homeC.idTahunAjaran.value!;

    try {
      // 2. Ambil semua dokumen anggota dari sub-koleksi ekskul yang dipilih
      final anggotaSnapshot = await _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('ekstrakurikuler').doc(laporan.instanceEkskulId)
          .collection('anggota')
          .orderBy('namaSiswa')
          .get();
      
      final List<SiswaModel> anggota = [];
      final Map<String, int> sebaran = {};

      // 3. Loop melalui setiap anggota untuk memproses data
      for (final doc in anggotaSnapshot.docs) {
        final data = doc.data();
        final siswa = SiswaModel(
          nisn: doc.id,
          nama: data['namaSiswa'] ?? '',
          idKelas: data['idKelasSiswa'] ?? '',
          namaKelas: data['kelasSiswa'] ?? 'Tanpa Kelas',
        );
        anggota.add(siswa);

        // --- Proses agregasi untuk chart ---
        final namaKelas = siswa.namaKelas;
        sebaran[namaKelas] = (sebaran[namaKelas] ?? 0) + 1;
      }

      // 4. Update state dengan data yang sudah siap
      daftarAnggotaDetail.value = anggota;
      sebaranKelas.value = sebaran;

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat detail anggota: $e");
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<void> generateLaporan() async {
    isLoading.value = true;
    final idSekolah = homeC.idSekolah;
    final idTahunAjaran = homeC.idTahunAjaran.value;
    if (idTahunAjaran == null) {
      Get.snackbar("Error", "Tahun ajaran tidak aktif.");
      isLoading.value = false;
      return;
    }

    try {
      // 1. Ambil SEMUA instansi ekskul di tahun ajaran ini (tetap sama)
      final ekskulSnapshot = await _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('ekstrakurikuler')
          .get();

      final List<QueryDocumentSnapshot> ekskulDocs = ekskulSnapshot.docs;
      final List<LaporanEkskulModel> laporanHasil = [];

      // 2. Loop untuk setiap ekskul
      for (final ekskulDoc in ekskulDocs) {
        final ekskulData = ekskulDoc.data() as Map<String, dynamic>;
        
        // --- MANUVER PERBAIKAN DI SINI ---
        // 3. Lakukan query .get() pada sub-koleksi 'anggota' lalu hitung ukurannya
        final anggotaSnapshot = await ekskulDoc.reference.collection('anggota').get();
        final int jumlahAnggota = anggotaSnapshot.size; // Gunakan .size
        // --- AKHIR PERBAIKAN ---

        // Ambil info nama master untuk nama yang lebih lengkap
        final masterEkskulRef = ekskulData['masterEkskulRef'];
        String namaMaster = 'Ekskul Dihapus';
        if (masterEkskulRef != null) {
          final masterDoc = await _firestore.collection('master_ekskul').doc(masterEkskulRef).get();
          if (masterDoc.exists) {
            namaMaster = masterDoc.data()?['namaMaster'] ?? 'Tanpa Nama';
          }
        }
        
        laporanHasil.add(
          LaporanEkskulModel(
            instanceEkskulId: ekskulDoc.id,
            namaEkskulLengkap: "$namaMaster - ${ekskulData['namaTampilan'] ?? ''}",
              namaPembina: List<String>.from((ekskulData['pembina'] as List? ?? []).map((p) => p['nama'])),
            jumlahAnggota: jumlahAnggota,
          ),
        );
      }

      // 4. Sortir laporan berdasarkan jumlah anggota terbanyak (tetap sama)
      laporanHasil.sort((a, b) => b.jumlahAnggota.compareTo(a.jumlahAnggota));
      
      daftarLaporan.value = laporanHasil;

    } catch (e) {
      Get.snackbar("Error", "Gagal membuat laporan: $e");
    } finally {
      isLoading.value = false;
    }
  }
}