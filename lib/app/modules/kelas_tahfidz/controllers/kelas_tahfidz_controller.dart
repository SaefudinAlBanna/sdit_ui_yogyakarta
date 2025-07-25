// lib/app/modules/kelas_tahfidz/controllers/kelas_tahfidz_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../modules/home/controllers/home_controller.dart';

class KelasTahfidzController extends GetxController {
  // --- DEPENDENSI ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final FirebaseAuth auth = FirebaseAuth.instance;

  // --- STATE KONTROL AKSES & UI ---
  final RxBool isLoading = true.obs;
  final RxBool hasAccess = false.obs;
  final RxBool isReadOnly = false.obs;
  final RxBool canManagePendamping = false.obs;

  // --- STATE DATA KELAS ---
  final RxString idKelas = ''.obs;
  final RxString namaKelas = ''.obs;
  final RxString namaWaliKelas = ''.obs;
  final RxList<Map<String, dynamic>> semuaSiswa = <Map<String, dynamic>>[].obs;
  final RxMap<String, String> daftarPendamping = <String, String>{}.obs;
  final RxMap<String, List<String>> delegasiSiswa = <String, List<String>>{}.obs;

  // --- STATE DATA TAMPILAN (DIPISAH) ---
  final RxList<Map<String, dynamic>> siswaDikelolaWali = <Map<String, dynamic>>[].obs;
  final RxMap<String, List<Map<String, dynamic>>> siswaPerPendamping = <String, List<Map<String, dynamic>>>{}.obs;
  final RxList<String> nisnBagianSaya = <String>[].obs;

  // --- STATE FORM & EDITING ---
  final formKey = GlobalKey<FormState>();
  late TextEditingController murojaahC, hafalanC, nilaiC, catatanGuruC;
  final Rxn<String> editingDocId = Rxn<String>();
  final RxBool isSaving = false.obs;
  Map<String, TextEditingController> nilaiMassalControllers = {};
  final RxList<Map<String, dynamic>> siswaUntukInputMassal = <Map<String, dynamic>>[].obs;

  bool get isEditMode => editingDocId.value != null;

  @override
  void onInit() {
    super.onInit();
    murojaahC = TextEditingController();
    hafalanC = TextEditingController();
    nilaiC = TextEditingController();
    catatanGuruC = TextEditingController();
    determineAccess();
  }

 @override
  void onClose() {
    nilaiMassalControllers.forEach((_, controller) => controller.dispose());
    murojaahC.dispose(); hafalanC.dispose(); nilaiC.dispose(); catatanGuruC.dispose();
    super.onClose();
  }

  // --- FUNGSI UTAMA & PEMERIKSAAN PERAN ---

