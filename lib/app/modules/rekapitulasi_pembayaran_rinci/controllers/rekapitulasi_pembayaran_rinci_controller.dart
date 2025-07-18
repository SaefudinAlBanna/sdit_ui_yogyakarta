import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// --- MODEL DATA (Tidak berubah) ---
class Transaksi {
  final DateTime tglBayar;
  final double nominal;
  final String petugas;
  final String? bulan; // Khusus untuk SPP
  final String? keterangan; // Khusus untuk PembayaranLain

  Transaksi({
    required this.tglBayar,
    required this.nominal,
    required this.petugas,
    this.bulan,
    this.keterangan,
  });
}

class PembayaranSiswaSummary {
  final String idKelas;
  final String idSiswa;
  final String namaSiswa;
  final String kelas;
  final String jenisPembayaran;
  final double totalHarusBayar;
  final double totalSudahBayar;
  final double sisaKekurangan;
  final String keteranganStatus;
  final Color warnaStatus;
  final List<Transaksi> riwayatTransaksi;
  final List<String> daftarTunggakanBulan; // Khusus untuk SPP

  PembayaranSiswaSummary({
    required this.idKelas,
    required this.idSiswa,
    required this.namaSiswa,
    required this.kelas,
    required this.jenisPembayaran,
    required this.totalHarusBayar,
    required this.totalSudahBayar,
    required this.sisaKekurangan,
    required this.keteranganStatus,
    required this.warnaStatus,
    required this.riwayatTransaksi,
    required this.daftarTunggakanBulan,
  });
}

// --- CONTROLLER YANG SUDAH DIREVISI TOTAL ---
class RekapitulasiPembayaranRinciController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String idSekolah = "20404148";
  
  // --- PERUBAIKAN: Daftar jenis pembayaran disamakan dengan controller rekapitulasi ---
  final List<String> jenisPembayaranList = [
    'SPP', 'Daftar Ulang', 'Kegiatan', 'Iuran Pangkal', 'Seragam', 'UPK ASPD'
  ];
  final List<String> JENIS_PEMBAYARAN_TAHUNAN = ['Daftar Ulang', 'Kegiatan'];
  final List<String> JENIS_PEMBAYARAN_SEKALI_SEUMUR_HIDUP = ['Kegiatan', 'Iuran Pangkal', 'Seragam', 'UPK ASPD'];

  var isLoading = true.obs;
  var searchController = TextEditingController();
  var searchTerm = ''.obs;
  var daftarKelas = <String>['Semua Kelas'].obs;
  var selectedKelas = 'Semua Kelas'.obs;
  
  var allSummaries = <String, List<PembayaranSiswaSummary>>{}.obs;
  String? _idTahunAjaran;

  @override
  void onInit() {
    super.onInit();
    fetchRincianPembayaran();
    searchController.addListener(() => searchTerm.value = searchController.text);
  }

  // FUNGSI HELPER BARU
