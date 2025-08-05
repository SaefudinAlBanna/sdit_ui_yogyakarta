// File: lib/app/services/rapor_pdf_service.dart

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/rapor_terpadu_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Impor model-model yang kita butuhkan untuk data
import 'package:sdit_ui_yogyakarta/app/models/rapor_siswa_model.dart'; // <-- Butuh ini untuk RaporMapelModel

class RaporPdfService {
  
  static Future<void> generateAndPrintPdf(RaporTerpaduModel dataRapor) async {
    final pdfBytes = await _buildPdf(dataRapor);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  // File: lib/app/services/rapor_pdf_service.dart

  static Future<Uint8List> _buildPdf(RaporTerpaduModel dataRapor) async {
    final pdf = pw.Document();

    final font = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    final baseStyle = pw.TextStyle(font: ttf, fontSize: 10);
    final boldStyle = pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // --- BAGIAN 1: HEADER ---
            _buildHeaderSiswaPdf(dataRapor, baseStyle, boldStyle),
            pw.SizedBox(height: 20),
            pw.Text(
              "LAPORAN HASIL BELAJAR", 
              textAlign: pw.TextAlign.center, 
              style: boldStyle.copyWith(fontSize: 14, decoration: pw.TextDecoration.underline)
            ),
            pw.SizedBox(height: 20),

            // --- BAGIAN 2: TABEL AKADEMIK ---
            pw.Text("A. Capaian Kompetensi", style: boldStyle),
            pw.SizedBox(height: 8),
            _buildTabelAkademikPdf(dataRapor, baseStyle, boldStyle), // Kirim semua data rapor
            
            // --- BAGIAN 3: TABEL EKSKUL ---
            pw.SizedBox(height: 20),
            pw.Text("B. Kegiatan Ekstrakurikuler", style: boldStyle),
            pw.SizedBox(height: 8),
            _buildTabelEkskulPdf(dataRapor.dataEkskul, baseStyle, boldStyle),
            
            // --- BAGIAN 4: ABSENSI & CATATAN ---
            // Gunakan pw.NewPage() untuk memastikan bagian ini tidak terpotong jika memungkinkan
            pw.NewPage(),
            pw.SizedBox(height: 20),
            _buildAbsensiDanCatatanPdf(dataRapor, baseStyle, boldStyle),

            // --- BAGIAN 5: AREA TANDA TANGAN ---
            pw.Spacer(), // Dorong ke bagian bawah halaman
            _buildAreaTandaTanganPdf(dataRapor, baseStyle, boldStyle),

          ];
        },
        footer: (context) {
          return _buildFooterPdf(context, dataRapor, baseStyle);
        }
      ),
    );

    return pdf.save();
  }

  /// [BARU] Membangun tabel untuk ekstrakurikuler
  static pw.Widget _buildTabelEkskulPdf(List<RaporEkskulItem> dataEkskul, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    if (dataEkskul.isEmpty) {
      return pw.Text("Tidak mengikuti kegiatan ekstrakurikuler semester ini.", style: baseStyle);
    }
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.IntrinsicColumnWidth(),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(4),
      },
      children: [
        _buildTableHeader(['No', 'Kegiatan Ekstrakurikuler', 'Predikat', 'Keterangan'], boldStyle),
        ...dataEkskul.asMap().entries.map((entry) {
          int index = entry.key;
          var ekskul = entry.value;
          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((index + 1).toString(), textAlign: pw.TextAlign.center, style: baseStyle)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(ekskul.namaEkskul, style: baseStyle)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(ekskul.predikat ?? '-', textAlign: pw.TextAlign.center, style: baseStyle)),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(ekskul.keterangan ?? '-', style: baseStyle)),
            ]
          );
        })
      ],
    );
  }

  /// [BARU] Menggabungkan Absensi dan Catatan Wali Kelas
  static pw.Widget _buildAbsensiDanCatatanPdf(RaporTerpaduModel data, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Kolom Absensi
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("C. Ketidakhadiran", style: boldStyle),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Sakit", style: baseStyle)), pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("${data.dataAbsensi.sakitCount} hari", style: baseStyle))]),
                  pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Izin", style: baseStyle)), pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("${data.dataAbsensi.izinCount} hari", style: baseStyle))]),
                  pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Tanpa Keterangan", style: baseStyle)), pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("${data.dataAbsensi.alfaCount} hari", style: baseStyle))]),
                ]
              )
            ]
          )
        ),
        pw.SizedBox(width: 20),
        // Kolom Catatan Wali Kelas
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("D. Catatan Wali Kelas", style: boldStyle),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Text(data.catatanWaliKelas, style: baseStyle, textAlign: pw.TextAlign.justify),
              )
            ]
          )
        ),
      ]
    );
  }

  // [BARU] Membangun area tanda tangan
  static pw.Widget _buildAreaTandaTanganPdf(RaporTerpaduModel data, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    // Ambil nama dari data, bukan hardcode
    String namaWaliKelas = data.namaWaliKelas;
    String namaKepsek = data.namaKepalaSekolah;

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // TTD Orang Tua
            pw.Column(
              children: [
                pw.Text("Mengetahui", style: baseStyle),
                pw.Text("Orang Tua/Wali,", style: baseStyle),
                pw.SizedBox(height: 60),
                pw.Container(width: 120, height: 1, color: PdfColors.black),
              ]
            ),
            // TTD Wali Kelas
            pw.Column(
              children: [
                pw.Text("Sleman, ${DateFormat('d MMMM y', 'id_ID').format(DateTime.now())}", style: baseStyle),
                pw.Text("Wali Kelas,", style: baseStyle),
                pw.SizedBox(height: 60),
                pw.Text(namaWaliKelas, style: boldStyle.copyWith(decoration: pw.TextDecoration.underline)),
                // pw.Text("NUPTK. XXXXXXXXX", style: baseStyle), // Bisa ditambahkan jika ada datanya
              ]
            ),
          ]
        ),
        pw.SizedBox(height: 40),
        // TTD Kepala Sekolah (di tengah)
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text("Mengetahui", style: baseStyle),
              pw.Text("Kepala Sekolah,", style: baseStyle),
              pw.SizedBox(height: 60),
              pw.Text(namaKepsek, style: boldStyle.copyWith(decoration: pw.TextDecoration.underline)),
              // pw.Text("NUPTK. XXXXXXXXX", style: baseStyle),
            ]
          ),
        ),
      ]
    );
  }

  // --- WIDGET BUILDER UNTUK PDF ---

  /// [BARU] Membangun bagian header informasi siswa
  static pw.Widget _buildHeaderSiswaPdf(RaporTerpaduModel data, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderRow("Nama", data.dataSiswa.nama, baseStyle, boldStyle),
            _buildHeaderRow("NIS/NISN", data.dataSiswa.nisn, baseStyle, boldStyle),
            _buildHeaderRow("Nama Sekolah", "SD IT UKHUWAH ISLAMIYAH", baseStyle, boldStyle),
            // _buildHeaderRow("Nama Sekolah", "PKBM SDTQ Telaga Ilmu", baseStyle, boldStyle),
            _buildHeaderRow("Alamat", "Jl. Candi Sambisari...", baseStyle, boldStyle), // Ganti dengan data asli jika ada
            // _buildHeaderRow("Alamat", "Jl. Sawo Wireokerten...", baseStyle, boldStyle), // Ganti dengan data asli jika ada
          ]
        ),
        pw.SizedBox(width: 40),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderRow("Kelas", data.dataSiswa.namaKelas, baseStyle, boldStyle),
            _buildHeaderRow("Fase", "A", baseStyle, boldStyle), // Ganti dengan data asli jika ada
            _buildHeaderRow("Semester", data.semester, baseStyle, boldStyle),
            _buildHeaderRow("Tahun Pelajaran", data.tahunAjaran, baseStyle, boldStyle),
          ]
        ),
      ]
    );
  }

  /// [BARU] Helper untuk baris di header
  static pw.Widget _buildHeaderRow(String label, String value, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: baseStyle)),
          pw.Text(": ", style: baseStyle),
          pw.Text(value, style: boldStyle),
        ]
      ),
    );
  }

  /// [BARU] Membangun tabel untuk nilai akademik
  static pw.Widget _buildTabelAkademikPdf(RaporTerpaduModel dataRapor, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    final dataAkademik = dataRapor.dataAkademik;
    final dataHalaqoh = dataRapor.dataHalaqoh;

    // Kelompokkan mapel (ini bisa dibuat lebih dinamis nanti)
    final kelompokA = dataAkademik.where((m) => ['Pendidikan Agama Islam dan Budi Pekerti', 'Pendidikan Pancasila', 'Bahasa Indonesia', 'Matematika', 'Seni Rupa', 'Bahasa Inggris', 'Muatan Lokal Bahasa Daerah'].contains(m.namaMapel)).toList();
    final kelompokB = dataAkademik.where((m) => ['Pendidikan Jasmani, Olahraga, dan Kesehatan', 'Bahasa Arab', 'Bina Pribadi Islam', 'Baca Tulis Al-Quran'].contains(m.namaMapel)).toList();

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.IntrinsicColumnWidth(), // No
        1: const pw.FlexColumnWidth(2.5),  // Mapel
        2: const pw.IntrinsicColumnWidth(), // Nilai Akhir
        3: const pw.FlexColumnWidth(4),    // Capaian
      },
      children: [
        _buildTableHeader(['No', 'Mata Pelajaran', 'Nilai Akhir', 'Capaian Kompetensi'], boldStyle),
        
        // Data Kelompok A
        _buildTableSubHeader("Kelompok A", baseStyle),
        ...kelompokA.asMap().entries.map((entry) => _buildMapelTableRow(entry.key + 1, entry.value, baseStyle)),
        
        // Data Kelompok B
        _buildTableSubHeader("Kelompok B", baseStyle),
        ...kelompokB.asMap().entries.map((entry) => _buildMapelTableRow(entry.key + 1, entry.value, baseStyle)),
        
        // Data Kelompok C (Halaqoh)
        _buildTableSubHeader("Kelompok C", baseStyle),
        ...dataHalaqoh.asMap().entries.map((entry) {
          int index = entry.key;
          var halaqoh = entry.value;
          // Adaptasi data halaqoh agar bisa masuk ke _buildMapelTableRow
          final mapelHalaqoh = RaporMapelModel(
            namaMapel: halaqoh.jenis, // "Tahsin" atau "Tahfidz"
            guruPengajar: '', // Bisa ditambahkan jika ada datanya
            nilaiAkhir: halaqoh.nilaiAkhir?.toDouble(),
            deskripsiCapaian: halaqoh.keterangan,
            daftarCapaian: [],
          );
          return _buildMapelTableRow(index + 1, mapelHalaqoh, baseStyle);
        })
      ],
    );
  }

  /// [BARU] Helper untuk header tabel
  static pw.TableRow _buildTableHeader(List<String> headers, pw.TextStyle style) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: headers.map((h) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(h, style: style, textAlign: pw.TextAlign.center),
      )).toList(),
    );
  }

  /// [BARU] Helper untuk sub-header kelompok
  static pw.TableRow _buildTableSubHeader(String title, pw.TextStyle style) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(title, style: style.copyWith(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(), // Sel kosong
        pw.Container(), // Sel kosong
        pw.Container(), // Sel kosong
      ]
    );
  }
  
  /// [BARU] Helper untuk satu baris data mapel
  static pw.TableRow _buildMapelTableRow(int index, RaporMapelModel mapel, pw.TextStyle style) {
    String capaianText = "Capaian belum diisi.";
    if (mapel.deskripsiCapaian != null && mapel.deskripsiCapaian!.isNotEmpty) {
      capaianText = mapel.deskripsiCapaian!;
    } else if (mapel.daftarCapaian.isNotEmpty) {
      capaianText = mapel.daftarCapaian.map((e) => e.namaUnit).join('. ');
    }

    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(index.toString(), textAlign: pw.TextAlign.center, style: style)),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(mapel.namaMapel, style: style)),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(mapel.nilaiAkhir?.toStringAsFixed(0) ?? '-', textAlign: pw.TextAlign.center, style: style)),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(capaianText, style: style)),
      ]
    );
  }

  /// [BARU] Membangun footer halaman
  static pw.Widget _buildFooterPdf(pw.Context context, RaporTerpaduModel data, pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text("${data.dataSiswa.namaKelas} | ${data.dataSiswa.nama} | ${data.dataSiswa.nisn}", style: style.copyWith(color: PdfColors.grey)),
        pw.Text("Halaman ${context.pageNumber} dari ${context.pagesCount}", style: style.copyWith(color: PdfColors.grey)),
      ]
    );
  }
}