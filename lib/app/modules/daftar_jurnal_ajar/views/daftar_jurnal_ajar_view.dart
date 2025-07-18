// lib/app/modules/daftar_jurnal_ajar/views/daftar_jurnal_ajar_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/daftar_jurnal_model.dart'; // Sesuaikan path
import '../controllers/daftar_jurnal_ajar_controller.dart';

class DaftarJurnalAjarView extends GetView<DaftarJurnalAjarController> {
  const DaftarJurnalAjarView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Jurnal Ajar'),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Filter Data Jurnal", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFilterSection(context, theme),
            const SizedBox(height: 16),
            _buildExportButtons(), // Tombol Export Baru
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.daftarJurnal.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return _buildJurnalList(theme);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButtons() {
    return Obx(() {
      if (controller.isExporting.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: controller.exportToPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Export PDF"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            onPressed: controller.exportToExcel,
            icon: const Icon(Icons.table_chart),
            label: const Text("Export Excel"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
          ),
        ],
      );
    });
  }

 Widget _buildFilterSection(BuildContext context, ThemeData theme) {
  return Obx(() => Column(
    children: [
      // Pilihan Mode: Harian / Bulanan
      SegmentedButton<FilterMode>(
        segments: const [
          ButtonSegment(value: FilterMode.Harian, label: Text('Harian'), icon: Icon(Icons.today)),
          ButtonSegment(value: FilterMode.Bulanan, label: Text('Bulanan'), icon: Icon(Icons.calendar_month)),
        ],
        selected: {controller.filterMode.value},
        onSelectionChanged: (Set<FilterMode> newSelection) {
          controller.changeFilterMode(newSelection.first);
        },
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          // Filter Tanggal
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => controller.changeDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Obx(() => Text(
                          DateFormat('dd MMM yyyy', 'id_ID').format(controller.selectedDate.value),
                          style: theme.textTheme.titleSmall,
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter Kelas
          Expanded(
            flex: 3,
            child: Obx(() => DropdownButtonFormField<KelasModel>(
                  value: controller.selectedKelas.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.class_outlined, color: theme.primaryColor, size: 20),
                    labelText: 'Pilih Kelas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('Semua Kelas'),
                  items: controller.daftarKelas.map((kelas) {
                    return DropdownMenuItem<KelasModel>(
                      value: kelas,
                      child: Text(kelas.nama, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: controller.changeKelas,
                )),
          ),
        ],
      ),
    ],
  ));
}

  Widget _buildJurnalList(ThemeData theme) {
    return ListView.separated(
      itemCount: controller.daftarJurnal.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final JurnalModel jurnal = controller.daftarJurnal[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(jurnal.jamPelajaran, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                    Text(jurnal.kelas, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 16),
                _buildInfoRow("Mapel", jurnal.namaMapel),
                const SizedBox(height: 6),
                _buildInfoRow("Guru", jurnal.namaGuru),
                const SizedBox(height: 6),
                _buildInfoRow("Materi", jurnal.materi),
                if (jurnal.catatan != null && jurnal.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow("Catatan", jurnal.catatan!, isItalic: true),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isItalic = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70, // Lebar tetap untuk label
          child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontStyle: isItalic ? FontStyle.italic : FontStyle.normal),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Jurnal Tidak Ditemukan",
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Tidak ada data jurnal untuk tanggal atau kelas yang dipilih.",
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}