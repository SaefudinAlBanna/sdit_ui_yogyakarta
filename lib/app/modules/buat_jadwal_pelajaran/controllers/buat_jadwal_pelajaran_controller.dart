import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/pelajaran_model.dart'; // Jika menggunakan model

class BuatJadwalPelajaranController extends GetxController {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // RxMap untuk menyimpan jadwal pelajaran per hari
  // Key: Nama Hari (String), Value: List pelajaran (RxList<Map<String, dynamic>>)
  final RxMap<String, RxList<Map<String, dynamic>>> jadwalPelajaran =
      <String, RxList<Map<String, dynamic>>>{}.obs;

  // Hari yang sedang dipilih untuk ditampilkan/diedit
  RxString selectedHari = 'Senin'.obs;

  // Daftar hari
  List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  RxBool isLoading = false.obs;

  // --- STATE BARU UNTUK KELAS ---
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final RxString selectedKelasId = ''.obs;

  // ID Sekolah dan Tahun Ajaran (bisa didapatkan dari parameter atau inputan lain)
  // Untuk contoh ini kita hardcode dulu, idealnya ini dinamis
  String idSekolah = "20404148";
  // String tahunAjaran = "2024-2025";

  @override
  void onInit() {
    super.onInit();
    // Inisialisasi jadwalPelajaran dengan list kosong untuk setiap hari
    for (var hari in daftarHari) {
      jadwalPelajaran[hari] = <Map<String, dynamic>>[].obs;
    }
    // Anda bisa tambahkan logic untuk load data jika sudah ada
    // loadJadwalFromFirestore();
    _fetchDaftarKelas();
  }

  /// FUNGSI BARU: Mengambil daftar kelas untuk dropdown
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
          'nama': doc.data()['namakelas'] ?? 'Tanpa Nama', // Sesuaikan field 'namakelas'
        }).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil daftar kelas: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// FUNGSI BARU: Dipanggil saat dropdown kelas berubah
  Future<void> onKelasChanged(String? kelasId) async {
    if (kelasId == null || kelasId.isEmpty) return;
    selectedKelasId.value = kelasId;
    // Otomatis muat jadwal untuk kelas yang baru dipilih
    await loadJadwalFromFirestore();
  }
  
  void changeSelectedHari(String? hari) {
    if (hari != null) {
      selectedHari.value = hari;
    }
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

  // Menambah slot pelajaran baru untuk hari yang dipilih
  void tambahPelajaran() {
    final listPelajaranHariIni = jadwalPelajaran[selectedHari.value];
    if (listPelajaranHariIni != null) {
      listPelajaranHariIni.add({
        // 'jamKe': listPelajaranHariIni.length + 1,
          'jamKe': jadwalPelajaran[selectedHari.value]!.length + 1,
        'mapel': '',
        'mulai': '00:00', // Default
        'selesai': '00:00', // Default
      });
    }
  }

  // Menghapus pelajaran dari hari yang dipilih berdasarkan index
  void hapusPelajaran(int index) async {
    final listPelajaranHariIni = jadwalPelajaran[selectedHari.value];
    if (listPelajaranHariIni != null && index < listPelajaranHariIni.length) {
      listPelajaranHariIni.removeAt(index);
      // Update jamKe setelah menghapus
      for (int i = 0; i < listPelajaranHariIni.length; i++) {
        listPelajaranHariIni[i]['jamKe'] = i + 1;
      }
      listPelajaranHariIni.refresh();
      await simpanJadwalKeFirestore();
    }
  }

  // Mengupdate detail pelajaran (mapel, mulai, selesai)
  void updatePelajaranDetail(int index, String key, String value) {
    final listPelajaranHariIni = jadwalPelajaran[selectedHari.value];
    if (listPelajaranHariIni != null && index < listPelajaranHariIni.length) {
      listPelajaranHariIni[index][key] = value;
      // Perlu refresh list agar UI terupdate jika map dalam list diubah
      listPelajaranHariIni.refresh();
    }
  }

  // Fungsi untuk memilih waktu
  Future<void> pilihWaktu(BuildContext context, int index, String jenisWaktu) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      updatePelajaranDetail(index, jenisWaktu, formattedTime);
    }
  }

  /// DIUBAH: Fungsi simpan sekarang memerlukan ID Kelas
  Future<void> simpanJadwalKeFirestore() async {
    if (selectedKelasId.value.isEmpty) {
      Get.snackbar('Perhatian', 'Silakan pilih kelas terlebih dahulu.');
      return;
    }

    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    isLoading.value = true;

    try {
      Map<String, List<Map<String, dynamic>>> dataToSave = {};
      jadwalPelajaran.forEach((hari, listPelajaran) {
        dataToSave[hari] = listPelajaran.map((p) => Map<String, dynamic>.from(p)).toList();
      });

      // --- PATH BARU YANG DINAMIS BERDASARKAN KELAS ---
      DocumentReference docRef = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelastahunajaran')
          .doc(selectedKelasId.value); // <-- Menggunakan ID kelas yang dipilih

      // Menyimpan data jadwal ke dalam field 'jadwal' di dokumen kelas tersebut
      await docRef.set({'jadwal': dataToSave}, SetOptions(merge: true));

      Get.snackbar('Sukses', 'Jadwal pelajaran berhasil disimpan!', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan jadwal: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// DIUBAH: Fungsi load sekarang memerlukan ID Kelas
  Future<void> loadJadwalFromFirestore() async {
    if (selectedKelasId.value.isEmpty) {
      // Jika tidak ada kelas dipilih, kosongkan jadwal
      clearJadwal();
      return;
    }

    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    isLoading.value = true;

    try {
      // --- PATH BARU YANG DINAMIS BERDASARKAN KELAS ---
      DocumentSnapshot docSnap = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelastahunajaran')
          .doc(selectedKelasId.value)
          .get();

      clearJadwal(); // Selalu kosongkan jadwal sebelum memuat yang baru

      if (docSnap.exists && docSnap.data() != null) {
        final docData = docSnap.data() as Map<String, dynamic>;
        // Ambil data dari field 'jadwal'
        if (docData.containsKey('jadwal')) {
          Map<String, dynamic> dataJadwal = docData['jadwal'];
          dataJadwal.forEach((hari, listPelajaranData) {
            if (jadwalPelajaran.containsKey(hari) && listPelajaranData is List) {
              jadwalPelajaran[hari]!.value = List<Map<String, dynamic>>.from(
                listPelajaranData.map((item) => Map<String, dynamic>.from(item as Map))
              );
            }
          });
          Get.snackbar('Info', 'Jadwal berhasil dimuat.', snackPosition: SnackPosition.BOTTOM);
        } else {
           Get.snackbar('Info', 'Belum ada jadwal tersimpan untuk kelas ini.', snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        Get.snackbar('Info', 'Belum ada jadwal tersimpan untuk kelas ini.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat jadwal: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void clearJadwal() {
    for (var hari in daftarHari) {
      jadwalPelajaran[hari]?.clear();
    }
  }
  
  
}