Future<String> _getNamaPetugas() async {
  try {
    // 1. Ambil email user yang sedang login
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return 'Tanpa Nama'; // Fallback jika tidak ada user login
    }

    // 2. Ambil dokumen pegawai berdasarkan email
    final docSnapshot = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(uid)
        .get();

    // 3. Jika dokumen ada, format nama dan role
    if (docSnapshot.exists && docSnapshot.data() != null) {
      final data = docSnapshot.data()!;
      final nama = data['alias'] as String?;
      final role = data['role'] as String?;

      if (nama != null && role != null) {
        return '$nama ($role)'; // Hasil: "Budi Santoso (Admin Keuangan)"
      } else if (nama != null) {
        return nama; // Fallback jika hanya ada nama
      }
    }
    
    // 4. Jika dokumen tidak ada, kembalikan email sebagai default
    return uid;
  } catch (e) {
    // Jika terjadi error, kembalikan email agar proses tidak gagal
    return FirebaseAuth.instance.currentUser?.email ?? 'Error Petugas';
  }
}

  // --- PERUBAIKAN UTAMA: LOGIKA PENGAMBILAN DATA DIROMBAK TOTAL ---
  Future<void> fetchRincianPembayaran() async {
    try {
      isLoading.value = true;
      allSummaries.clear();
      daftarKelas.value = ['Semua Kelas'];

      // 1. Ambil data-data master
      _idTahunAjaran = (await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').orderBy('namatahunajaran', descending: true).limit(1).get()).docs.first.id;
      final kewajibanTahunan = await _getKewajibanTahunan(_idTahunAjaran!);
      final semuaSiswaMaster = await _getSemuaSiswaMaster();
      final semuaSiswaDiTahunAjaran = await _getAllSiswaWithKelas(_idTahunAjaran!);
      
      // 2. Ambil semua riwayat pembayaran untuk tahun ini secara massal
      final semuaSppBayar = await _getSemuaPembayaranSpp(_idTahunAjaran!);
      final semuaPembayaranLain = await _getSemuaPembayaranLain(_idTahunAjaran!);

      // 3. Tambahkan daftar kelas ke filter
      final kelasSet = semuaSiswaDiTahunAjaran.values.map((data) => data['kelas'] as String).toSet();
      daftarKelas.addAll(kelasSet.toList()..sort());

      // 4. Proses data yang sudah diambil
      for (var jenis in jenisPembayaranList) {
        List<PembayaranSiswaSummary> summariesForJenis = [];

        for (var siswaDiKelas in semuaSiswaDiTahunAjaran.entries) {
          final idSiswa = siswaDiKelas.key;
          final dataSiswaDiKelas = siswaDiKelas.value;
          final masterSiswa = semuaSiswaMaster[idSiswa];

          if (masterSiswa == null) continue;

          // Ambil riwayat transaksi dari data yang sudah di-fetch
          List<Transaksi> riwayatTransaksiSiswa = [];
          if (jenis == 'SPP') {
            riwayatTransaksiSiswa = semuaSppBayar[idSiswa] ?? [];
          } else {
            riwayatTransaksiSiswa = (semuaPembayaranLain[idSiswa] ?? []).where((trx) => trx.keterangan == jenis).toList();
          }

          // Hitung kewajiban siswa
          double harusBayar = _getKewajibanSiswa(jenis, masterSiswa, kewajibanTahunan);
          
          if (harusBayar <= 0 && riwayatTransaksiSiswa.isEmpty) continue; // Lewati jika tidak ada tagihan & tidak ada pembayaran

          // Proses menjadi summary
          if (jenis == 'SPP') {
            summariesForJenis.add(_prosesSpp(idSiswa, dataSiswaDiKelas, riwayatTransaksiSiswa, harusBayar));
          } else {
            summariesForJenis.add(_prosesPembayaranLain(idSiswa, dataSiswaDiKelas, riwayatTransaksiSiswa, jenis, harusBayar));
          }
        }
        allSummaries[jenis] = summariesForJenis;
      }
    } catch (e, s) {
      Get.snackbar("Error", "Gagal mengambil data rinci: $e");
      debugPrint("Error Rinci: $e\nStacktrace: $s");
    } finally {
      isLoading.value = false;
    }
  }

  // --- FUNGSI HELPER BARU (disamakan dengan controller rekap) ---
  
  double _getKewajibanSiswa(String jenis, Map<String, dynamic> masterSiswa, Map<String, double> kewajibanTahunan) {
    if (jenis == 'SPP') {
      // Mengatasi inkonsistensi nama field 'spp' vs 'SPP'
      return (masterSiswa['SPP'] as num?)?.toDouble() ?? (masterSiswa['SPP'] as num?)?.toDouble() ?? 0.0;
    }
    if (JENIS_PEMBAYARAN_TAHUNAN.contains(jenis)) {
      return kewajibanTahunan[jenis] ?? 0.0;
    }
    if (JENIS_PEMBAYARAN_SEKALI_SEUMUR_HIDUP.contains(jenis)) {
      // String fieldName = jenis.replaceAll(' ', '').replaceFirst(jenis[0], jenis[0].toLowerCase());
      // return (masterSiswa[fieldName] as num?)?.toDouble() ?? 0.0;
      return (masterSiswa[jenis] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  Future<Map<String, double>> _getKewajibanTahunan(String idTahunAjaran) async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('biaya').get();
    return {for (var doc in snapshot.docs) doc.id: (doc.data()['nominal'] as num?)?.toDouble() ?? 0.0};
  }

  Future<Map<String, Map<String, dynamic>>> _getSemuaSiswaMaster() async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('siswa').get();
    return {for (var doc in snapshot.docs) doc.id: doc.data()};
  }

  Future<Map<String, Map<String, dynamic>>> _getAllSiswaWithKelas(String idTahunAjaran) async {
    Map<String, Map<String, dynamic>> siswaMap = {};
    final kelasSnapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').get();
    for (var kelasDoc in kelasSnapshot.docs) {
      final siswaSnapshot = await kelasDoc.reference.collection('daftarsiswa').get();
      for (var siswaDoc in siswaSnapshot.docs) {
        siswaMap[siswaDoc.id] = {
          'namasiswa': siswaDoc.data()['namasiswa'],
          'kelas': kelasDoc.data()['namakelas'] ?? kelasDoc.id, // Ambil nama kelas
          'idKelas': kelasDoc.id, // Simpan ID kelas untuk aksi bayar
        };
      }
    }
    return siswaMap;
  }

  Future<Map<String, List<Transaksi>>> _getSemuaPembayaranSpp(String idTahunAjaran) async {
  final snapshot = await firestore.collectionGroup('SPP').get();
  Map<String, List<Transaksi>> hasil = {};
  for (var doc in snapshot.docs) {
    if (!doc.reference.path.contains(idTahunAjaran)) continue;
    
    final pathSegments = doc.reference.path.split('/');
    if (pathSegments.length < 7) continue;

    final idSiswa = pathSegments[pathSegments.length - 3];
    final data = doc.data();
    final transaksi = Transaksi(
      // Lakukan pengecekan aman untuk semua field yang bisa null
      tglBayar: (data['tglbayar'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      // --- PERBAIKAN UTAMA DI SINI ---
      // 1. Coba cast sebagai num, boleh null (as num?)
      // 2. Jika tidak null, ubah ke double (.toDouble())
      // 3. Jika hasilnya null, gunakan nilai default 0.0 (?? 0.0)
      nominal: (data['nominal'] as num?)?.toDouble() ?? 0.0,
      
      petugas: data['petugas'] ?? '-',
      bulan: doc.id,
    );
    hasil.putIfAbsent(idSiswa, () => []).add(transaksi);
  }
  return hasil;
}

  Future<Map<String, List<Transaksi>>> _getSemuaPembayaranLain(String idTahunAjaran) async {
  final snapshot = await firestore.collectionGroup('PembayaranLain').where('tglbayar', isNull: false).get();
  Map<String, List<Transaksi>> hasil = {};
  for (var doc in snapshot.docs) {
    if (!doc.reference.path.contains(idTahunAjaran)) continue;

    final pathSegments = doc.reference.path.split('/');
    if (pathSegments.length < 7) continue;

    final idSiswa = pathSegments[pathSegments.length - 3];
    final data = doc.data();
    final transaksi = Transaksi(
      tglBayar: (data['tglbayar'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      // --- TERAPKAN PERBAIKAN YANG SAMA DI SINI ---
      nominal: (data['nominal'] as num?)?.toDouble() ?? 0.0,

      petugas: data['petugas'] ?? '-',
      keterangan: data['jenis'],
    );
    hasil.putIfAbsent(idSiswa, () => []).add(transaksi);
  }
  return hasil;
}

  // --- LOGIKA PEMROSESAN (SEDIKIT PENYESUAIAN) ---
  
  PembayaranSiswaSummary _prosesSpp(String idSiswa, Map<String, dynamic> siswaData, List<Transaksi> riwayatTransaksi, double nominalSppPerBulan) {
    Set<String> bulanSudahBayar = riwayatTransaksi.where((t) => t.bulan != null).map((t) => t.bulan!).toSet();
    int bulanWajib = _hitungBulanWajibSpp();
    int bulanNunggak = bulanWajib - bulanSudahBayar.length;
    bulanNunggak = bulanNunggak > 0 ? bulanNunggak : 0;
    
    List<String> tunggakanBulan = [];
    if (bulanNunggak > 0) {
      getListBulan().take(bulanWajib).forEach((bulan) {
        if (!bulanSudahBayar.contains(bulan)) tunggakanBulan.add(bulan);
      });
    }

    double totalSudahBayar = riwayatTransaksi.fold(0.0, (sum, item) => sum + item.nominal);
    double totalHarusBayar = nominalSppPerBulan * bulanWajib; // Total kewajiban sampai saat ini
    double sisaKekurangan = (nominalSppPerBulan * bulanNunggak).clamp(0, double.infinity);

    return PembayaranSiswaSummary(
      idSiswa: idSiswa, idKelas: siswaData['idKelas'], namaSiswa: siswaData['namasiswa'], kelas: siswaData['kelas'],
      jenisPembayaran: 'SPP', totalHarusBayar: totalHarusBayar,
      totalSudahBayar: totalSudahBayar, sisaKekurangan: sisaKekurangan,
      keteranganStatus: bulanNunggak == 0 ? "Lunas" : "$bulanNunggak bln nunggak",
      warnaStatus: bulanNunggak == 0 ? Colors.green : Colors.red,
      riwayatTransaksi: riwayatTransaksi, daftarTunggakanBulan: tunggakanBulan,
    );
  }

  PembayaranSiswaSummary _prosesPembayaranLain(String idSiswa, Map<String, dynamic> siswaData, List<Transaksi> riwayatTransaksi, String jenis, double harusBayar) {
    double sudahBayar = riwayatTransaksi.fold(0.0, (sum, item) => sum + item.nominal);
    double sisa = harusBayar - sudahBayar;
    String status; Color warna;

    if (harusBayar <= 0) { status = "Tidak Ada Tagihan"; warna = Colors.grey; } 
    else if (sisa <= 0) { status = "Lunas"; warna = Colors.green; } 
    else if (sudahBayar > 0) { status = "Kurang ${formatRupiah(sisa)}"; warna = Colors.orange.shade800; } 
    else { status = "Belum Bayar"; warna = Colors.red; }

    return PembayaranSiswaSummary(
      idSiswa: idSiswa, namaSiswa: siswaData['namasiswa'], idKelas: siswaData['idKelas'], kelas: siswaData['kelas'],
      jenisPembayaran: jenis, totalHarusBayar: harusBayar, totalSudahBayar: sudahBayar,
      sisaKekurangan: sisa > 0 ? sisa : 0, keteranganStatus: status, warnaStatus: warna,
      riwayatTransaksi: riwayatTransaksi, daftarTunggakanBulan: [],
    );
  }

  Future<void> bayarTunggakan(
    // Kita butuh ID kelas (dokumen), bukan nama kelas
    String idSiswa,
    String jenisPembayaran,
    String idKelas,
    double sisaKekurangan, {
    String? bulan,
  }) async {
    final nominalController = TextEditingController();
    
    // Ambil data kewajiban SPP per bulan dari master data
    if (jenisPembayaran == 'SPP') {
      final masterSiswaDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(idSiswa).get();
      final masterData = masterSiswaDoc.data();
      if (masterData == null) {
        Get.snackbar("Gagal", "Data master siswa tidak ditemukan.");
        return;
      }
      // Mengatasi inkonsistensi nama field
      double nominalSpp = (masterData['SPP'] as num?)?.toDouble() ?? (masterData['spp'] as num?)?.toDouble() ?? 0.0;
      if (nominalSpp <= 0) {
        Get.snackbar("Gagal", "Nominal SPP siswa ini belum diatur di data master.");
        return;
      }
      nominalController.text = nominalSpp.toStringAsFixed(0);
    } else {
      // Untuk pembayaran lain, nominal yang diisi adalah sisa kekurangannya
      nominalController.text = sisaKekurangan.toStringAsFixed(0);
    }
    
    Get.defaultDialog(
      title: "Input Pembayaran",
      content: Column(
        children: [
          Text("Bayar $jenisPembayaran ${bulan != null ? 'untuk bulan $bulan' : ''}?"),
          const SizedBox(height: 16),
          TextField(
            controller: nominalController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Nominal",
              prefixText: "Rp ",
              border: OutlineInputBorder(),
            ),
            // SPP tidak bisa diubah nominalnya, pembayaran lain bisa
            readOnly: jenisPembayaran == 'SPP',
          ),
        ],
      ),
      textConfirm: "Ya, Simpan",
      textCancel: "Batal",
      onConfirm: () async {
        double? nominalBayar = double.tryParse(nominalController.text);
        if (nominalBayar == null || nominalBayar <= 0) {
          Get.snackbar("Peringatan", "Nominal tidak valid.");
          return;
        }
        
        Get.back(); // Tutup dialog konfirmasi
        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false); // Tampilkan loading
        
        try {

          final String namaPetugas = await _getNamaPetugas();

          // Path untuk menyimpan data, menggunakan idTahunAjaran yang sudah kita punya
          final collectionRef = firestore
              .collection('Sekolah').doc(idSekolah)
              .collection('tahunajaran').doc(_idTahunAjaran)
              .collection('kelastahunajaran').doc(idKelas)
              .collection('daftarsiswa').doc(idSiswa)
              .collection(jenisPembayaran == 'SPP' ? 'SPP' : 'PembayaranLain');

          // Menyiapkan data untuk disimpan
          Map<String, dynamic> dataToSave = {
            'tglbayar': Timestamp.now(),
            // 'petugas': FirebaseAuth.instance.currentUser?.email ?? 'admin',
            'petugas': namaPetugas,
            'nominal': nominalBayar,
          };
          
          String docId;
          if (jenisPembayaran == 'SPP') {
            if (bulan == null) throw Exception("Bulan SPP tidak boleh kosong");
            docId = bulan;
            dataToSave['status'] = 'Lunas'; // Field spesifik SPP
          } else {
            docId = DateTime.now().millisecondsSinceEpoch.toString();
            dataToSave['jenis'] = jenisPembayaran; // Field spesifik PembayaranLain
            dataToSave['keterangan'] = "Pembayaran via rekap rinci";
          }

          await collectionRef.doc(docId).set(dataToSave);
          
          Get.back(); // Tutup loading
          Get.snackbar("Sukses", "Pembayaran berhasil disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
          fetchRincianPembayaran(); // Muat ulang data untuk merefresh UI
        } catch (e) {
          Get.back(); // Tutup loading jika error
          Get.snackbar("Error", "Gagal menyimpan pembayaran: $e");
        }
      },
    );
  }

  // --- Fungsi lain tidak perlu banyak perubahan ---
  List<PembayaranSiswaSummary> getFilteredSummaries(String jenis) {
    List<PembayaranSiswaSummary> summaries = allSummaries[jenis] ?? [];
    if (selectedKelas.value != 'Semua Kelas') {
      summaries = summaries.where((s) => s.kelas == selectedKelas.value).toList();
    }
    if (searchTerm.value.isNotEmpty) {
      summaries = summaries.where((s) => s.namaSiswa.toLowerCase().contains(searchTerm.value.toLowerCase())).toList();
    }
    summaries.sort((a, b) {
      if (a.sisaKekurangan > 0 && b.sisaKekurangan <= 0) return -1;
      if (a.sisaKekurangan <= 0 && b.sisaKekurangan > 0) return 1;
      return a.namaSiswa.compareTo(b.namaSiswa);
    });
    return summaries;
  }
  
  int _hitungBulanWajibSpp() {
    final now = DateTime.now();
    if (now.month >= 7) return now.month - 6;
    return now.month + 6;
  }
  
  List<String> getListBulan() => ['Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni'];
  String formatRupiah(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  String formatTanggal(DateTime date) => DateFormat('d MMM yyyy', 'id_ID').format(date);
}