  Future<void> determineAccess() async {
    isLoading.value = true;
    try {
      if (await _checkAndLoadAsWaliKelas()) return;
      if (await _checkAndLoadAsPendamping()) return;
      if (await _checkAndLoadAsPimpinan()) return; // Logika pimpinan bisa ditambahkan nanti
      hasAccess.value = false;
    } catch (e) {
      hasAccess.value = false;
      Get.snackbar("Error Akses", "Gagal memuat data kelas: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _checkAndLoadAsPimpinan() async {
    // --- GANTI BAGIAN INI ---
    // if (homeC.isAdminKepsek) {
    // --- MENJADI INI ---
    if (homeC.tahfidzKelas) { 
    
      hasAccess.value = true;
      isReadOnly.value = true;
      canManagePendamping.value = false;
      _showKelasSelectionDialogForPimpinan(); // Tampilkan dialog untuk pilih kelas
      return true;
    }
    return false;
  }

  void _showKelasSelectionDialogForPimpinan() async {
    // Ambil semua kelas yang ada di tahun ajaran aktif
    final String idTahunAjaran = homeC.idTahunAjaran.value!;
    final querySnapshot = await firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .orderBy('namakelas')
        .get();

    final List<Map<String, dynamic>> semuaKelas = querySnapshot.docs.map((doc) {
      return {'id': doc.id, 'nama': doc.data()['namakelas']};
    }).toList();

    // Tampilkan dialog pencarian
    Get.dialog(
      AlertDialog(
        title: const Text("Pilih Kelas untuk Dipantau"),
        content: SizedBox(
          width: Get.width * 0.8,
          child: DropdownSearch<Map<String, dynamic>>(
            items: (f, cs) => semuaKelas,
            itemAsString: (item) => item['nama'],
            compareFn: (item1, item2) => item1['id'] == item2['id'],
            popupProps: PopupProps.menu(showSearchBox: true, searchFieldProps: TextFieldProps(decoration: InputDecoration(labelText: "Cari Kelas"))),
            decoratorProps: DropDownDecoratorProps(decoration: InputDecoration(labelText: "Daftar Kelas")),
            onChanged: (selectedKelas) {
              if (selectedKelas != null) {
                Get.back(); // Tutup dialog
                isLoading.value = true;
                // Muat data kelas yang dipilih
                _loadKelasData(selectedKelas['id']).whenComplete(() => isLoading.value = false);
              }
            },
          ),
        ),
      ),
      barrierDismissible: false, // Pimpinan harus memilih kelas
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCatatanTahfidzStream(String nisn) {
    return firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelastahunajaran').doc(idKelas.value)
        .collection('semester').doc(homeC.semesterAktifId.value)
        .collection('daftarsiswa').doc(nisn)
        .collection('catatan_tahfidz')
        .orderBy('tanggal_penilaian', descending: true)
        .snapshots();
  }


  Future<bool> _checkAndLoadAsWaliKelas() async {
    if (homeC.walikelas) {
      final query = await firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
          .collection('kelastahunajaran').where('idwalikelas', isEqualTo: auth.currentUser!.uid).limit(1).get();
      
      if (query.docs.isNotEmpty) {
        await _loadKelasData(query.docs.first.id);
        hasAccess.value = true;
        isReadOnly.value = false;
        canManagePendamping.value = true;
        nisnBagianSaya.assignAll(semuaSiswa.map((s) => s['id'].toString()).toList());
        return true;
      }
    }
    return false;
  }

  Future<bool> _checkAndLoadAsPendamping() async {
    final userDoc = await firestore.collection('Sekolah').doc(homeC.idSekolah).collection('pegawai').doc(auth.currentUser!.uid).get();
    final String? idKelasTugas = userDoc.data()?['tugas_pendamping_tahfidz'];

    if (idKelasTugas != null) {
      await _loadKelasData(idKelasTugas);
      hasAccess.value = true;
      isReadOnly.value = false;
      canManagePendamping.value = false;
      nisnBagianSaya.assignAll(delegasiSiswa[auth.currentUser!.uid] ?? []);
      return true;
    }
    return false;
  }
  
  // --- FUNGSI PENGAMBILAN & PEMROSESAN DATA ---

  Future<void> _loadKelasData(String kelasId) async {
    final String idTahunAjaran = homeC.idTahunAjaran.value!;
    final String semesterId = homeC.semesterAktifId.value;
    final docRef = firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(kelasId);
    
    final kelasDoc = await docRef.get();
    if (!kelasDoc.exists) throw Exception("Data kelas dengan ID '$kelasId' tidak ditemukan.");

    final kelasData = kelasDoc.data()!;
    idKelas.value = kelasDoc.id;
    namaKelas.value = kelasData['namakelas'] ?? 'Tanpa Nama';
    namaWaliKelas.value = kelasData['walikelas'] ?? 'Tanpa Nama'; // Mengambil nama wali kelas
    daftarPendamping.clear();
    delegasiSiswa.clear();
    
    if (kelasData.containsKey('tahfidz_info')) {
      daftarPendamping.assignAll(Map<String, String>.from(kelasData['tahfidz_info']['pendamping'] ?? {}));
      delegasiSiswa.assignAll(Map<String, List<String>>.from(
          (kelasData['tahfidz_info']['delegasi_siswa'] as Map? ?? {}).map(
              (key, value) => MapEntry(key, List<String>.from(value))
          )
      ));
    }

    final siswaSnapshot = await docRef.collection('semester').doc(semesterId).collection('daftarsiswa').get();
    semuaSiswa.assignAll(siswaSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
    
    _kelompokkanSiswa();
  }

  void _kelompokkanSiswa() {
    siswaDikelolaWali.clear();
    siswaPerPendamping.clear();
    final semuaNisnDidelegasikan = delegasiSiswa.values.expand((list) => list).toSet();
    delegasiSiswa.forEach((uidPendamping, nisnList) {
      siswaPerPendamping[uidPendamping] = semuaSiswa.where((siswa) => nisnList.contains(siswa['id'])).toList();
    });
    siswaDikelolaWali.assignAll(semuaSiswa.where((siswa) => !semuaNisnDidelegasikan.contains(siswa['id'])));
  }

  String _getPendampingNamaForSiswa(String nisn) {
    // Cari di daftar delegasi pendamping
    for (var entry in delegasiSiswa.entries) {
      if (entry.value.contains(nisn)) {
        // Jika ditemukan, kembalikan nama pendampingnya
        return daftarPendamping[entry.key] ?? 'Pendamping Tidak Ditemukan';
      }
    }
    // Jika tidak ditemukan di manapun, berarti tanggung jawab Wali Kelas
    return namaWaliKelas.value;
  }

  // --- FUNGSI MANAJEMEN PENDAMPING & DELEGASI ---

  Future<List<Map<String, dynamic>>> getAvailablePendamping() async {
    final snapshot = await firestore.collection('Sekolah').doc(homeC.idSekolah).collection('pegawai')
        .where('role', isEqualTo: 'Pengampu').where('tugas_pendamping_tahfidz', isNull: true).get();
    return snapshot.docs.map((doc) => {'uid': doc.id, 'nama': doc.data()['alias'] ?? 'Tanpa Nama'}).toList();
  }

    /// 2. Menambahkan seorang guru sebagai pendamping.
  Future<void> addPendamping(String uid, String nama) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final String idTahunAjaran = homeC.idTahunAjaran.value!;
      final kelasRef = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(idKelas.value);
      final guruRef = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('pegawai').doc(uid);

      WriteBatch batch = firestore.batch();

      batch.set(kelasRef, {
        'tahfidz_info': {
          'pendamping': {uid: nama}
        }
      }, SetOptions(merge: true));

      batch.update(guruRef, {'tugas_pendamping_tahfidz': idKelas.value});

      await batch.commit();

      daftarPendamping[uid] = nama;
      Get.back();
      Get.snackbar("Berhasil", "$nama telah ditambahkan sebagai pendamping.");

    } catch (e) {
      Get.back();
      Get.snackbar("Gagal", "Gagal menambahkan pendamping: $e");
    }
  }

    /// 3. Menghapus seorang guru dari daftar pendamping.
  Future<void> removePendamping(String uid) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final String idTahunAjaran = homeC.idTahunAjaran.value!;
      final kelasRef = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(idKelas.value);
      final guruRef = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('pegawai').doc(uid);

      WriteBatch batch = firestore.batch();

      // batch.update(kelasRef, {'tahfidz_info.pendamping.$uid': FieldValue.delete()});
      batch.update(kelasRef, {
      'tahfidz_info.pendamping.$uid': FieldValue.delete(),
      'tahfidz_info.delegasi_siswa.$uid': FieldValue.delete() // <-- TAMBAHAN
    });
      batch.update(guruRef, {'tugas_pendamping_tahfidz': FieldValue.delete()});

      await batch.commit();
      await _loadKelasData(idKelas.value);
      
      daftarPendamping.remove(uid);
      Get.back();
      Get.snackbar("Berhasil", "Pendamping telah dihapus.");
    } catch (e) {
      Get.back();
      Get.snackbar("Gagal", "Gagal menghapus pendamping: $e");
    }
  }

    // --- LOGIKA MANAJEMEN DELEGASI SISWA ---
  Future<void> saveDelegasi(String uidPendamping, List<String> nisnTerpilih) async {
    Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final docRef = firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
          .collection('kelastahunajaran').doc(idKelas.value);

      // Update map delegasi
      await docRef.update({'tahfidz_info.delegasi_siswa.$uidPendamping': nisnTerpilih});
      
      Get.back(); // Tutup dialog loading
      Get.back(); // Tutup dialog delegasi
      Get.snackbar("Berhasil", "Data delegasi siswa telah diperbarui.");
      
      // Muat ulang data untuk refresh UI
      await _loadKelasData(idKelas.value);
    } catch (e) {
      Get.back();
      Get.snackbar("Gagal", "Gagal menyimpan delegasi: $e");
    }
  }

