// lib/app/modules/pantau_tahfidz/controllers/pantau_tahfidz_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../home/controllers/home_controller.dart';
import '../../kelas_tahfidz/controllers/kelas_tahfidz_controller.dart'; // Pinjam beberapa fungsi

class PantauTahfidzController extends GetxController {
  final HomeController homeC = Get.find<HomeController>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final RxString idKelas = ''.obs;
  final RxString namaKelas = ''.obs;
  final RxString namaWaliKelas = ''.obs;
  final RxMap<String, List<String>> delegasiSiswa = <String, List<String>>{}.obs;

  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> kelasTerpilih = Rxn<Map<String, dynamic>>();
  
  // State untuk data kelas yang dipilih
  final RxList<Map<String, dynamic>> daftarSiswa = <Map<String, dynamic>>[].obs;
  final RxMap<String, String> daftarPendamping = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchDaftarKelas();
  }

  Future<void> _fetchDaftarKelas() async {
    isLoading.value = true;
    final snapshot = await firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelastahunajaran').orderBy('namakelas').get();
    daftarKelas.assignAll(snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
    isLoading.value = false;
  }

  void pilihKelas(Map<String, dynamic> kelas) async {
    kelasTerpilih.value = kelas;
    isLoading.value = true;
    
    final kelasId = kelas['id'];
    final semesterId = homeC.semesterAktifId.value;

    daftarPendamping.clear();
    if (kelas.containsKey('tahfidz_info')) {
      daftarPendamping.assignAll(Map<String, String>.from(kelas['tahfidz_info']['pendamping'] ?? {}));
    }

    final siswaSnapshot = await firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelastahunajaran').doc(kelasId)
        .collection('semester').doc(semesterId)
        .collection('daftarsiswa').get();
    daftarSiswa.assignAll(siswaSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
    
    isLoading.value = false;
  }
  
  Stream<QuerySnapshot<Map<String, dynamic>>> getCatatanTahfidzStream(String nisn) {
    if (kelasTerpilih.value == null) return const Stream.empty();
    return firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelastahunajaran').doc(kelasTerpilih.value!['id'])
        .collection('semester').doc(homeC.semesterAktifId.value)
        .collection('daftarsiswa').doc(nisn)
        .collection('catatan_tahfidz').orderBy('tanggal_penilaian', descending: true).snapshots();
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

  // Kita pinjam dan adaptasi fungsi cetak dari KelasTahfidzController
  // (Jika proyek semakin besar, ini bisa diekstrak ke service terpisah)
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