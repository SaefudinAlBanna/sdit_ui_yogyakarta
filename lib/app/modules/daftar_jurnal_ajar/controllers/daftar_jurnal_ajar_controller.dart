// lib/app/modules/daftar_jurnal_ajar/controllers/daftar_jurnal_ajar_controller.dart


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:open_file_plus/open_file_plus.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import '../../../models/daftar_jurnal_model.dart'; // Sesuaikan path jika perlu

// Enum untuk mode filter
enum FilterMode { Harian, Bulanan }

class DaftarJurnalAjarController extends GetxController {
  // --- STATE MANAGEMENT ---
  var isLoading = true.obs;
  var isExporting = false.obs; // State untuk proses export
  var selectedDate = DateTime.now().obs;
  // Rxn<T> digunakan untuk tipe data yang bisa null.
  

  // Daftar untuk menampung data dari Firestore
  var daftarKelas = <KelasModel>[].obs;
  var daftarJurnal = <JurnalModel>[].obs;

  // State untuk filter
  var filterMode = FilterMode.Harian.obs;
  var startDate = DateTime.now().obs;
  var endDate = DateTime.now().obs;
  var selectedKelas = Rxn<KelasModel>();

  // --- FIREBASE INSTANCES ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String idSekolah = '20404148';

  @override
  void onInit() {
    super.onInit();
    // Saat controller pertama kali dimuat, langsung ambil data
    fetchDaftarKelas();
    fetchDaftarJurnal();
  }

  // --- DATA FETCHING METHODS ---

  /// Mengambil daftar semua kelas untuk ditampilkan di dropdown.
  Future<void> fetchDaftarKelas() async {
    try {
      final snapshot = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('kelas')
          .get();

      // Ubah dokumen menjadi List<KelasModel>
      daftarKelas.value = snapshot.docs
          .map((doc) => KelasModel.fromFirestore(doc))
          .toList();
      // Urutkan berdasarkan nama
      daftarKelas.sort((a, b) => a.nama.compareTo(b.nama));
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil daftar kelas: ${e.toString()}");
    }
  }

  /// Mengambil daftar jurnal berdasarkan filter tanggal dan kelas yang dipilih.
   Future<void> fetchDaftarJurnal() async {
    isLoading.value = true;
    try {
      // PENTING: Kita sekarang query ke koleksi 'jurnal_flat'
      Query<Map<String, dynamic>> query = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('jurnal_flat');

      // Terapkan filter rentang tanggal
      // Pastikan endDate mencakup keseluruhan hari terakhir
      final endOfDay = DateTime(endDate.value.year, endDate.value.month, endDate.value.day, 23, 59, 59);
      query = query
          .where('timestamp', isGreaterThanOrEqualTo: startDate.value)
          .where('timestamp', isLessThanOrEqualTo: endOfDay);

      // Terapkan filter kelas jika dipilih
      if (selectedKelas.value != null) {
        query = query.where('kelas', isEqualTo: selectedKelas.value!.id);
      }
      
      // Urutkan berdasarkan waktu, lalu jam pelajaran
      // PENTING: Ini akan memerlukan INDEKS KOMPOSIT di Firestore!
      query = query.orderBy('timestamp').orderBy('jampelajaran');

      final snapshot = await query.get();

      daftarJurnal.value = snapshot.docs
          .map((doc) => JurnalModel.fromFirestore(doc))
          .toList();
          
    } catch (e) {
      daftarJurnal.clear();
      print("Error fetchDaftarJurnal: $e");
      Get.snackbar("Error", "Gagal memuat data. Pastikan indeks Firestore sudah dibuat.");
    } finally {
      isLoading.value = false;
    }
  }

  // --- UI EVENT HANDLERS ---

  void changeFilterMode(FilterMode mode) {
    filterMode.value = mode;
    // Sesuaikan tanggal saat mode berubah
    if (mode == FilterMode.Harian) {
      startDate.value = DateTime.now();
      endDate.value = DateTime.now();
    } else { // Bulanan
      final now = DateTime.now();
      startDate.value = DateTime(now.year, now.month, 1);
      endDate.value = DateTime(now.year, now.month + 1, 0); // Hari terakhir di bulan ini
    }
    fetchDaftarJurnal();
  }