  // --- FUNGSI PENILAIAN ---

  void prepareAndShowNilaiMassalDialog({required String mode}) {
    siswaUntukInputMassal.clear();
    nilaiMassalControllers.clear();

    if (mode == 'wali_saja') siswaUntukInputMassal.assignAll(siswaDikelolaWali);
    else if (mode == 'semua_siswa') siswaUntukInputMassal.assignAll(semuaSiswa);
    else if (mode == 'pendamping') siswaUntukInputMassal.assignAll(siswaPerPendamping[auth.currentUser!.uid] ?? []);

    for (var siswa in siswaUntukInputMassal) {
      nilaiMassalControllers[siswa['id']] = TextEditingController();
    }
    showNilaiMassalDialog();
  }

  void showNilaiMassalDialog() {
    final murojaahMassalC = TextEditingController();
    final hafalanMassalC = TextEditingController();

    Get.defaultDialog(
      title: "Input Nilai Massal",
      titlePadding: const EdgeInsets.all(16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      content: Form(
        child: SizedBox(
          width: Get.width,
          height: Get.height * 0.6,
          child: Column(
            children: [
              // --- GANTI DROPDOWN MENJADI TEXTFIELD BARU ---
              TextFormField(
                controller: murojaahMassalC,
                decoration: const InputDecoration(labelText: "Murojaah (Untuk Semua Siswa)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: hafalanMassalC,
                decoration: const InputDecoration(labelText: "Hafalan Baru (Untuk Semua Siswa)", border: OutlineInputBorder()),
              ),
              const Divider(height: 20),
              const Text("Daftar Siswa", style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Obx(() {
                  if (siswaUntukInputMassal.isEmpty) {
                    return const Center(child: Text("Tidak ada siswa untuk dinilai."));
                  }
                  return ListView.builder(
                    itemCount: siswaUntukInputMassal.length,
                    itemBuilder: (context, index) {
                      final siswa = siswaUntukInputMassal[index];
                      return ListTile(
                        title: Text(siswa['namasiswa']),
                        trailing: SizedBox(
                          width: 60,
                          child: TextFormField(
                            controller: nilaiMassalControllers[siswa['id']],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: "Nilai"),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      textConfirm: "Simpan Semua",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () => saveNilaiMassal(murojaahMassalC.text, hafalanMassalC.text),
    );
  }

  Future<void> saveNilaiMassal(String murojaah, String hafalan) async {
    // Validasi: Pastikan salah satu field diisi
    if (murojaah.trim().isEmpty && hafalan.trim().isEmpty) {
      Get.snackbar("Peringatan", "Murojaah atau Hafalan wajib diisi.");
      return;
    }

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      WriteBatch batch = firestore.batch();
      int successCount = 0;

      for (var entry in nilaiMassalControllers.entries) {
        String nisn = entry.key;
        String nilai = entry.value.text;

        if (nilai.isNotEmpty) {
          final collectionRef = firestore
              .collection('Sekolah').doc(homeC.idSekolah)
              .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
              .collection('kelastahunajaran').doc(idKelas.value)
              .collection('semester').doc(homeC.semesterAktifId.value)
              .collection('daftarsiswa').doc(nisn)
              .collection('catatan_tahfidz');

          final dataToSave = {
            "tanggal_penilaian": Timestamp.now(),
            "murojaah": murojaah.trim(), // <-- FIELD BARU
            "hafalan": hafalan.trim(),   // <-- FIELD BARU
            "nilai": int.tryParse(nilai) ?? 0,
            "catatan_guru": "Input massal.",
            "penilai_uid": auth.currentUser!.uid,
            "penilai_nama": homeC.userRole.value,
            "id_kelas": idKelas.value,
            "nisn": nisn,
            "namaSiswa": (semuaSiswa.firstWhere((s) => s['id'] == nisn, orElse: () => {}))['namasiswa'] ?? ''
          };
          batch.set(collectionRef.doc(), dataToSave);
          successCount++;
        }
      }

      if (successCount == 0) {
        Get.back();
        Get.snackbar("Info", "Tidak ada nilai yang diinputkan.");
        return;
      }

      await batch.commit();
      Get.back(); // Tutup dialog loading
      Get.back(); // Tutup dialog input massal
      Get.snackbar("Berhasil", "$successCount data nilai berhasil disimpan.");
      nilaiMassalControllers.forEach((_, controller) => controller.clear());

    } catch (e) {
      Get.back();
      Get.snackbar("Gagal", "Terjadi kesalahan: $e");
    }
  }

   // --- FUNGSI BARU: Mengambil stream untuk nilai terakhir siswa ---
  Stream<DocumentSnapshot<Map<String, dynamic>>?> getLastNilaiStream(String nisn) {
    // Pastikan semua ID yang dibutuhkan tidak kosong sebelum menjalankan query
    if (idKelas.isEmpty || homeC.idTahunAjaran.value == null) {
      return Stream.value(null);
    }
    
    // Path yang sudah sadar semester
    return firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelastahunajaran').doc(idKelas.value)
        .collection('semester').doc(homeC.semesterAktifId.value) // <- Path semester
        .collection('daftarsiswa').doc(nisn)
        .collection('catatan_tahfidz')
        .orderBy('tanggal_penilaian', descending: true)
        .limit(1) // Ambil hanya 1 dokumen teratas
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
  }

  void startEdit(Map<String, dynamic> catatan, String docId) {
    editingDocId.value = docId;
    murojaahC.text = catatan['murojaah'] ?? '';
    hafalanC.text = catatan['hafalan'] ?? '';
    nilaiC.text = (catatan['nilai'] ?? 0).toString();
    catatanGuruC.text = catatan['catatan_guru'] ?? '';
  }

  void clearForm() {
    editingDocId.value = null;
    murojaahC.clear(); hafalanC.clear(); nilaiC.clear(); catatanGuruC.clear();
    formKey.currentState?.reset();
  }

  Future<void> saveCatatanTahfidz(String nisn) async {
    if (!formKey.currentState!.validate()) return;
    if (murojaahC.text.isEmpty && hafalanC.text.isEmpty && editingDocId.value == null) {
      Get.snackbar("Peringatan", "Murojaah atau Hafalan wajib diisi untuk setoran baru.");
      return;
    }

    isSaving.value = true;
    try {
      final collectionRef = firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
          .collection('kelastahunajaran').doc(idKelas.value)
          .collection('semester').doc(homeC.semesterAktifId.value)
          .collection('daftarsiswa').doc(nisn).collection('catatan_tahfidz');

      if (editingDocId.value != null) {
        final dataToUpdate = {
          "nilai": int.tryParse(nilaiC.text) ?? 0,
          "catatan_guru": catatanGuruC.text.trim(),
          "penilai_uid": auth.currentUser!.uid,
          "penilai_nama": homeC.userRole.value,
          "tanggal_penilaian": Timestamp.now(),
        };
        await collectionRef.doc(editingDocId.value).update(dataToUpdate);
        Get.snackbar("Berhasil", "Catatan penilaian telah diperbarui.");
      } else {
        final dataToSave = {
          "tanggal_penilaian": Timestamp.now(),
          "murojaah": murojaahC.text.trim(),
          "hafalan": hafalanC.text.trim(),
          "nilai": int.tryParse(nilaiC.text) ?? 0,
          "catatan_guru": catatanGuruC.text.trim(),
          "penilai_uid": auth.currentUser!.uid,
          "penilai_nama": homeC.userRole.value,
          "id_kelas": idKelas.value,
          "nisn": nisn,
          "namaSiswa": (semuaSiswa.firstWhere((s) => s['id'] == nisn, orElse: () => {}))['namasiswa'] ?? ''
        };
        await collectionRef.add(dataToSave);
        Get.snackbar("Berhasil", "Catatan penilaian baru telah disimpan.");
      }
      clearForm();
    } catch (e) {
      Get.snackbar("Gagal", "Gagal menyimpan data: $e");
    } finally {
      isSaving.value = false;
    }
  }

    /// Menghapus catatan tahfidz.
  Future<void> deleteCatatanTahfidz(String nisn, String docId) async {
     Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
     try {
       await firestore
           .collection('Sekolah').doc(homeC.idSekolah)
           .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
           .collection('kelastahunajaran').doc(idKelas.value)
           .collection('daftarsiswa').doc(nisn)
           .collection('catatan_tahfidz').doc(docId).delete();
      
      Get.back();
      Get.snackbar("Berhasil", "Catatan telah dihapus.");
     } catch (e) {
       Get.back();
       Get.snackbar("Gagal", "Gagal menghapus catatan: $e");
     }
  }

    /// Membuat dan mencetak PDF riwayat tahfidz siswa.
  Future<void> generateAndPrintPdf(String namaSiswa, String nisn, List<QueryDocumentSnapshot<Map<String, dynamic>>> catatanList) async {
    final pdf = pw.Document();
    
    // Panggil fungsi helper untuk mendapatkan nama penanggung jawab
    final String namaPenanggungJawab = _getPendampingNamaForSiswa(nisn);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("Laporan Riwayat Tahfidz", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20))),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Nama Siswa: $namaSiswa"),
                  pw.SizedBox(height: 4),
                  // --- TAMBAHAN BARU SESUAI IMPROVISASI ---
                  pw.Text("Penanggung Jawab: $namaPenanggungJawab", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                ]
              ),
              pw.Text("Kelas: ${namaKelas.value}"),
            ]
          ),
          pw.Divider(height: 20),
          pw.Table.fromTextArray(
            headers: ['Tanggal', 'Murojaah', 'Hafalan', 'Nilai', 'Catatan'],
            data: catatanList.map((doc) {
              final data = doc.data();
              final timestamp = data['tanggal_penilaian'] as Timestamp;
              final tanggal = DateFormat('dd-MM-yyyy', 'id_ID').format(timestamp.toDate());
              return [
                tanggal, data['murojaah'] ?? '-', data['hafalan'] ?? '-',
                (data['nilai'] ?? 0).toString(), data['catatan_guru'] ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(5),
            border: pw.TableBorder.all(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void showCetakLaporanKelasDialog() {
    Get.defaultDialog(
      title: "Cetak Laporan Kelas",
      middleText: "Pilih jenis laporan yang ingin Anda cetak.",
      actions: [
        ListTile(
          leading: Icon(Icons.today),
          title: Text("Laporan Hari Ini"),
          onTap: () {
            Get.back();
            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day);
            final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
            generateLaporanKelasPdf(startOfDay, endOfDay);
          },
        ),
        ListTile(
          leading: Icon(Icons.date_range),
          title: Text("Pilih Rentang Tanggal"),
          onTap: () async {
            Get.back();
            DateTimeRange? picked = await showDateRangePicker(
              context: Get.context!,
              initialDateRange: DateTimeRange(start: DateTime.now().subtract(Duration(days: 7)), end: DateTime.now()),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(Duration(days: 30)),
            );
            if (picked != null) {
              // Set jam akhir hari agar mencakup semua data di tanggal akhir
              final endOfDay = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
              generateLaporanKelasPdf(picked.start, endOfDay);
            }
          },
        ),
      ],
    );
  }

  Future<void> generateLaporanKelasPdf(DateTime start, DateTime end) async {
    Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      // 1. Ambil semua catatan penilaian di kelas ini dalam rentang tanggal
      final querySnapshot = await firestore
          .collectionGroup('catatan_tahfidz')
          .where('id_kelas', isEqualTo: idKelas.value) // Butuh field 'id_kelas' di dokumen nilai
          .where('tanggal_penilaian', isGreaterThanOrEqualTo: start)
          .where('tanggal_penilaian', isLessThanOrEqualTo: end)
          .get();

      if (querySnapshot.docs.isEmpty) {
        Get.back();
        Get.snackbar("Informasi", "Tidak ada data penilaian pada rentang tanggal yang dipilih.");
        return;
      }
      
      // 2. Proses dan kelompokkan data
      final List<List<String>> tableData = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final String nisn = data['nisn'] ?? ''; // Butuh field 'nisn' di dokumen nilai
        final String namaSiswa = data['namaSiswa'] ?? 'Siswa'; // Butuh field 'namaSiswa'
        final String pendamping = _getPendampingNamaForSiswa(nisn);
        
        tableData.add([
          namaSiswa,
          pendamping,
          data['murojaah'] ?? '-',
          data['hafalan'] ?? '-',
          data['catatan_guru'] ?? '-',
        ]);
      }
      
      // 3. Buat PDF
      final pdf = pw.Document();
      final String tglLaporan = DateFormat('dd MMMM yyyy', 'id_ID').format(start) + (start.day != end.day ? " - ${DateFormat('dd MMMM yyyy', 'id_ID').format(end)}" : "");

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape, // Gunakan landscape agar muat
          build: (context) => [
            pw.Header(text: "Laporan Tahfidz Kelas: ${namaKelas.value}"),
            pw.Text("Tanggal Laporan: $tglLaporan"),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Nama Siswa', 'Pendamping', 'Murojaah', 'Hafalan', 'Catatan'],
              data: tableData,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellPadding: const pw.EdgeInsets.all(5),
              border: pw.TableBorder.all(),
            ),
          ],
        ),
      );
      
      Get.back(); // Tutup dialog loading
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

    } catch (e) {
      Get.back();
      print("error membuat laporan : $e");
      Get.snackbar("Error Membuat Laporan", "Terjadi kesalahan: ${e.toString()}\n\nMungkin perlu membuat indeks Firestore.");
    }
  }
}