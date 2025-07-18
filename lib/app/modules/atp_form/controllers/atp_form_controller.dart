// app/controller/atp_form_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../models/atp_model.dart';
import '../../perangkat_ajar/controllers/perangkat_ajar_controller.dart';
import '../../../modules/home/controllers/home_controller.dart';

class AtpFormController extends GetxController {
  // Dapatkan controller utama untuk memanggil fungsi save/update
  final PerangkatAjarController _perangkatAjarController = Get.find<PerangkatAjarController>();
  final HomeController _homeController = Get.find<HomeController>();
  var uuid = Uuid();

  // State untuk menentukan mode 'tambah' atau 'edit'
  RxBool isEditMode = false.obs;
  AtpModel? originalAtp; // Simpan data asli jika mode edit

  // --- TextEditingControllers untuk data utama ATP ---
  late TextEditingController capaianPembelajaranC;
  late TextEditingController mapelC;
  late TextEditingController faseC;
  late TextEditingController kelasC;

  // --- State untuk Unit Pembelajaran ---
  // Ini adalah "jantung" dari form kita. UI akan me-render berdasarkan list ini.
  RxList<UnitPembelajaranForm> unitPembelajaranForms = <UnitPembelajaranForm>[].obs;

  @override
  void onInit() {
    super.onInit();
    
    // Inisialisasi semua controller teks
    capaianPembelajaranC = TextEditingController();
    mapelC = TextEditingController();
    faseC = TextEditingController();
    kelasC = TextEditingController();

    // Cek apakah kita menerima argumen (data ATP untuk diedit)
    if (Get.arguments != null && Get.arguments is AtpModel) {
      isEditMode.value = true;
      originalAtp = Get.arguments as AtpModel;
      // Isi form dengan data yang ada
      _fillFormWithData(originalAtp!);
    } else {
      // Mode Tambah: Isi dengan data default dari user
      _fillWithDefaultData();
    }
  }

  void _fillFormWithData(AtpModel atp) {
    capaianPembelajaranC.text = atp.capaianPembelajaran;
    mapelC.text = atp.namaMapel;
    faseC.text = atp.fase;
    kelasC.text = atp.kelas.toString();
    
    // Konversi setiap UnitPembelajaran menjadi UnitPembelajaranForm yang bisa diedit
    unitPembelajaranForms.value = atp.unitPembelajaran
      .map((unit) => UnitPembelajaranForm.fromModel(unit))
      .toList();
  }
  
  void _fillWithDefaultData() {
    // Ambil data default dari home controller, contoh:
    mapelC.text = "Bahasa Arab"; // Ganti dengan mapel yang diajar guru
    faseC.text = "C"; // Ganti dengan fase kelas yang diajar
    kelasC.text = "5"; // Ganti dengan kelas yang diajar
  }
  
  // --- Fungsi untuk mengelola Unit Pembelajaran ---
  void addUnitPembelajaran() {
    unitPembelajaranForms.add(UnitPembelajaranForm());
  }

  void removeUnitPembelajaran(int index) {
    unitPembelajaranForms.removeAt(index);
  }

