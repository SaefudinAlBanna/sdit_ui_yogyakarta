// lib/app/services/halaqoh_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/siswa_halaqoh.dart';
import '../modules/home/controllers/home_controller.dart';

class HalaqohService extends GetxService {
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  HomeController get _homeController => Get.find<HomeController>();
  String get _idSekolah => _homeController.idSekolah;
  String get _idTahunAjaran => _homeController.idTahunAjaran.value!;
  String get _semesterAktif => _homeController.semesterAktifId.value;

  
  Future<List<Map<String, dynamic>>> fetchAvailablePengampu(String fase) async {
    
    try {
      final results = await Future.wait([
        _firestore.collection('Sekolah').doc(_idSekolah)
                 .collection('pegawai').where('role', isEqualTo: 'Pengampu').get(),
        _firestore.collection('Sekolah').doc(_idSekolah)
                 .collection('pegawai').where('tugas', arrayContains: 'Pengampu').get(),
      ]);
      final allPengampuByRole = results[0].docs;
      final allPengampuByTugas = results[1].docs;
      final Map<String, Map<String, dynamic>> pengampuMap = {};
      for (var doc in allPengampuByRole) {
        pengampuMap[doc.id] = {'uid': doc.id, 'alias': doc.data()['alias'] as String};
      }
      for (var doc in allPengampuByTugas) {
        pengampuMap[doc.id] = {'uid': doc.id, 'alias': doc.data()['alias'] as String};
      }
      final List<Map<String, dynamic>> semuaPengampu = pengampuMap.values.toList();
      final assignedPengampuSnapshot = await _firestore
          .collection('Sekolah').doc(_idSekolah)
          .collection('tahunajaran').doc(_idTahunAjaran)
          .collection('kelompokmengaji').doc(fase)
          .collection('pengampu').get();
      final Set<String> uidPengampuDitugaskan = assignedPengampuSnapshot.docs.map((doc) => doc.id).toSet();
      final List<Map<String, dynamic>> pengampuTersedia = semuaPengampu
          .where((pengampu) => !uidPengampuDitugaskan.contains(pengampu['uid']))
          .toList();
      return pengampuTersedia;
    } catch(e) {
      Get.snackbar("Error Service", "Gagal memuat daftar pengampu: $e");
      return [];
    }
  }


  // ... (Fungsi addSiswaToKelompok, _addSiswaToBatch, _updateStatusSiswaInBatch tidak berubah)
  Future<bool> addSiswaToKelompok({
    required List<Map<String, dynamic>> daftarSiswaTerpilih,
    required Map<String, dynamic> infoKelompok,
  }) async {
    if (daftarSiswaTerpilih.isEmpty) {
      Get.snackbar("Info", "Tidak ada siswa yang dipilih.");
      return false;
    }
    try {
      final WriteBatch batch = _firestore.batch();
      final String idTahunAjaran = infoKelompok['idTahunAjaran'];
      final String semesterAktif = _semesterAktif;
      for (var siswaData in daftarSiswaTerpilih) {
        _addSiswaToBatch(
          batch: batch,
          siswaData: siswaData,
          infoKelompok: infoKelompok,
          semesterAktif: semesterAktif,
        );
        _updateStatusSiswaInBatch(
          batch: batch,
          nisnSiswa: siswaData['nisn'],
          idTahunAjaran: idTahunAjaran,
          kelasId: siswaData['kelas'],
          semesterId: semesterAktif,
        );
      }
      await batch.commit();
      return true;
    } catch (e) {
      Get.snackbar("Error Service", "Gagal menambahkan siswa: $e");
      return false;
    }
  }

