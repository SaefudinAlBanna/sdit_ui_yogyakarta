// app/controller/modul_ajar_form_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../models/modul_ajar_model.dart';
import '../../perangkat_ajar/controllers/perangkat_ajar_controller.dart';
import '../../../modules/home/controllers/home_controller.dart';
import '../../../models/atp_model.dart';

import 'package:sdit_ui_yogyakarta/app/modules/perangkat_ajar/widgets/dialog_impor_tp.dart'; 

class ModulAjarFormController extends GetxController {
  final PerangkatAjarController _perangkatAjarController = Get.find<PerangkatAjarController>();
  final HomeController _homeController = Get.find<HomeController>();
  var uuid = Uuid();

  RxBool isEditMode = false.obs;
  ModulAjarModel? originalModul;

  // --- Controllers untuk data utama Modul Ajar ---
  late TextEditingController mapelC;
  late TextEditingController kelasC;
  late TextEditingController faseC;
  late TextEditingController alokasiWaktuC;
  late TextEditingController kompetensiAwalC;
  late TextEditingController modelPembelajaranC;
  late TextEditingController tujuanPembelajaranC;
  late TextEditingController pemahamanBermaknaC;

  // --- State untuk data list/dinamis ---
  RxList<String> profilPancasila = <String>[].obs;
  RxList<String> profilRahmatan = <String>[].obs;
  RxList<String> media = <String>[].obs;
  RxList<String> sumberBelajar = <String>[].obs;
  RxList<String> targetPesertaDidik = <String>[].obs;
  RxList<String> elemen = <String>[].obs;
  RxList<String> pertanyaanPemantik = <String>[].obs;
  
  // State untuk sesi pembelajaran
  RxList<SesiPembelajaranForm> sesiPembelajaranForms = <SesiPembelajaranForm>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();

