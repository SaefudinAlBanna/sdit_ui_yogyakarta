// app/services/pdf_export_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sdit_ui_yogyakarta/app/models/atp_model.dart'; // Sesuaikan path jika perlu

class PdfExportService {

  // Fungsi utama yang akan kita panggil
  Future<Uint8List> generateProtaProsemPdf(AtpModel atp, String namaSekolah) async {
    final pdf = pw.Document();

    // Data untuk tabel
    final headers = ['No', 'Materi Pokok / Unit', 'Semester', 'Alokasi Waktu'];
    final data = atp.unitPembelajaran.map((unit) {
      String semesterText;
      if (unit.semester == 1) {
        semesterText = "Ganjil";
      } else if (unit.semester == 2) {
        semesterText = "Genap";
      } else {
        semesterText = "-"; // Jika belum dijadwalkan
      }
      return [
        (atp.unitPembelajaran.indexOf(unit) + 1).toString(),
        unit.lingkupMateri,
        semesterText,
        unit.alokasiWaktu,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Dokumen
            _buildHeader(context, atp, namaSekolah),
            pw.SizedBox(height: 20),
            
            // Judul Tabel
            pw.Text(
              "Program Tahunan (PROTA)",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 15),

            // Tabel Data
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey),
            ),
          );
        }
      ),
    );

    // Simpan PDF dan kembalikan sebagai data bytes
    return pdf.save();
  }

  // Helper untuk membuat header informasi
  static pw.Widget _buildHeader(pw.Context context, AtpModel atp, String namaSekolah) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(namaSekolah, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.Divider(height: 8),
        pw.SizedBox(height: 10),
        pw.Table(
          columnWidths: {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(0.1),
            2: pw.FlexColumnWidth(2),
          },
          border: pw.TableBorder.all(style: pw.BorderStyle.none),
          children: [
            _buildTableRow("Mata Pelajaran", atp.namaMapel),
            _buildTableRow("Penyusun", atp.namaPenyusun),
            _buildTableRow("Fase / Kelas", "${atp.fase} / ${atp.kelas}"),
            _buildTableRow("Tahun Pelajaran", atp.idTahunAjaran.replaceAll('-', '/')),
          ]
        )
      ]
    );
  }
  
  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(":"),
        pw.Text(value),
      ]
    );
  }
}