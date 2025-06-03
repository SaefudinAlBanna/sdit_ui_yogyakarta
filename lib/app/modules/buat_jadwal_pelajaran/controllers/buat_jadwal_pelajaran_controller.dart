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
  List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  RxBool isLoading = false.obs;

  // ID Sekolah dan Tahun Ajaran (bisa didapatkan dari parameter atau inputan lain)
  // Untuk contoh ini kita hardcode dulu, idealnya ini dinamis
  String idSekolah = "20404148";
  String tahunAjaran = "2024-2025";

  @override
  void onInit() {
    super.onInit();
    // Inisialisasi jadwalPelajaran dengan list kosong untuk setiap hari
    for (var hari in daftarHari) {
      jadwalPelajaran[hari] = <Map<String, dynamic>>[].obs;
    }
    // Anda bisa tambahkan logic untuk load data jika sudah ada
    // loadJadwalFromFirestore();
  }

  void changeSelectedHari(String? hari) {
    if (hari != null) {
      selectedHari.value = hari;
    }
  }

  // Menambah slot pelajaran baru untuk hari yang dipilih
  void tambahPelajaran() {
    final listPelajaranHariIni = jadwalPelajaran[selectedHari.value];
    if (listPelajaranHariIni != null) {
      listPelajaranHariIni.add({
        'jamKe': listPelajaranHariIni.length + 1,
        'mapel': '',
        'mulai': '00:00', // Default
        'selesai': '00:00', // Default
      });
    }
  }

  // Menghapus pelajaran dari hari yang dipilih berdasarkan index
  void hapusPelajaran(int index) {
    final listPelajaranHariIni = jadwalPelajaran[selectedHari.value];
    if (listPelajaranHariIni != null && index < listPelajaranHariIni.length) {
      listPelajaranHariIni.removeAt(index);
      // Update jamKe setelah menghapus
      for (int i = 0; i < listPelajaranHariIni.length; i++) {
        listPelajaranHariIni[i]['jamKe'] = i + 1;
      }
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

  // Menyimpan seluruh jadwal ke Firestore
  Future<void> simpanJadwalKeFirestore() async {
    isLoading.value = true;
    try {
      // Konversi RxMap dan RxList menjadi Map dan List biasa
      Map<String, List<Map<String, dynamic>>> dataToSave = {};
      jadwalPelajaran.forEach((hari, listPelajaran) {
        // Pastikan hanya menyimpan hari yang ada pelajarannya atau sesuai kebutuhan
        // if (listPelajaran.isNotEmpty) {
          dataToSave[hari] = listPelajaran.map((p) => Map<String, dynamic>.from(p)).toList();
        // }
      });

      // Path ke dokumen di Firestore
      DocumentReference docRef = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(tahunAjaran)
          .collection('jadwalpelajaran')
          .doc(tahunAjaran);

      await docRef.set(dataToSave); // Menggunakan set untuk overwrite atau create

      Get.snackbar('Sukses', 'Jadwal pelajaran berhasil disimpan!',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan jadwal: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // (Opsional) Fungsi untuk memuat jadwal dari Firestore
  Future<void> loadJadwalFromFirestore() async {
    isLoading.value = true;
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
        Map<String, dynamic> data = docSnap.data() as Map<String, dynamic>;
        data.forEach((hari, listPelajaranData) {
          if (jadwalPelajaran.containsKey(hari) && listPelajaranData is List) {
            // Konversi List<dynamic> (dari firestore) menjadi List<Map<String, dynamic>>
            jadwalPelajaran[hari]!.value = List<Map<String, dynamic>>.from(
              listPelajaranData.map((item) => Map<String, dynamic>.from(item as Map))
            );
          }
        });
        // Jika ada hari yang dipilih, refresh untuk memastikan UI update
        if (jadwalPelajaran.containsKey(selectedHari.value)) {
          jadwalPelajaran[selectedHari.value]!.refresh();
        }
        Get.snackbar('Info', 'Jadwal berhasil dimuat.', snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Info', 'Belum ada jadwal tersimpan untuk tahun ajaran ini.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat jadwal: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}