    if (Get.arguments != null && Get.arguments is ModulAjarModel) {
      isEditMode.value = true;
      originalModul = Get.arguments as ModulAjarModel;
      _fillFormWithData(originalModul!);
    } else {
      _fillWithDefaultData();
    }
  }

  void _initializeControllers() {
    mapelC = TextEditingController();
    kelasC = TextEditingController();
    faseC = TextEditingController();
    alokasiWaktuC = TextEditingController();
    kompetensiAwalC = TextEditingController();
    modelPembelajaranC = TextEditingController();
    tujuanPembelajaranC = TextEditingController();
    pemahamanBermaknaC = TextEditingController();
  }

  // --- FUNGSI BARU UNTUK PROSES IMPOR ---
  Future<void> imporTujuanPembelajaran() async {
    // 1. Dapatkan controller perangkat ajar utama
    final perangkatAjarC = Get.find<PerangkatAjarController>();

    // 2. Cari ATP yang cocok berdasarkan mapel dan fase dari form yang sedang diisi
    final atpCocok = perangkatAjarC.daftarAtp.firstWhere(
      (atp) => atp.namaMapel == mapelC.text && atp.fase == faseC.text,
      orElse: () => AtpModel( /* Objek kosong sebagai penanda tidak ketemu */
        idAtp: '', idSekolah: '', idPenyusun: '', namaPenyusun: '', idTahunAjaran: '',
        namaMapel: '', fase: '', kelas: 0, capaianPembelajaran: '', createdAt: Timestamp.now(),
        lastModified: Timestamp.now(), unitPembelajaran: [],
      ),
    );

    // 3. Jika tidak ada ATP yang cocok, tampilkan pesan
    if (atpCocok.idAtp.isEmpty) {
      Get.snackbar("Informasi", "Tidak ditemukan ATP yang cocok untuk mata pelajaran dan fase ini.");
      return;
    }

    // 4. Jika ditemukan, tampilkan dialog untuk memilih unit pembelajaran
    final List<UnitPembelajaran>? hasilPilihan = await Get.dialog<List<UnitPembelajaran>>(
      DialogImporTp(units: atpCocok.unitPembelajaran), // Kirim daftar unit ke dialog
    );
    
    // 5. Proses hasil dari dialog
    if (hasilPilihan != null && hasilPilihan.isNotEmpty) {
      // Gabungkan semua tujuan pembelajaran dari unit yang dipilih menjadi satu string
      String teksTujuanGabungan = hasilPilihan
        .map((unit) => unit.tujuanPembelajaran.map((tp) => "• $tp").join('\n'))
        .join('\n\n'); // Beri spasi antar unit

      // Masukkan ke dalam text controller
      tujuanPembelajaranC.text = teksTujuanGabungan;
      Get.snackbar("Berhasil", "${hasilPilihan.length} unit berhasil diimpor.");
    }
  }
  
  void _fillFormWithData(ModulAjarModel modul) {
    mapelC.text = modul.mapel;
    kelasC.text = modul.kelas.toString();
    faseC.text = modul.fase;
    alokasiWaktuC.text = modul.alokasiWaktu;
    kompetensiAwalC.text = modul.kompetensiAwal;
    modelPembelajaranC.text = modul.modelPembelajaran;
    tujuanPembelajaranC.text = modul.tujuanPembelajaran;
    pemahamanBermaknaC.text = modul.pemahamanBermakna;
    
    profilPancasila.value = modul.profilPancasila;
    profilRahmatan.value = modul.profilRahmatan;
    media.value = modul.media;
    sumberBelajar.value = modul.sumberBelajar;
    targetPesertaDidik.value = modul.targetPesertaDidik;
    elemen.value = modul.elemen;
    pertanyaanPemantik.value = modul.pertanyaanPemantik;
    
    sesiPembelajaranForms.value = modul.kegiatanPembelajaran
        .map((sesi) => SesiPembelajaranForm.fromModel(sesi))
        .toList();
  }

  void _fillWithDefaultData() {
    mapelC.text = "Bahasa Arab"; // Ganti dengan data default
    kelasC.text = "5";
    faseC.text = "C";
  }

  void addSesiPembelajaran() {
    sesiPembelajaranForms.add(SesiPembelajaranForm());
  }

  void removeSesiPembelajaran(int index) {
    sesiPembelajaranForms[index].dispose(); // Penting untuk dispose controller
    sesiPembelajaranForms.removeAt(index);
  }

  Future<void> saveModulAjar() async {
    // Ambil nama penyusun yang benar dari HomeController secara asynchronous
    final userSnapshot = await _homeController.userStream().first;
    final namaPenyusun = userSnapshot.data()?['nama'] ?? 'Guru';

    final modulData = ModulAjarModel(
      idModul: isEditMode.value ? originalModul!.idModul : '',
      idSekolah: _homeController.idSekolah,
      idPenyusun: _homeController.idUser,
      namaPenyusun: namaPenyusun, // Gunakan variabel yang sudah diambil
      idTahunAjaran: _homeController.idTahunAjaran.value!,
      mapel: mapelC.text,
      kelas: int.tryParse(kelasC.text) ?? 0,
      fase: faseC.text,
      alokasiWaktu: alokasiWaktuC.text,
      kompetensiAwal: kompetensiAwalC.text,
      profilPancasila: profilPancasila.toList(),
      profilRahmatan: profilRahmatan.toList(),
      media: media.toList(),
      sumberBelajar: sumberBelajar.toList(),
      targetPesertaDidik: targetPesertaDidik.toList(),
      modelPembelajaran: modelPembelajaranC.text,
      elemen: elemen.toList(),
      tujuanPembelajaran: tujuanPembelajaranC.text,
      pemahamanBermakna: pemahamanBermaknaC.text,
      pertanyaanPemantik: pertanyaanPemantik.toList(),
      kegiatanPembelajaran: sesiPembelajaranForms.map((form) => form.toModel()).toList(),
      status: 'draf',
      createdAt: isEditMode.value ? originalModul!.createdAt : Timestamp.now(),
      lastModified: Timestamp.now(),
    );

    if (isEditMode.value) {
      _perangkatAjarController.updateModulAjar(modulData);
    } else {
      _perangkatAjarController.createModulAjar(modulData);
    }
  }

  @override
  void onClose() {
    mapelC.dispose();
    kelasC.dispose();
    faseC.dispose();
    alokasiWaktuC.dispose();
    kompetensiAwalC.dispose();
    modelPembelajaranC.dispose();
    tujuanPembelajaranC.dispose();
    pemahamanBermaknaC.dispose();
    for (var sesi in sesiPembelajaranForms) {
      sesi.dispose();
    }
    super.onClose();
  }
}

// Helper class untuk form Sesi Pembelajaran
class SesiPembelajaranForm {
  late TextEditingController judulSesiC;
  late TextEditingController pendahuluanC;
  late TextEditingController kegiatanIntiC;
  late TextEditingController penutupC;

  SesiPembelajaranForm() {
    judulSesiC = TextEditingController();
    pendahuluanC = TextEditingController();
    kegiatanIntiC = TextEditingController();
    penutupC = TextEditingController();
  }

  factory SesiPembelajaranForm.fromModel(SesiPembelajaran model) {
    final form = SesiPembelajaranForm();
    form.judulSesiC.text = model.judulSesi;
    form.pendahuluanC.text = model.pendahuluan;
    form.kegiatanIntiC.text = model.kegiatanInti;
    form.penutupC.text = model.penutup;
    return form;
  }

  SesiPembelajaran toModel() {
    return SesiPembelajaran(
      sesi: 0, // Bisa ditambahkan logika urutan jika perlu
      judulSesi: judulSesiC.text,
      pendahuluan: pendahuluanC.text,
      kegiatanInti: kegiatanIntiC.text,
      penutup: penutupC.text,
    );
  }
  
  void dispose() {
    judulSesiC.dispose();
    pendahuluanC.dispose();
    kegiatanIntiC.dispose();
    penutupC.dispose();
  }
}