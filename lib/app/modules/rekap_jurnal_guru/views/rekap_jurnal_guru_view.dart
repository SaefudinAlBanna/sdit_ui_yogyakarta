// lib/app/modules/rekap_jurnal_guru/views/rekap_jurnal_guru_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../controllers/rekap_jurnal_guru_controller.dart';

class RekapJurnalGuruView extends GetView<RekapJurnalGuruController> {
  const RekapJurnalGuruView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    initializeDateFormatting('id_ID', null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Jurnal Mengajar Saya'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.getRekapJurnalGuru(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- PERUBAHAN UTAMA ADA DI BLOK INI ---
          if (snapshot.hasError) {
            // Kita akan mencetak errornya ke konsol agar bisa disalin.
            final error = snapshot.error;
            debugPrint("==========================================================");
            debugPrint("FIRESTORE QUERY ERROR DITEMUKAN:");
            debugPrint("Tipe Error: ${error.runtimeType}");
            debugPrint("Pesan Error: ${error.toString()}");
            debugPrint("==========================================================");

            // Tampilkan pesan error yang informatif di UI
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange.shade800),
                    const SizedBox(height: 16),
                    const Text(
                      "Query Membutuhkan Index",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Buka 'Debug Console' Anda untuk menyalin link pembuatan index yang diperlukan oleh Firestore.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          // --- AKHIR DARI PERUBAHAN ---

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Anda belum pernah menginput jurnal."),
                ],
              ),
            );
          }

          var listJurnal = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: listJurnal.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              Map<String, dynamic> data = listJurnal[index].data();
              
              DateTime tanggalInput;
              final dynamic tanggalValue = data['tanggalinput'];

              if (tanggalValue is Timestamp) {
                tanggalInput = tanggalValue.toDate();
              } else if (tanggalValue is String) {
                tanggalInput = DateTime.tryParse(tanggalValue) ?? DateTime.now();
              } else {
                tanggalInput = DateTime.now();
              }

              String tanggalFormatted = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(tanggalInput);
              
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['jampelajaran'] ?? 'Jam Pelajaran',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                          Text(
                            tanggalFormatted,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: "Kelas: ", style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant)),
                        TextSpan(text: "${data['kelas'] ?? '-'}", style: TextStyle(color: theme.colorScheme.onSurface)),
                      ]), style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: "Mapel: ", style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant)),
                        TextSpan(text: "${data['namamapel'] ?? '-'}", style: TextStyle(color: theme.colorScheme.onSurface)),
                      ]), style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: "Materi: ", style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant)),
                        TextSpan(text: "${data['materipelajaran'] ?? '-'}", style: TextStyle(color: theme.colorScheme.onSurface)),
                      ]), style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis,),
                      if (data['catatanjurnal'] != null && (data['catatanjurnal'] as String).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text.rich(TextSpan(children: [
                          TextSpan(text: "Catatan: ", style: TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
                          TextSpan(text: "${data['catatanjurnal']}", style: TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface)),
                        ]), style: theme.textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis,),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}