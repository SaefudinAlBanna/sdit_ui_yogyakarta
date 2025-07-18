// app/modules/perangkat_ajar/controllers/prota_prosem_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart'; // Import untuk CircularProgressIndicator
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../../models/atp_model.dart';
import '../../perangkat_ajar/controllers/perangkat_ajar_controller.dart';
import '../../../services/pdf_export_service.dart';

class ProtaProsemController extends GetxController {
  late final Rx<AtpModel> atp;
  final PerangkatAjarController _perangkatAjarController = Get.find();

  final List<String> bulanSemester1 = ["Juli", "Agustus", "September", "Oktober", "November", "Desember"];
  final List<String> bulanSemester2 = ["Januari", "Februari", "Maret", "April", "Mei", "Juni"];

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is AtpModel) {
      atp = (Get.arguments as AtpModel).obs;
    } else {
      Get.back();
      Get.snackbar("Error", "Tidak ada data ATP yang dipilih.");
    }
  }

  Future<void> jadwalkanUnit({
    required String idUnit,
    required int semester,
    required String bulan,
  }) async {
    int unitIndex = atp.value.unitPembelajaran.indexWhere((unit) => unit.idUnit == idUnit);
    
    if (unitIndex != -1) {
      atp.value.unitPembelajaran[unitIndex].semester = semester;
      atp.value.unitPembelajaran[unitIndex].bulan = bulan;
      await _perangkatAjarController.updateAtp(atp.value);
      atp.refresh();
      Get.snackbar("Berhasil", "${atp.value.unitPembelajaran[unitIndex].lingkupMateri} berhasil dijadwalkan.");
    } else {
      Get.snackbar("Error", "Gagal menemukan unit untuk dijadwalkan.");
    }
  }

  Future<void> batalkanJadwalUnit({required String idUnit}) async {
    int unitIndex = atp.value.unitPembelajaran.indexWhere((unit) => unit.idUnit == idUnit);

    if (unitIndex != -1) {
      atp.value.unitPembelajaran[unitIndex].semester = null;
      atp.value.unitPembelajaran[unitIndex].bulan = null;
      await _perangkatAjarController.updateAtp(atp.value);
      atp.refresh();
      Get.snackbar("Berhasil", "Jadwal untuk '${atp.value.unitPembelajaran[unitIndex].lingkupMateri}' telah dibatalkan.");
    } else {
      Get.snackbar("Error", "Gagal menemukan unit untuk dibatalkan.");
    }
  }
  
  // --- PERBAIKAN DI FUNGSI INI ---
  Future<void> cetakProtaProsem() async {
    Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    try {
      final pdfService = PdfExportService();
      
      // Ambil nama sekolah dari HomeController secara asynchronous
      final userSnapshot = await _perangkatAjarController.homeC.userStream().first;
      // Di dalam dokumen user (pegawai), Anda menyimpan nama sekolah di field `namasekolah`
      // Anda bisa cek kembali di struktur Firestore Anda.
      // Jika tidak ada di dokumen user, kita ambil dari data sekolah langsung.
      final namaSekolah = userSnapshot.data()?['namasekolah'] ?? "SDIT Ukhuwah Islamiyah"; // Fallback
      
      final pdfData = await pdfService.generateProtaProsemPdf(atp.value, namaSekolah);
      
      // Tutup dialog loading SEBELUM menampilkan print preview
      if (Get.isDialogOpen ?? false) Get.back();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: 'PROTA_PROSEM_${atp.value.namaMapel}_${atp.value.idTahunAjaran}.pdf',
      );

    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", "Gagal membuat PDF: ${e.toString()}");
    }
  }
  // --- AKHIR PERBAIKAN ---
}