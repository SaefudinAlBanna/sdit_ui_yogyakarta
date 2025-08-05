import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/controllers/home_controller.dart';

class PemberianGuruMapelController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final String idSekolah = '20404148'; // Pastikan ID benar
  late String idTahunAjaran;
  
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMapel = false.obs;
  
  final RxList<String> daftarKelas = <String>[].obs;
  final RxList<Map<String, String>> daftarGuru = <Map<String, String>>[].obs;
  
  // [DIROMBAK] Sekarang menyimpan seluruh objek Mapel (Map), bukan hanya nama (String)
  final RxList<Map<String, dynamic>> daftarMapelWajib = <Map<String, dynamic>>[].obs;
  
  final Rxn<String> kelasTerpilih = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      isLoading.value = true;
      idTahunAjaran = homeC.idTahunAjaran.value!;
      
      // Jalankan pengambilan data secara bersamaan untuk efisiensi
      await Future.wait([
        _fetchDaftarKelas(),
        _fetchDaftarGuru(),
      ]);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data awal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // [DIROMBAK] Logika pengambilan mapel dari master kurikulum
  Future<void> gantiKelasTerpilih(String namaKelas) async {
    if (kelasTerpilih.value == namaKelas) return;
    kelasTerpilih.value = namaKelas;
    isLoadingMapel.value = true;
    daftarMapelWajib.clear();

    try {
      final String kelasAngka = namaKelas.substring(0, 1);
      final String idFase = (kelasAngka == '1' || kelasAngka == '2') ? "fase_a" : (kelasAngka == '3' || kelasAngka == '4') ? "fase_b" : "fase_c";
      
      final kurikulumDoc = await firestore.collection('konfigurasi_kurikulum').doc(idFase).get();
      if (!kurikulumDoc.exists || kurikulumDoc.data()?['matapelajaran'] == null) {
        throw Exception("Konfigurasi kurikulum untuk $idFase tidak ditemukan.");
      }
      
      final List<dynamic> mapelDariDB = kurikulumDoc.data()!['matapelajaran'];
      // [PENTING] Mengambil seluruh Map, bukan hanya nama
      daftarMapelWajib.assignAll(mapelDariDB.map((e) => e as Map<String, dynamic>).toList());

    } catch (e) {
      Get.snackbar("Gagal Memuat Kurikulum", e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoadingMapel.value = false;
    }
  }

    Future<void> _fetchDaftarKelas() async {
      // Memastikan kita mengambil dari sumber yang benar (kelastahunajaran)
      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').get();
      daftarKelas.assignAll(snapshot.docs.map((doc) => doc.id).toList()..sort());
    }
    
   
   Future<void> _fetchDaftarGuru() async {
      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah).collection('pegawai')
          .where('role', whereIn: ['Pengampu', 'Guru Kelas', 'Guru Mapel']).get();

      final guruList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'nama': data['alias'] as String? ?? 'Tanpa Nama',
          'role': data['role'] as String? ?? 'Tanpa Role',
        };
      }).toList();
      daftarGuru.assignAll(guruList);
   }
  
  // [DIROMBAK] Stream sekarang menargetkan dokumen berdasarkan idMapel
  Stream<QuerySnapshot<Map<String, dynamic>>> getAssignedMapelStream() {
    if (kelasTerpilih.value == null) return const Stream.empty();
    
    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('penugasan').doc(kelasTerpilih.value!)
        .collection('matapelajaran') // Di sini dokumennya adalah {idMapel}
        .snapshots();
  }

  // [DIROMBAK TOTAL] Fungsi ini sekarang menggunakan idMapel sebagai kunci
  Future<void> assignGuruToMapel(String idGuru, String namaGuru, String idMapel, String namaMapel) async {
    if (kelasTerpilih.value == null) return;
    final String namaKelas = kelasTerpilih.value!;
    final String semesterAktif = homeC.semesterAktifId.value;

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      WriteBatch batch = firestore.batch();
      
      // [PATH BARU] Path penugasan sekarang menggunakan idMapel sebagai ID dokumen
      final penugasanRef = firestore.collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('penugasan').doc(namaKelas)
          .collection('matapelajaran').doc(idMapel); // <-- KUNCI PERUBAHAN

      // [PATH BARU] Path di dokumen pegawai juga menggunakan idMapel
      final pegawaiMapelRef = firestore.collection('Sekolah').doc(idSekolah)
          .collection('pegawai').doc(idGuru)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('semester').doc(semesterAktif)
          .collection('kelasnya').doc(namaKelas)
          .collection('matapelajaran').doc(idMapel); // <-- KUNCI PERUBAHAN
      
      final pegawaiKelasRef = pegawaiMapelRef.parent.parent!;

      // [DATA BARU] Data yang disimpan sekarang lebih kaya
      final dataToSave = {
        'idMapel': idMapel,
        'namamatapelajaran': namaMapel,
        'idGuru': idGuru,
        'guru': namaGuru,
        'idKelas': namaKelas,
        'idTahunAjaran': idTahunAjaran,
        'semester': semesterAktif,
        'diinputPada': FieldValue.serverTimestamp(),
      };
      
      batch.set(pegawaiKelasRef, {'namaKelas': namaKelas}, SetOptions(merge: true));
      batch.set(penugasanRef, dataToSave);
      batch.set(pegawaiMapelRef, dataToSave);
      await batch.commit();
      
      Get.back();
      Get.snackbar('Berhasil', '$namaMapel telah diberikan kepada $namaGuru');
    } catch (e) {
      Get.back();
      Get.snackbar('Gagal', e.toString().replaceAll('Exception: ', ''));
    }
  }

  // [DIROMBAK TOTAL] Fungsi ini sekarang menggunakan idMapel untuk menghapus
  Future<void> removeGuruFromMapel(String idMapel) async {
    if (kelasTerpilih.value == null) return;
    final String namaKelas = kelasTerpilih.value!;
    final String semesterAktif = homeC.semesterAktifId.value;

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      // [PATH BARU] Path penugasan menggunakan idMapel
      final penugasanRef = firestore.collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('penugasan').doc(namaKelas)
          .collection('matapelajaran').doc(idMapel); // <-- KUNCI PERUBAHAN
          
      final doc = await penugasanRef.get();
      if (!doc.exists) throw Exception('Data penugasan tidak ditemukan.');
      
      final String idGuru = doc.data()!['idGuru'];

      // [PATH BARU] Path di dokumen pegawai juga menggunakan idMapel
      final pegawaiMapelRef = firestore.collection('Sekolah').doc(idSekolah)
          .collection('pegawai').doc(idGuru)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('semester').doc(semesterAktif)
          .collection('kelasnya').doc(namaKelas)
          .collection('matapelajaran').doc(idMapel); // <-- KUNCI PERUBAHAN

      // Logika cerdas untuk menghapus folder kelas jika ini mapel terakhir (TETAP SAMA)
      final mapelDiajarSnapshot = await pegawaiMapelRef.parent.get();

      WriteBatch batch = firestore.batch();
      batch.delete(penugasanRef);
      batch.delete(pegawaiMapelRef);

      if (mapelDiajarSnapshot.docs.length == 1) {
        batch.delete(pegawaiMapelRef.parent.parent!);
      }
      await batch.commit();

      Get.back();
      Get.snackbar('Berhasil', 'Guru untuk mata pelajaran telah dihapus.');
    } catch (e) {
      Get.back();
      Get.snackbar('Gagal', e.toString());
    }
  }
}