  void pickDateRange(BuildContext context) async {
    if (filterMode.value == FilterMode.Harian) {
      final picked = await showDatePicker(context: context, initialDate: startDate.value, firstDate: DateTime(2020), lastDate: DateTime(2050));
      if (picked != null) {
        startDate.value = picked;
        endDate.value = picked;
        fetchDaftarJurnal();
      }
    } else { // Bulanan
      final picked = await showDateRangePicker(context: context, initialDateRange: DateTimeRange(start: startDate.value, end: endDate.value), firstDate: DateTime(2020), lastDate: DateTime(2050));
      if (picked != null) {
        startDate.value = picked.start;
        endDate.value = picked.end;
        fetchDaftarJurnal();
      }
    }
  }

  /// Dipanggil saat pengguna memilih tanggal baru dari date picker.
  void changeDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );

    if (pickedDate != null && pickedDate != selectedDate.value) {
      selectedDate.value = pickedDate;
      fetchDaftarJurnal(); // Ambil ulang data dengan tanggal baru
    }
  }

  /// Dipanggil saat pengguna memilih kelas baru dari dropdown.
  void changeKelas(KelasModel? kelas) {
    selectedKelas.value = kelas;
    fetchDaftarJurnal(); // Ambil ulang data dengan filter kelas baru
  }

  // --- EXPORT FUNCTIONS ---

  Future<void> exportToPdf() async {
    if (daftarJurnal.isEmpty) {
      Get.snackbar("Gagal", "Tidak ada data untuk diekspor.");
      return;
    }
    isExporting.value = true;
    try {
      final pdf = pw.Document();

      // Buat halaman PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildPdfHeader(),
          build: (context) => [
            _buildPdfTable(daftarJurnal),
          ],
        ),
      );

      // Simpan file
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/laporan_jurnal.pdf");
      await file.writeAsBytes(await pdf.save());

      // Buka file
      // await OpenFile.open(file.path);

    } catch (e) {
      Get.snackbar("Error", "Gagal membuat PDF: $e");
    } finally {
      isExporting.value = false;
    }
  }
  
  Future<void> exportToExcel() async {
    if (daftarJurnal.isEmpty) {
      Get.snackbar("Gagal", "Tidak ada data untuk diekspor.");
      return;
    }
    isExporting.value = true;
    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel[excel.getDefaultSheet()!];

      // Header
      final headers = ["Tanggal", "Jam", "Kelas", "Mapel", "Guru", "Materi", "Catatan"];
      sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
      
      // Data
      for (final jurnal in daftarJurnal) {
        final tanggal = jurnal.id.split('-').reversed.join('-'); // Asumsi id format d-M-y
        final row = [
            TextCellValue(tanggal),
            TextCellValue(jurnal.jamPelajaran),
            TextCellValue(jurnal.kelas),
            TextCellValue(jurnal.namaMapel),
            TextCellValue(jurnal.namaGuru),
            TextCellValue(jurnal.materi),
            TextCellValue(jurnal.catatan ?? ""),
        ];
        sheet.appendRow(row);
      }

      // Simpan file
      final output = await getTemporaryDirectory();
      final fileBytes = excel.save();
      final file = File("${output.path}/laporan_jurnal.xlsx")
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      // Buka file
      // await OpenFile.open(file.path);

    } catch (e) {
      Get.snackbar("Error", "Gagal membuat Excel: $e");
    } finally {
      isExporting.value = false;
    }
  }

  // Helper untuk PDF
  pw.Widget _buildPdfHeader() {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Laporan Jurnal Ajar Harian", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.SizedBox(height: 5),
          pw.Text("Periode: ${DateFormat('dd MMM yyyy').format(startDate.value)} - ${DateFormat('dd MMM yyyy').format(endDate.value)}"),
          pw.Text("Kelas: ${selectedKelas.value?.nama ?? 'Semua Kelas'}"),
        ],
      ),
    );
  }

  pw.Table _buildPdfTable(List<JurnalModel> data) {
    final headers = ["Jam", "Kelas", "Mapel", "Guru", "Materi"];
    return pw.Table.fromTextArray(
      headers: headers,
      data: data.map((jurnal) => [
        jurnal.jamPelajaran,
        jurnal.kelas,
        jurnal.namaMapel,
        jurnal.namaGuru,
        jurnal.materi,
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
      },
      border: pw.TableBorder.all(),
    );
  }
}
