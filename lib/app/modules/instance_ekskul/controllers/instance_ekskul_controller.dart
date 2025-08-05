// File: lib/app/modules/admin_manajemen/controllers/instance_ekskul_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/home/controllers/home_controller.dart';
import 'package:uuid/uuid.dart';

// Import Views
import '../../../models/instance_ekskul_model.dart';
import '../../../models/master_ekskul_model.dart';
import '../../../models/pegawai_model.dart';
import '../../../models/pembina_eksternal_model.dart';
import '../../../models/siswa_model.dart';
import '../views/kelola_anggota_view.dart';

// Import Models
// import '../models/instance_ekskul_model.dart';
// import '../models/master_ekskul_model.dart';
// import '../models/pegawai_model.dart';
// import '../models/pembina_eksternal_model.dart';
// import '../models/siswa_model.dart';

// Helper class untuk menyatukan data pembina di UI
class PembinaOption {
  String uid;
  String nama;
  String tipe; // "internal" atau "eksternal"
  String detail;

  PembinaOption({
    required this.uid,
    required this.nama,
    required this.tipe,
    required this.detail,
  });
}

class InstanceEkskulController extends GetxController {
  //================================================================
  // DEPENDENCIES
  //================================================================
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final HomeController homeC = Get.find<HomeController>();

  //================================================================
  // STATE: LOADING & DATA UTAMA
  //================================================================
  final RxBool isLoading = false.obs;
  final RxList<InstanceEkskulModel> daftarInstanceEkskul = <InstanceEkskulModel>[].obs;
  
  //================================================================
  // STATE: OPSI-OPSI UNTUK FORM
  //================================================================
  final RxList<MasterEkskulModel> opsiMasterEkskul = <MasterEkskulModel>[].obs;
  final RxList<PembinaOption> opsiPembina = <PembinaOption>[].obs;

  //================================================================
  // STATE: FORM INSTANSI EKSKUL
  //================================================================
  final formKey = GlobalKey<FormState>();
  final Rxn<MasterEkskulModel> selectedMasterEkskul = Rxn<MasterEkskulModel>();
  final RxList<PembinaOption> selectedPembina = <PembinaOption>[].obs;
  final Rxn<String> selectedHari = Rxn<String>();
  final TextEditingController namaTampilanC = TextEditingController();
  final TextEditingController jamMulaiC = TextEditingController();
  final TextEditingController jamSelesaiC = TextEditingController();
  final TextEditingController lokasiC = TextEditingController();
  final List<String> hariOptions = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  //================================================================
  // STATE: MANAJEMEN ANGGOTA
  //================================================================
  final RxBool isLoadingSiswa = false.obs;
  final RxList<SiswaModel> semuaSiswa = <SiswaModel>[].obs;
  final RxList<String> semuaKelas = <String>[].obs;
  final Rxn<String> filterKelas = Rxn<String>();
  final RxString searchQuery = ''.obs;
  final RxList<SiswaModel> anggotaAwal = <SiswaModel>[].obs;
  final RxList<SiswaModel> anggotaTerpilih = <SiswaModel>[].obs;
  
  //================================================================
  // LIFECYCLE METHOD
  //================================================================
  @override
  void onInit() {
    super.onInit();
    if (homeC.idTahunAjaran.value != null) {
      fetchAllData();
    } else {
      Get.snackbar('Kritis', 'Tahun Ajaran tidak ditemukan. Harap mulai ulang aplikasi.');
    }
  }

  //================================================================
  // FUNGSI FETCH DATA AWAL
  //================================================================
  Future<void> fetchAllData() async {
    isLoading.value = true;
    await Future.wait([
      fetchInstanceEkskul(),
      fetchMasterEkskulOptions(),
      fetchAllPembinaOptions(),
    ]);
    isLoading.value = false;
  }

