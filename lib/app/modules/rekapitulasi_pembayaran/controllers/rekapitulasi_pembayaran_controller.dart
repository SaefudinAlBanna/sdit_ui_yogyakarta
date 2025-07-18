// lib/app/modules/rekapitulasi_pembayaran/controllers/rekapitulasi_pembayaran_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// --- MODEL DATA (Tidak berubah) ---
// --- MODEL DATA (PERBAIKAN) ---
class RekapitulasiItem {
  String namaItem; // Dihapus final
  double totalDiterima; // Dihapus final
  double totalKekurangan; // Dihapus final
  
  RekapitulasiItem({
    required this.namaItem, 
    this.totalDiterima = 0.0, 
    this.totalKekurangan = 0.0
  });
}

class RekapKelas {
  final String namaKelas;
  final int jumlahSiswa;
  final double totalPenerimaan;
  final double totalKekurangan;
  final List<RekapitulasiItem> rincian; // Rincian per jenis pembayaran
  RekapKelas({
    required this.namaKelas,
    required this.jumlahSiswa,
    required this.totalPenerimaan,
    required this.totalKekurangan,
    required this.rincian,
  });
}

class RekapitulasiPembayaranController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String idSekolah = "20404148";

  // --- DEFINISI JENIS PEMBAYARAN (SANGAT PENTING!) ---
  final List<String> JENIS_PEMBAYARAN_TAHUNAN = ['Daftar Ulang', 'Kegiatan'];
  final List<String> JENIS_PEMBAYARAN_SEKALI_SEUMUR_HIDUP = ['Iuran Pangkal', 'Seragam', 'UPK ASPD'];
  
  var isLoading = true.obs;
  var statusMessage = "Menginisialisasi...".obs;

  var rekapPerKelas = <RekapKelas>[].obs;
  var totalPenerimaanSekolah = 0.0.obs;
  var totalKekuranganSekolah = 0.0.obs;
  var totalSiswaSekolah = 0.obs;

  @override
  void onInit() {
    super.onInit();
    hitungRekapitulasi();
  }

  Future<void> hitungRekapitulasi() async {
    try {
      isLoading.value = true;
      _resetData();

      statusMessage.value = "Mengambil data tahun ajaran...";
      final idTahunAjaran = (await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').orderBy('namatahunajaran', descending: true).limit(1).get()).docs.first.id;
      
      statusMessage.value = "Mengambil data kewajiban pembayaran...";
      final kewajibanTahunan = await _getKewajibanTahunan(idTahunAjaran);
      
      statusMessage.value = "Mengambil data master siswa...";
      final semuaSiswaMaster = await _getSemuaSiswaMaster();
      
      statusMessage.value = "Mengambil data riwayat pembayaran (SPP)...";
      final semuaSppBayar = await _getSemuaPembayaranSpp(idTahunAjaran);
      
      statusMessage.value = "Mengambil data riwayat pembayaran lain...";
      final semuaPembayaranLain = await _getSemuaPembayaranLain();
      
      statusMessage.value = "Menghitung rekapitulasi per kelas...";
      final kelasSnapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').get();
      
      for (var kelasDoc in kelasSnapshot.docs) {
        String namaKelas = kelasDoc.data()['namakelas'] ?? kelasDoc.id;
        final siswaDiKelasSnapshot = await kelasDoc.reference.collection('daftarsiswa').get();
        totalSiswaSekolah.value += siswaDiKelasSnapshot.docs.length;

        Map<String, RekapitulasiItem> rincianPerJenis = {};
        
        for (var siswaDoc in siswaDiKelasSnapshot.docs) {
          final idSiswa = siswaDoc.id;
          final masterSiswa = semuaSiswaMaster[idSiswa];
          if (masterSiswa == null) continue;

          _prosesSppUntukSiswa(idSiswa, masterSiswa, semuaSppBayar, rincianPerJenis);
          _prosesPembayaranTahunan(idSiswa, kewajibanTahunan, semuaPembayaranLain[idTahunAjaran]?[idSiswa] ?? [], rincianPerJenis);
          _prosesPembayaranSekaliSeumurHidup(idSiswa, masterSiswa, semuaPembayaranLain, rincianPerJenis);
        }

        double totalPenerimaanKelas = rincianPerJenis.values.fold(0.0, (sum, item) => sum + item.totalDiterima);
        double totalKekuranganKelas = rincianPerJenis.values.fold(0.0, (sum, item) => sum + item.totalKekurangan);
        
        rekapPerKelas.add(RekapKelas(
          namaKelas: namaKelas,
          jumlahSiswa: siswaDiKelasSnapshot.size,
          totalPenerimaan: totalPenerimaanKelas,
          totalKekurangan: totalKekuranganKelas,
          rincian: rincianPerJenis.values.toList()..sort((a,b) => a.namaItem.compareTo(b.namaItem)),
        ));
        totalPenerimaanSekolah.value += totalPenerimaanKelas;
        totalKekuranganSekolah.value += totalKekuranganKelas;
      }
      rekapPerKelas.sort((a, b) => a.namaKelas.compareTo(b.namaKelas));

    } catch (e, s) {
      Get.snackbar("Error", "Gagal menghitung rekapitulasi: $e");
      debugPrint("Error rekap: $e\n$s");
    } finally {
      isLoading.value = false;
    }
  }
  
  void _prosesSppUntukSiswa(String idSiswa, Map<String, dynamic> masterSiswa, Map<String, int> semuaSppBayar, Map<String, RekapitulasiItem> rincian) {
    double sppWajibPerBulan = (masterSiswa['SPP'] as num?)?.toDouble() ?? 0.0;
    if (sppWajibPerBulan <= 0) return;
    
    int bulanWajib = _hitungBulanWajibSpp();
    int bulanSudahBayar = semuaSppBayar[idSiswa] ?? 0;
    
    double diterima = bulanSudahBayar * sppWajibPerBulan;
    double kurang = (bulanWajib - bulanSudahBayar) * sppWajibPerBulan;
    
    _akumulasiRincian(rincian, 'SPP', diterima, kurang);
  }

  // --- PERBAIKAN ERROR TIPE DATA DI SINI ---
  void _prosesPembayaranTahunan(String idSiswa, Map<String, double> kewajibanTahunan, List<DocumentSnapshot> riwayatBayar, Map<String, RekapitulasiItem> rincian) {
    for (String jenis in JENIS_PEMBAYARAN_TAHUNAN) {
      double harusBayar = kewajibanTahunan[jenis] ?? 0.0;
      if (harusBayar <= 0) continue;
      
      double sudahBayar = riwayatBayar
          .where((doc) => doc.data() is Map && (doc.data() as Map)['jenis'] == jenis)
          .fold(0.0, (num sum, doc) => sum + ((((doc.data() as Map)['nominal'] as num?)?.toDouble()) ?? 0.0));
          
      // Gunakan nilai default 0.0 jika harusBayar null
      _akumulasiRincian(rincian, jenis, sudahBayar, (harusBayar ?? 0.0) - sudahBayar);
    }
  }

  // --- PERBAIKAN ERROR TIPE DATA DI SINI ---
  void _prosesPembayaranSekaliSeumurHidup(String idSiswa, Map<String, dynamic> masterSiswa, Map<String, Map<String, List<DocumentSnapshot>>> semuaPembayaranLain, Map<String, RekapitulasiItem> rincian) {
    for (String jenis in JENIS_PEMBAYARAN_SEKALI_SEUMUR_HIDUP) {
      String fieldName = jenis.replaceAll(' ', '').replaceFirst(jenis[0], jenis[0].toLowerCase());
      double harusBayar = (masterSiswa[fieldName] as num?)?.toDouble() ?? 0.0;
      if (harusBayar <= 0) continue;

      double sudahBayar = 0.0;
      semuaPembayaranLain.forEach((tahun, dataSiswa) {
        if (dataSiswa.containsKey(idSiswa)) {
          sudahBayar += dataSiswa[idSiswa]!
              .where((doc) => doc.data() is Map && (doc.data() as Map)['jenis'] == jenis)
              .fold<double>(0.0, (double sum, doc) => sum + ((((doc.data() as Map)['nominal'] as num?)?.toDouble()) ?? 0.0));
        }
      });
      
      // Gunakan nilai default 0.0 jika harusBayar null
      _akumulasiRincian(rincian, jenis, sudahBayar, (harusBayar ?? 0.0) - sudahBayar);
    }
  }

  // void _akumulasiRincian(Map<String, RekapitulasiItem> rincian, String jenis, double diterima, double kurang) {
  //   if (!rincian.containsKey(jenis)) {
  //     rincian[jenis] = RekapitulasiItem(namaItem: jenis);
  //   }
  //   rincian[jenis] = RekapitulasiItem(
  //     namaItem: jenis,
  //     totalDiterima: rincian[jenis]!.totalDiterima + (diterima > 0 ? diterima : 0),
  //     totalKekurangan: rincian[jenis]!.totalKekurangan + (kurang > 0 ? kurang : 0),
  //   );
  // }

  void _akumulasiRincian(Map<String, RekapitulasiItem> rincian, String jenis, double diterima, double kurang) {
  // Jika jenis pembayaran ini belum ada di map rincian, buat baru.
  rincian.putIfAbsent(jenis, () => RekapitulasiItem(namaItem: jenis));

  // Ambil item yang ada dan langsung tambahkan nilainya.
  final item = rincian[jenis]!;
  item.totalDiterima += (diterima > 0 ? diterima : 0);
  item.totalKekurangan += (kurang > 0 ? kurang : 0);
}

  Future<Map<String, double>> _getKewajibanTahunan(String idTahunAjaran) async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('biaya').get();
    return {for (var doc in snapshot.docs) doc.id: (doc.data()['nominal'] as num?)?.toDouble() ?? 0.0};
  }

  Future<Map<String, Map<String, dynamic>>> _getSemuaSiswaMaster() async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('siswa').get();
    return {for (var doc in snapshot.docs) doc.id: doc.data()};
  }
  
  // Future<Map<String, int>> _getSemuaPembayaranSpp(String idTahunAjaran) async {
  //   // Query ini perlu disesuaikan agar bisa bekerja tanpa index composite
  //   final snapshot = await firestore.collectionGroup('SPP').get();
  //   Map<String, int> hasil = {};
  //   for (var doc in snapshot.docs) {
  //     // Filter manual karena query collectionGroup dengan where di __name__ kompleks
  //     if (doc.reference.path.contains(idTahunAjaran)) {
  //       String idSiswa = doc.reference.parent.parent!.id;
  //       hasil[idSiswa] = (hasil[idSiswa] ?? 0) + 1;
  //     }
  //   }
  //   return hasil;
  // }

  Future<Map<String, int>> _getSemuaPembayaranSpp(String idTahunAjaran) async {
  final snapshot = await firestore.collectionGroup('SPP').get();
  Map<String, int> hasil = {};
  
  debugPrint("[Rekapitulasi] Mengecek ${snapshot.docs.length} dokumen pembayaran SPP dari collectionGroup...");

  for (var doc in snapshot.docs) {
    // Path dokumen SPP: /Sekolah/{idSekolah}/tahunajaran/{idTahunAjaran}/kelastahunajaran/{idKelas}/daftarsiswa/{idSiswa}/SPP/{idBulan}
    final pathSegments = doc.reference.path.split('/');

    // Validasi panjang path untuk mencegah error
    if (pathSegments.length >= 7) {
      final docTahunAjaranId = pathSegments[pathSegments.length - 7];
      
      // Filter berdasarkan idTahunAjaran yang sedang direkap
      if (docTahunAjaranId == idTahunAjaran) {
        final idSiswa = pathSegments[pathSegments.length - 3];
        hasil[idSiswa] = (hasil[idSiswa] ?? 0) + 1;
        // debugPrint("[Rekapitulasi] Ditemukan SPP untuk siswa $idSiswa di tahun ajaran $idTahunAjaran.");
      }
    } else {
      debugPrint("[Rekapitulasi] Peringatan: Path dokumen SPP tidak valid dan dilewati: ${doc.reference.path}");
    }
  }
  
  debugPrint("[Rekapitulasi] Selesai memproses SPP. Total ${hasil.length} siswa memiliki riwayat bayar SPP di tahun ini.");
  return hasil;
}



  // Future<Map<String, Map<String, List<DocumentSnapshot>>>> _getSemuaPembayaranLain() async {
  //   Map<String, Map<String, List<DocumentSnapshot>>> hasil = {};
  //   final snapshot = await firestore.collectionGroup('PembayaranLain').get();
  //   for (var doc in snapshot.docs) {
  //     try {
  //       final pathSegments = doc.reference.path.split('/');
  //       final idSiswa = pathSegments[pathSegments.length - 3];
  //       final idTahunAjaran = pathSegments[pathSegments.length - 7];
        
  //       hasil.putIfAbsent(idTahunAjaran, () => {});
  //       hasil[idTahunAjaran]!.putIfAbsent(idSiswa, () => []).add(doc);
  //     } catch (e) {
  //       debugPrint("Gagal memproses path pembayaran: ${doc.reference.path}");
  //     }
  //   }
  //   return hasil;
  // }

  Future<Map<String, Map<String, List<DocumentSnapshot>>>> _getSemuaPembayaranLain() async {
  Map<String, Map<String, List<DocumentSnapshot>>> hasil = {};
  final snapshot = await firestore.collectionGroup('PembayaranLain').get();
  
  debugPrint("[Rekapitulasi] Mengecek ${snapshot.docs.length} dokumen 'PembayaranLain' dari collectionGroup...");

  for (var doc in snapshot.docs) {
    try {
      final pathSegments = doc.reference.path.split('/');
      final idSiswa = pathSegments[pathSegments.length - 3];
      final idTahunAjaran = pathSegments[pathSegments.length - 7];
      
      hasil.putIfAbsent(idTahunAjaran, () => {});
      hasil[idTahunAjaran]!.putIfAbsent(idSiswa, () => []).add(doc);
    } catch (e) {
      debugPrint("[Rekapitulasi] Gagal memproses path pembayaran lain: ${doc.reference.path}");
    }
  }
  debugPrint("[Rekapitulasi] Selesai memproses PembayaranLain.");
  return hasil;
}
  
  // --- PERBAIKAN ERROR UNDEFINED NAME DI SINI ---
  void _resetData() {
    rekapPerKelas.clear();
    totalPenerimaanSekolah.value = 0.0;
    totalKekuranganSekolah.value = 0.0;
    totalSiswaSekolah.value = 0;
  }

  int _hitungBulanWajibSpp() {
    final now = DateTime.now();
    // Jika tahun ajaran saat ini, hitung sampai bulan sekarang.
    // Jika tahun ajaran lampau, hitung 12 bulan penuh.
    // Logika ini bisa disempurnakan tergantung kebutuhan rekap tahun lalu.
    // Untuk sekarang, kita asumsikan rekap untuk tahun ajaran aktif.
    if (now.month >= 7) { // Semester ganjil (Juli-Desember)
      return now.month - 6;
    } else { // Semester genap (Januari-Juni)
      return now.month + 6;
    }
  }
  
  String formatRupiah(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
}