  void _addSiswaToBatch({
    required WriteBatch batch,
    required Map<String, dynamic> siswaData,
    required Map<String, dynamic> infoKelompok,
    required String semesterAktif,
  }) {
    final idTahunAjaran = infoKelompok['idTahunAjaran'];
    final dataUntukSiswa = {
      'namasiswa': siswaData['namasiswa'],
      'nisn': siswaData['nisn'],
      'kelas': siswaData['kelas'],
      'fase': infoKelompok['fase'],
      'tempatmengaji': infoKelompok['tempatmengaji'],
      'tahunajaran': infoKelompok['tahunajaran'],
      'kelompokmengaji': infoKelompok['namapengampu'],
      'namapengampu': infoKelompok['namapengampu'],
      'idpengampu': infoKelompok['idpengampu'],
      'emailpenginput': _homeController.auth.currentUser!.email,
      'idpenginput': _homeController.auth.currentUser!.uid,
      'tanggalinput': DateTime.now().toIso8601String(),
      'idsiswa': siswaData['nisn'],
      'ummi': '0',
      'semester': semesterAktif,
      'profileImageUrl': siswaData['profileImageUrl'],
    };
    DocumentReference siswaDiKelompokRef = _firestore
        .collection('Sekolah').doc(_idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(infoKelompok['fase'])
        .collection('pengampu').doc(infoKelompok['idpengampu'])
        .collection('tempat').doc(infoKelompok['tempatmengaji'])
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').doc(siswaData['nisn']);
    batch.set(siswaDiKelompokRef, dataUntukSiswa);
    DocumentReference refDiSiswa = _firestore.collection('Sekolah')
        .doc(_idSekolah).collection('siswa').doc(siswaData['nisn'])
        .collection('tahunajarankelompok').doc(idTahunAjaran);

    batch.set(refDiSiswa, {'namatahunajaran': infoKelompok['tahunajaran']});
    batch.set(refDiSiswa.collection('semester').doc(semesterAktif).collection('kelompokmengaji').doc(infoKelompok['fase']), {
        'fase': infoKelompok['fase'],
        'namapengampu': infoKelompok['namapengampu'],
        'tempatmengaji': infoKelompok['tempatmengaji'],
        'idpengampu': infoKelompok['idpengampu'],
    });
  }

  void _updateStatusSiswaInBatch({
    required WriteBatch batch,
    required String nisnSiswa,
    required String idTahunAjaran,
    required String kelasId,
    required String semesterId,
  }) {
    final DocumentReference siswaRef = _firestore
        .collection('Sekolah').doc(_idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(kelasId)
        .collection('semester').doc(semesterId)
        .collection('daftarsiswa').doc(nisnSiswa);
    batch.update(siswaRef, {'statuskelompok': 'aktif'});
  }

  Future<bool> inputNilaiMassal({
    required Map<String, dynamic> infoKelompok,
    required List<Map<String, dynamic>> semuaSiswaDiKelompok,
    required List<String> daftarNisnTerpilih,
    required Map<String, String> nilaiPerSiswa,
    required Map<String, dynamic> templateData,
    }) async {
    if (daftarNisnTerpilih.isEmpty) {
      Get.snackbar("Info", "Tidak ada siswa yang dipilih.");
      return false;
    }

    // --- TAHAP 1: Simpan data nilai (Tidak ada perubahan di sini) ---
    try {
      final WriteBatch batch = _firestore.batch();
      final DateTime now = DateTime.now();
      final String docIdNilaiHarian = DateFormat('yyyy-MM-dd').format(now);
      await batch.commit();

      // --- [NOTIFIKASI] TAHAP 2: Buat notifikasi dengan path yang benar ---
      try {
        final WriteBatch notifBatch = _firestore.batch();
        final siswaYangDinilai = semuaSiswaDiKelompok
            .where((siswa) => daftarNisnTerpilih.contains(siswa['nisn']))
            .toList();

        for (var siswaData in siswaYangDinilai) {
          final nisn = siswaData['nisn'] as String;
          final namaSiswa = siswaData['namasiswa'] as String;
          final nilaiInput = nilaiPerSiswa[nisn] ?? '';

          if (nilaiInput.isNotEmpty) {
            // [PERBAIKAN KUNCI] Path ini sekarang menunjuk ke koleksi 'siswa' utama.
            final siswaDocRef = _firestore
                .collection('Sekolah').doc(_idSekolah)
                .collection('siswa').doc(nisn);

            final notifDocRef = siswaDocRef.collection('notifikasi').doc();
            final notifData = {
              'judul': 'Nilai Harian Tahsin',
              'isi': 'Ananda $namaSiswa baru saja mendapatkan nilai "$nilaiInput" dari ${infoKelompok['namapengampu']}.',
              'tipe': 'NILAI_HALAQOH',
              'tanggal': FieldValue.serverTimestamp(),
              'isRead': false,
              'deepLink': '/halaqoh/nilai_harian/$nisn',
              'pengirim': infoKelompok['namapengampu'],
            };

            notifBatch.set(notifDocRef, notifData);
            notifBatch.update(siswaDocRef, {'unreadNotificationCount': FieldValue.increment(1)});
          }
        }
        await notifBatch.commit();
        print("Log: Notifikasi dan counter berhasil dibuat ke path siswa utama.");
      } catch (e) {
        print("Error [Non-Fatal]: Gagal saat membuat notifikasi: $e");
      }

      return true;
    } catch (e) {
      Get.snackbar("Error Service", "Gagal menyimpan nilai massal: $e");
      return false;
    }
  }

  Future<bool> tandaiSiapUjianMassal({
    required Map<String, dynamic> infoKelompok,
    required List<SiswaHalaqoh> siswaTerpilih,
  }) async {
    if (siswaTerpilih.isEmpty) {
      Get.snackbar("Info", "Tidak ada siswa yang dipilih.");
      return false;
    }
    try {
      final WriteBatch batch = _firestore.batch();
      final DateTime now = DateTime.now();
      final String uidPendaftar = _homeController.auth.currentUser!.uid;
      for (SiswaHalaqoh siswa in siswaTerpilih) {
        final refSiswaInduk = _getRefSiswaInduk(infoKelompok, siswa.nisn);
        final refUjianBaru = refSiswaInduk.collection('ujian').doc();
        batch.update(refSiswaInduk, {'status_ujian': 'siap_ujian'});
        batch.set(refUjianBaru, {
          'namasiswa': siswa.namaSiswa,
          'status_ujian': 'siap_ujian',
          'level_ujian': siswa.ummi,
          'capaian_saat_didaftarkan': siswa.capaian,
          'tanggal_didaftarkan': now,
          'didaftarkan_oleh': uidPendaftar,
          'semester': _semesterAktif,
          'tanggal_ujian': null,
          'diuji_oleh': null,
          'catatan_penguji': null,
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      Get.snackbar("Error Service", "Gagal menandai siap ujian: $e");
      return false;
    }
  }

  DocumentReference _getRefSiswaInduk(Map<String, dynamic> infoKelompok, String nisn) {
    final String idPengampuUntukQuery = infoKelompok['idPengampuAsli'] ?? infoKelompok['idpengampu'];
    return _firestore
        .collection('Sekolah').doc(_idSekolah)
        .collection('tahunajaran').doc(infoKelompok['idTahunAjaran'] ?? _idTahunAjaran)
        .collection('kelompokmengaji').doc(infoKelompok['fase'])
        .collection('pengampu').doc(idPengampuUntukQuery)
        .collection('tempat').doc(infoKelompok['tempatmengaji'])
        .collection('semester').doc(_semesterAktif)
        .collection('daftarsiswa').doc(nisn);
  }

  String _getGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 85) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 75) return 'B-';
    if (score >= 70) return 'C+';
    if (score >= 65) return 'C';
    if (score >= 60) return 'C-';
    return 'D';
  }
}
