import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/home/controllers/home_controller.dart';
import 'package:uuid/uuid.dart';

class ManajemenTahunAjaranEkskulController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final Uuid _uuid = const Uuid();

  final RxBool isLoading = false.obs;
  
  // State untuk menampilkan info di UI
  final RxString tahunAjaranSumber = ''.obs;
  final RxString tahunAjaranTujuan = ''.obs;
  final RxString idTahunAjaranTujuan = ''.obs;
  final RxBool isReadyForCopy = false.obs;

  @override
  void onInit() {
    super.onInit();
    persiapkanInfoDuplikasi();
  }

  void persiapkanInfoDuplikasi() {
    final sumber = homeC.idTahunAjaran.value;
    if (sumber != null) {
      tahunAjaranSumber.value = sumber.replaceAll('-', '/');
      // Logika sederhana untuk membuat nama tahun ajaran berikutnya
      final tahun = sumber.split('-').map(int.parse).toList();
      final tahunBaru = "${tahun[0] + 1}-${tahun[1] + 1}";
      tahunAjaranTujuan.value = tahunBaru.replaceAll('-', '/');
      idTahunAjaranTujuan.value = tahunBaru;
      isReadyForCopy.value = true;
    }
  }

  Future<void> salinDataEkskul() async {
    if (!isReadyForCopy.value) {
      Get.snackbar("Gagal", "Informasi tahun ajaran tidak valid.");
      return;
    }

    isLoading.value = true;
    final idSekolah = homeC.idSekolah;
    final idSumber = homeC.idTahunAjaran.value!;
    final idTujuan = idTahunAjaranTujuan.value;
    
    try {
      // 1. Pastikan tahun ajaran tujuan sudah ada dokumennya
      final tujuanRef = _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTujuan);
      final tujuanDoc = await tujuanRef.get();
      if (!tujuanDoc.exists) {
        // Jika belum ada, buat dokumennya. Anda bisa tambahkan field lain jika perlu.
        await tujuanRef.set({'namatahunajaran': tahunAjaranTujuan.value});
      }
      
      // 2. Ambil semua ekskul dari tahun ajaran sumber
      final ekskulSumberSnapshot = await _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idSumber)
          .collection('ekstrakurikuler')
          .get();

      if (ekskulSumberSnapshot.docs.isEmpty) {
        Get.snackbar("Info", "Tidak ada data ekskul untuk disalin.");
        isLoading.value = false;
        return;
      }
      
      // 3. Gunakan WriteBatch untuk menyalin semua data
      final batch = _firestore.batch();
      int jumlahDisalin = 0;

      for (final doc in ekskulSumberSnapshot.docs) {
        var data = doc.data();
        
        // Data BARU yang akan disalin
        var dataBaru = {
          'masterEkskulRef': data['masterEkskulRef'],
          'namaTampilan': data['namaTampilan'],
          'idTahunAjaran': idTujuan, // <-- Gunakan ID tahun ajaran BARU
          'pembina': data['pembina'], // Asumsi pembina masih sama
          'hariJadwal': data['hariJadwal'],
          'jamMulai': data['jamMulai'],
          'jamSelesai': data['jamSelesai'],
          'lokasi': data['lokasi'],
          'status': 'Aktif', // Selalu set sebagai aktif
        };
        
        // Buat referensi dokumen BARU di tahun ajaran tujuan
        final refBaru = tujuanRef.collection('ekstrakurikuler').doc(doc.id); // Bisa pakai ID lama atau baru
        batch.set(refBaru, dataBaru);
        jumlahDisalin++;
      }
      
      // 4. Eksekusi batch
      await batch.commit();
      
      Get.defaultDialog(
        title: "Berhasil!",
        middleText: "$jumlahDisalin data ekstrakurikuler berhasil disalin ke tahun ajaran ${tahunAjaranTujuan.value}.\n\nHarap perbarui daftar pembina dan anggota secara manual.",
        textConfirm: "Luar Biasa",
        onConfirm: () => Get.back(),
      );

    } catch (e) {
      Get.snackbar("Error Kritis", "Proses penyalinan gagal: $e");
    } finally {
      isLoading.value = false;
    }
  }
}