  Future<void> fetchInstanceEkskul() async {
    final idSekolah = homeC.idSekolah;
    final idTahunAjaran = homeC.idTahunAjaran.value;
    if (idTahunAjaran == null) return;

    try {
      final snapshot = await _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('ekstrakurikuler').where('status', isEqualTo: 'Aktif').get();
      daftarInstanceEkskul.value = snapshot.docs.map((doc) => InstanceEkskulModel.fromFirestore(doc)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat daftar ekskul: $e');
    }
  }

  Future<void> fetchMasterEkskulOptions() async {
    try {
      final snapshot = await _firestore.collection('master_ekskul').where('status', isEqualTo: 'Aktif').get();
      opsiMasterEkskul.value = snapshot.docs.map((doc) => MasterEkskulModel.fromFirestore(doc)).toList();
    } catch (e) {
       Get.snackbar('Error', 'Gagal memuat opsi master ekskul: $e');
    }
  }

  Future<void> fetchAllPembinaOptions() async {
    final idSekolah = homeC.idSekolah;
    final List<PembinaOption> combinedList = [];
    try {
      final pegawaiFuture = _firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').get();
      final pembinaEksternalFuture = _firestore.collection('pembina_eksternal').where('status', isEqualTo: 'Aktif').get();
      final results = await Future.wait([pegawaiFuture, pembinaEksternalFuture]);

      final pegawaiDocs = results[0].docs;
      for (var doc in pegawaiDocs) {
        final pegawai = PegawaiModel.fromFirestore(doc);
        combinedList.add(PembinaOption(uid: pegawai.uid, nama: pegawai.nama, tipe: 'internal', detail: pegawai.role));
      }

      final pembinaEksternalDocs = results[1].docs;
      for (var doc in pembinaEksternalDocs) {
        final pembina = PembinaEksternalModel.fromFirestore(doc);
        combinedList.add(PembinaOption(uid: pembina.id, nama: pembina.namaLengkap, tipe: 'eksternal', detail: 'Pembina Eksternal'));
      }

      combinedList.sort((a, b) => a.nama.compareTo(b.nama));
      opsiPembina.value = combinedList;
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat opsi pembina: $e');
    }
  }

  //================================================================
  // FUNGSI FORM HELPER (INSTANSI EKSKUL)
  //================================================================
  void clearForm() {
    formKey.currentState?.reset();
    selectedMasterEkskul.value = null;
    selectedPembina.clear();
    selectedHari.value = null;
    namaTampilanC.clear();
    jamMulaiC.clear();
    jamSelesaiC.clear();
    lokasiC.clear();
  }

  void fillFormForEdit(InstanceEkskulModel instance) {
    selectedMasterEkskul.value = opsiMasterEkskul.firstWhereOrNull((o) => o.id == instance.masterEkskulRef);
    selectedPembina.value = opsiPembina.where((o) => instance.pembina.any((p) => p['uid'] == o.uid)).toList();
    selectedHari.value = instance.hariJadwal;
    namaTampilanC.text = instance.namaTampilan;
    jamMulaiC.text = instance.jamMulai;
    jamSelesaiC.text = instance.jamSelesai;
    lokasiC.text = instance.lokasi;
  }

  Future<void> selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now(), builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!));
    if (picked != null) {
      final formattedTime = MaterialLocalizations.of(context).formatTimeOfDay(picked, alwaysUse24HourFormat: true);
      controller.text = formattedTime;
    }
  }

  //================================================================
  // FUNGSI CRUD: INSTANSI EKSKUL (AKAN DITAMBAHKAN DI MISI BRAVO-3)
  //================================================================
  // Future<void> saveInstanceEkskul(...) { ... }
   Future<void> saveInstanceEkskul({String? existingInstanceId}) async {
    // 1. Validasi Form dari UI
    if (!formKey.currentState!.validate()) {
      Get.snackbar("Gagal", "Mohon periksa kembali semua isian Anda.");
      return;
    }

    // Tampilkan loading di tombol utama
    isLoading.value = true;

    try {
      final idSekolah = homeC.idSekolah;
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      
      // 2. Siapkan Data dari Form
      final List<Map<String, dynamic>> pembinaData = selectedPembina.map((p) => {
        'tipe': p.tipe,
        'uid': p.uid,
        'nama': p.nama,
      }).toList();

      final instanceId = existingInstanceId ?? _uuid.v4();
      
      final instanceData = InstanceEkskulModel(
        id: instanceId,
        masterEkskulRef: selectedMasterEkskul.value!.id,
        namaTampilan: namaTampilanC.text,
        idTahunAjaran: idTahunAjaran,
        pembina: pembinaData,
        hariJadwal: selectedHari.value!,
        jamMulai: jamMulaiC.text,
        jamSelesai: jamSelesaiC.text,
        lokasi: lokasiC.text,
        status: 'Aktif',
      );

      // 3. Mulai Operasi Batch
      final batch = _firestore.batch();
      
      // Operasi Utama: Simpan atau Update data instansi ekskul
      final ekskulRef = _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('ekstrakurikuler').doc(instanceId);
      batch.set(ekskulRef, instanceData.toFirestore(), SetOptions(merge: true));

      // --- Logika Cerdas untuk Update Denormalisasi Pembina ---
      List<Map<String,dynamic>> pembinaLamaData = [];
      if (existingInstanceId != null) {
          final ekskulLama = daftarInstanceEkskul.firstWhereOrNull((e) => e.id == existingInstanceId);
          if(ekskulLama != null) pembinaLamaData = ekskulLama.pembina;
      }
      
      final Set<String> uidsPembinaBaru = selectedPembina.map((p) => p.uid).toSet();
      final Set<String> uidsPembinaLama = pembinaLamaData.map((p) => p['uid'] as String).toSet();

      final List<PembinaOption> pembinaUntukDitambah = selectedPembina.where((p) => !uidsPembinaLama.contains(p.uid)).toList();
      final List<Map<String,dynamic>> pembinaUntukDihapus = pembinaLamaData.where((p) => !uidsPembinaBaru.contains(p['uid'])).toList();
      
      // Data referensi yang akan disimpan di dokumen pembina
      final Map<String, dynamic> dataRefEkskulUntukPembina = {
          'instanceEkskulId': instanceId,
          'idTahunAjaran': idTahunAjaran,
          'namaTampilan': "${instanceData.namaTampilan} (${homeC.idTahunAjaran.value})" // Lebih informatif
      };

      // Operasi Batch: Tambahkan referensi ke pembina BARU
      for (var p in pembinaUntukDitambah) {
          final docCollection = p.tipe == 'internal' ? 'pegawai' : 'pembina_eksternal';
          final ref = docCollection == 'pegawai' 
            ? _firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(p.uid)
            : _firestore.collection('pembina_eksternal').doc(p.uid);
          batch.update(ref, {'ekskulYangDiampu': FieldValue.arrayUnion([dataRefEkskulUntukPembina])});
      }

      // Operasi Batch: Hapus referensi dari pembina LAMA
      for (var p in pembinaUntukDihapus) {
          final docCollection = p['tipe'] == 'internal' ? 'pegawai' : 'pembina_eksternal';
          // Kita butuh membuat ulang data referensi LAMA persis seperti saat disimpan
          // agar `arrayRemove` berhasil. Ini adalah bagian yang tricky.
          final ekskulLama = daftarInstanceEkskul.firstWhereOrNull((e) => e.id == existingInstanceId);
          final dataRefLama = {
            'instanceEkskulId': existingInstanceId,
            'idTahunAjaran': ekskulLama?.idTahunAjaran,
            'namaTampilan': "${ekskulLama?.namaTampilan} (${ekskulLama?.idTahunAjaran})"
          };
          final ref = docCollection == 'pegawai'
            ? _firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(p['uid'])
            : _firestore.collection('pembina_eksternal').doc(p['uid']);
          batch.update(ref, {'ekskulYangDiampu': FieldValue.arrayRemove([dataRefLama])});
      }
      
      // 4. Eksekusi semua operasi dalam satu transaksi
      await batch.commit();

      // 5. Selesaikan
      Get.back(); // Kembali ke halaman list
      await fetchAllData(); // Muat ulang semua data
      Get.snackbar("Berhasil", "Data ekstrakurikuler berhasil disimpan.");

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data: $e");
    } finally {
      isLoading.value = false;
    }
  }
  
  //================================================================
  // FUNGSI ALUR MANAJEMEN ANGGOTA
  //================================================================
  Future<void> navigateToKelolaAnggota(String instanceEkskulId) async {
    isLoadingSiswa.value = true;
    try {
      await fetchSiswaDatabase();
      await prepareMemberManagement(instanceEkskulId);
      Get.to(() => KelolaAnggotaView(instanceEkskulId: instanceEkskulId));
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoadingSiswa.value = false;
    }
  }

  Future<void> fetchSiswaDatabase() async {
    final idSekolah = homeC.idSekolah;
    try {
      final snapshot = await _firestore.collection('Sekolah').doc(idSekolah).collection('siswa').where('status', isEqualTo: 'aktif').orderBy('nama').get();
      semuaSiswa.value = snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList();
      final kelasSet = <String>{};
      for (var siswa in semuaSiswa) {
        kelasSet.add(siswa.namaKelas);
      }
      semuaKelas.value = kelasSet.toList()..sort();
    } catch (e) {
      throw Exception("Gagal memuat database siswa: $e");
    }
  }
  
  Future<void> prepareMemberManagement(String instanceEkskulId) async {
    filterKelas.value = null;
    searchQuery.value = '';
    anggotaAwal.clear();
    anggotaTerpilih.clear();
    final idSekolah = homeC.idSekolah;
    final idTahunAjaran = homeC.idTahunAjaran.value;
    if (idTahunAjaran == null) return;

    final anggotaSnapshot = await _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('ekstrakurikuler').doc(instanceEkskulId).collection('anggota').get();
    final Set<String> idAnggotaSaatIni = anggotaSnapshot.docs.map((doc) => doc.id).toSet();
    final initialMembers = semuaSiswa.where((siswa) => idAnggotaSaatIni.contains(siswa.nisn)).toList();
    anggotaAwal.value = List<SiswaModel>.from(initialMembers);
    anggotaTerpilih.value = List<SiswaModel>.from(initialMembers);
  }

  void changeKelasFilter(String? newKelas) {
    filterKelas.value = newKelas;
    searchQuery.value = '';
  }

  //================================================================
  // FUNGSI CRUD: KEANGGOTAAN EKSKUL
  //================================================================
  Future<void> updateKeanggotaan(String instanceEkskulId) async {
    isLoadingSiswa.value = true;
    try {
      final instanceInfo = daftarInstanceEkskul.firstWhere((e) => e.id == instanceEkskulId);
      final Set<String> uidsAwal = anggotaAwal.map((s) => s.nisn).toSet();
      final Set<String> uidsTerpilih = anggotaTerpilih.map((s) => s.nisn).toSet();
      final Set<String> uidsUntukDitambah = uidsTerpilih.difference(uidsAwal);
      final Set<String> uidsUntukDihapus = uidsAwal.difference(uidsTerpilih);

      if (uidsUntukDitambah.isEmpty && uidsUntukDihapus.isEmpty) {
        Get.snackbar("Info", "Tidak ada perubahan keanggotaan.");
        isLoadingSiswa.value = false;
        return;
      }

      final batch = _firestore.batch();
      final idSekolah = homeC.idSekolah;
      final idTahunAjaran = homeC.idTahunAjaran.value!;

      for (final nisn in uidsUntukDitambah) {
        final siswa = anggotaTerpilih.firstWhere((s) => s.nisn == nisn);
        final ekskulAnggotaRef = _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('ekstrakurikuler').doc(instanceEkskulId).collection('anggota').doc(nisn);
        final siswaEkskulRef = _firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(nisn).collection('ekskul_diikuti').doc(instanceEkskulId);
        final anggotaData = {'namaSiswa': siswa.nama, 'idKelasSiswa': siswa.namaKelas, 'kelasSiswa': siswa.namaKelas, 'tanggalBergabung': FieldValue.serverTimestamp()};
        final siswaData = {'masterEkskulRef': instanceInfo.masterEkskulRef, 'idTahunAjaran': idTahunAjaran, 'namaTampilan': instanceInfo.namaTampilan, 'namaPembina': instanceInfo.pembina.map((p) => p['nama']).join(', '), 'jadwalHari': instanceInfo.hariJadwal};
        batch.set(ekskulAnggotaRef, anggotaData);
        batch.set(siswaEkskulRef, siswaData);
      }

      for (final nisn in uidsUntukDihapus) {
        final ekskulAnggotaRef = _firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('ekstrakurikuler').doc(instanceEkskulId).collection('anggota').doc(nisn);
        final siswaEkskulRef = _firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(nisn).collection('ekskul_diikuti').doc(instanceEkskulId);
        batch.delete(ekskulAnggotaRef);
        batch.delete(siswaEkskulRef);
      }

      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "Keanggotaan ekstrakurikuler berhasil diperbarui.");
    } catch (e) {
      Get.snackbar("Error Kritis", "Gagal menyimpan perubahan: $e");
    } finally {
      isLoadingSiswa.value = false;
    }
  }
}