  // --- Fungsi Puncak: SIMPAN DATA ---
   Future<void> saveAtp() async {
    if (capaianPembelajaranC.text.isEmpty || unitPembelajaranForms.isEmpty) {
      Get.snackbar("Error", "Capaian Pembelajaran dan minimal 1 Unit Pembelajaran harus diisi.", 
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Ambil nama penyusun yang benar dari HomeController secara asynchronous
    final userSnapshot = await _homeController.userStream().first;
    final namaPenyusun = userSnapshot.data()?['nama'] ?? 'Guru';

    if (isEditMode.value) {
      // LOGIKA UPDATE
      final updatedAtp = AtpModel(
        idAtp: originalAtp!.idAtp,
        createdAt: originalAtp!.createdAt,
        capaianPembelajaran: capaianPembelajaranC.text,
        namaMapel: mapelC.text,
        fase: faseC.text,
        kelas: int.tryParse(kelasC.text) ?? 0,
        unitPembelajaran: unitPembelajaranForms.map((form) => form.toModel()).toList(),
        idSekolah: _homeController.idSekolah,
        idPenyusun: _homeController.idUser,
        namaPenyusun: namaPenyusun, // Gunakan variabel yang sudah diambil
        idTahunAjaran: _homeController.idTahunAjaran.value!,
        lastModified: Timestamp.now(), 
      );
      _perangkatAjarController.updateAtp(updatedAtp);
    } else {
      // LOGIKA CREATE
      final newAtp = AtpModel(
        capaianPembelajaran: capaianPembelajaranC.text,
        namaMapel: mapelC.text,
        fase: faseC.text,
        kelas: int.tryParse(kelasC.text) ?? 0,
        unitPembelajaran: unitPembelajaranForms.map((form) => form.toModel()).toList(),
        idSekolah: _homeController.idSekolah,
        idPenyusun: _homeController.idUser,
        namaPenyusun: namaPenyusun, // Gunakan variabel yang sudah diambil
        idTahunAjaran: _homeController.idTahunAjaran.value!,
        idAtp: '',
        createdAt: Timestamp.now(),
        lastModified: Timestamp.now(),
      );
      _perangkatAjarController.createAtp(newAtp);
    }
  }

  @override
  void onClose() {
    // Jangan lupa dispose semua controller teks
    capaianPembelajaranC.dispose();
    mapelC.dispose();
    faseC.dispose();
    kelasC.dispose();
    // Dispose semua controller di dalam unit
    for (var unitForm in unitPembelajaranForms) {
      unitForm.dispose();
    }
    super.onClose();
  }
}


// Helper class untuk mengelola state form per Unit Pembelajaran
class UnitPembelajaranForm {
  late TextEditingController lingkupMateriC;
  late TextEditingController jenisTeksC;
  late TextEditingController gramatikaC;
  late TextEditingController alokasiWaktuC;
  RxList<String> tujuanPembelajaran = <String>[].obs;
  RxList<String> alurPembelajaran = <String>[].obs;

  UnitPembelajaranForm() {
    lingkupMateriC = TextEditingController();
    jenisTeksC = TextEditingController();
    gramatikaC = TextEditingController();
    alokasiWaktuC = TextEditingController();
  }
  
  // Konversi dari model ke form (untuk mode edit)
  factory UnitPembelajaranForm.fromModel(UnitPembelajaran model) {
    final form = UnitPembelajaranForm();
    form.lingkupMateriC.text = model.lingkupMateri;
    form.jenisTeksC.text = model.jenisTeks;
    form.gramatikaC.text = model.gramatika;
    form.alokasiWaktuC.text = model.alokasiWaktu;
    form.tujuanPembelajaran.value = List<String>.from(model.tujuanPembelajaran);
    form.alurPembelajaran.value = model.alurPembelajaran.map((e) => e.deskripsi).toList();
    return form;
  }

  // Konversi dari form kembali ke model (untuk disimpan)
  UnitPembelajaran toModel() {
    return UnitPembelajaran(
      idUnit: Uuid().v4(), // Generate id baru setiap save
      urutan: 0, // Anda bisa tambahkan logika urutan jika perlu
      lingkupMateri: lingkupMateriC.text,
      jenisTeks: jenisTeksC.text,
      gramatika: gramatikaC.text,
      alokasiWaktu: alokasiWaktuC.text,
      tujuanPembelajaran: List<String>.from(tujuanPembelajaran),
      alurPembelajaran: alurPembelajaran
          .asMap()
          .entries
          .map((entry) => AlurPembelajaran(urutan: entry.key + 1, deskripsi: entry.value))
          .toList(),
    );
  }

  // Method untuk membersihkan controller saat unit dihapus
  void dispose() {
    lingkupMateriC.dispose();
    jenisTeksC.dispose();
    gramatikaC.dispose();
    alokasiWaktuC.dispose();
  }
}