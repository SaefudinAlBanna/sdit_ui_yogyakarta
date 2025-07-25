import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Import semua model yang kita butuhkan
import '../../../models/rapor_siswa_model.dart';
import '../../../models/atp_model.dart';
import '../../home/controllers/home_controller.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RaporSiswaController extends GetxController {
  
  // --- DEPENDENSI & DATA DASAR ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  
  // Data siswa & sesi yang didapat dari argumen dan HomeController
  late String idSiswa, namaSiswa, idKelas;
  late String idTahunAjaran, semesterAktif;

  // --- STATE MANAGEMENT UNTUK UI ---
  final RxBool isLoading = true.obs;
  // Ini akan menyimpan data rapor yang sudah siap ditampilkan
  final RxList<RaporMapelModel> raporData = <RaporMapelModel>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // 1. Ambil data penting dari argumen navigasi
    final Map<String, dynamic>? args = Get.arguments;
    if (args == null) {
      // Handle error jika tidak ada argumen
      Get.snackbar("Error", "Data siswa tidak ditemukan.");
      isLoading.value = false;
      return;
    }
    
    idSiswa = args['idSiswa'] ?? '';
    namaSiswa = args['namaSiswa'] ?? '';
    idKelas = args['idKelas'] ?? '';

    // 2. Ambil data sesi dari HomeController
    idTahunAjaran = homeC.idTahunAjaran.value!;
    semesterAktif = homeC.semesterAktifId.value;
    
    // 3. Mulai proses pengambilan data rapor
    loadRaporData();
  }

  Future<void> exportRaporToPdf() async {
  final pdf = pw.Document();

  // --- PERUBAHAN UTAMA DIMULAI DI SINI ---

  // 1. Muat FONT TEKS (NotoSans)
  final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
  final notoSans = pw.Font.ttf(fontData);

  // 2. Muat FONT EMOJI (NotoColorEmoji)
  final emojiFontData = await rootBundle.load("assets/fonts/NotoColorEmoji-Regular.ttf");
  final notoEmoji = pw.Font.ttf(emojiFontData);

  // 3. Buat Tema dengan FONT FALLBACK
  // Ini memberitahu PDF: "Coba gambar pakai notoSans, kalau gagal, coba pakai notoEmoji"
  final theme = pw.ThemeData.withFont(
    base: notoSans,
    fontFallback: [notoEmoji], // <-- INI ADALAH KUNCI UTAMANYA
  );

  // --- AKHIR PERUBAHAN UTAMA ---

  pdf.addPage(
    pw.MultiPage(
      theme: theme, // Terapkan tema canggih kita
      pageFormat: PdfPageFormat.a4,
      build: (context) {
          final List<RaporMapelModel> data = raporData;
          return [
            // Header
            pw.Header(
              level: 0,
            child: pw.Text("Rapor Belajar Siswa - ${namaSiswa}", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text("Kelas: $idKelas | Semester: $semesterAktif | Tahun Ajaran: $idTahunAjaran"),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          // Loop untuk setiap mata pelajaran
          ...data.map((mapel) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(mapel.namaMapel, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text("Nilai Akhir: ${mapel.nilaiAkhir?.toStringAsFixed(1) ?? '-'}", style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 10),

                // Loop untuk setiap Unit Capaian (Bab)
                ...mapel.daftarCapaian.map((unit) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(5)
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(unit.namaUnit, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Divider(height: 5),
                        pw.SizedBox(height: 5),
                        // TP Tercapai
                        if(unit.tpTercapai.isNotEmpty)
                          ...unit.tpTercapai.map((tp) => pw.Text("✅ ${tp}")),
                        // TP Perlu Bimbingan
                        if(unit.tpPerluBimbingan.isNotEmpty)
                          ...unit.tpPerluBimbingan.map((tp) => pw.Text("⚠️ ${tp}")),
                      ]
                    )
                  );
                }),
                pw.SizedBox(height: 20),
              ]
            );
          }).toList(),
        ];
      },
    ),
  );

  // 3. Tampilkan layar untuk print/share
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

  /// Fungsi utama yang menjadi sutradara pengambilan data rapor.
  Future<void> loadRaporData() async {
    try {
      isLoading.value = true;
      
      // --- LANGKAH 1: Ambil semua mata pelajaran yang diikuti siswa ---
      final mapelSnapshot = await firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('semester').doc(semesterAktif)
          .collection('daftarsiswa').doc(idSiswa)
          .collection('matapelajaran').get();

      if (mapelSnapshot.docs.isEmpty) {
        // Handle jika siswa belum punya data mapel sama sekali
        isLoading.value = false;
        return;
      }

      List<RaporMapelModel> tempDataRapor = [];

      // --- LANGKAH 2: Proses setiap mata pelajaran satu per satu ---
      for (var mapelDoc in mapelSnapshot.docs) {
        final namaMapel = mapelDoc.id;
        final dataMapelSiswa = mapelDoc.data();
        
        // --- LANGKAH 2A: Ambil ATP yang sesuai untuk mapel ini ---
        final atpModel = await _findAtpForMapel(namaMapel);
        
        // --- LANGKAH 2B: Ambil nama guru pengajar ---
        final namaGuru = await _findGuruPengajar(namaMapel);

        // --- LANGKAH 2C: Susun data capaian berdasarkan struktur ATP ---
        List<UnitCapaian> daftarUnitCapaian = [];
        if (atpModel != null) {
          final capaianSiswa = Map<String, String>.from(dataMapelSiswa['capaian_tp'] ?? {});
          
          for (var unit in atpModel.unitPembelajaran) {
            List<String> tpTercapai = [];
            List<String> tpPerluBimbingan = [];

            for (var tp in unit.tujuanPembelajaran) {
              if (capaianSiswa[tp] == 'Tercapai') {
                tpTercapai.add(tp);
              } else if (capaianSiswa[tp] == 'Perlu Bimbingan') {
                tpPerluBimbingan.add(tp);
              }
            }
            
            // Hanya tambahkan Unit ke rapor jika ada isinya
            if (tpTercapai.isNotEmpty || tpPerluBimbingan.isNotEmpty) {
              daftarUnitCapaian.add(UnitCapaian(
                namaUnit: unit.lingkupMateri, // Judul Bab
                tpTercapai: tpTercapai,
                tpPerluBimbingan: tpPerluBimbingan,
              ));
            }
          }
        }
        
        // --- LANGKAH 2D: Rakit semua data menjadi satu RaporMapelModel ---
        tempDataRapor.add(RaporMapelModel(
          namaMapel: namaMapel,
          guruPengajar: namaGuru,
          nilaiAkhir: dataMapelSiswa['nilai_akhir'],
          daftarCapaian: daftarUnitCapaian,
        ));
      }
      
      // --- LANGKAH 3: Tampilkan data ke UI ---
      raporData.assignAll(tempDataRapor);

    } catch (e) {
      Get.snackbar("Terjadi Kesalahan", "Gagal memuat data rapor: $e");
    } finally {
      isLoading.value = false;
    }
  }
  
  // --- Helper Function untuk mencari ATP ---
  Future<AtpModel?> _findAtpForMapel(String namaMapel) async {
    final kelasAngka = int.tryParse(idKelas.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    
    final snapshot = await firestore
        .collection('Sekolah').doc(homeC.idSekolah).collection('atp')
        .where('idTahunAjaran', isEqualTo: idTahunAjaran)
        .where('namaMapel', isEqualTo: namaMapel)
        .where('kelas', isEqualTo: kelasAngka)
        .limit(1).get();
        
    if (snapshot.docs.isNotEmpty) {
      return AtpModel.fromJson(snapshot.docs.first.data());
    }
    return null;
  }

  // --- Helper Function untuk mencari Guru Pengajar ---
  Future<String> _findGuruPengajar(String namaMapel) async {
    final doc = await firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('penugasan').doc(idKelas)
        .collection('matapelajaran').doc(namaMapel).get();
        
    if (doc.exists) {
      return doc.data()?['guru'] ?? 'N/A';
    }
    return 'N/A';
  }
}