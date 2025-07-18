// app/modules/perangkat_ajar/prota_prosem_view.dart
import 'package:collection/collection.dart'; // Tambahkan import ini
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/atp_model.dart';
import '../controllers/prota_prosem_controller.dart';

class ProtaProsemView extends GetView<ProtaProsemController> {
  const ProtaProsemView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Prota & Prosem"),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.print_outlined),
            //   onPressed: () {
            //     Get.snackbar("Info", "Fitur Cetak PDF akan segera hadir!");
            //   },
            //   tooltip: "Cetak ke PDF",
            // ),
            IconButton(
              icon: Icon(Icons.print_outlined),
              onPressed: () => controller.cetakProtaProsem(), // Panggil fungsi controller
              tooltip: "Cetak ke PDF",
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Program Semester 1"),
              Tab(text: "Program Semester 2"),
              Tab(text: "Program Tahunan (Rekap)"),
            ],
          ),
        ),
        // Bungkus body dengan Obx untuk mereaksi perubahan pada controller.atp
        body: Obx(() => TabBarView(
          children: [
            _buildSemesterView(semester: 1),
            _buildSemesterView(semester: 2),
            _buildProtaView(),
          ],
        )),
      ),
    );
  }

  // Widget untuk tampilan per semester (SEKARANG DINAMIS)
  Widget _buildSemesterView({required int semester}) {
    // Filter unit pembelajaran berdasarkan semester
    final scheduledUnits = controller.atp.value.unitPembelajaran
        .where((unit) => unit.semester == semester)
        .toList();
    
    // Filter unit yang belum terjadwal sama sekali
    final unscheduledUnits = controller.atp.value.unitPembelajaran
        .where((unit) => unit.semester == null || unit.semester == 0)
        .toList();
        
    // Kelompokkan unit yang sudah terjadwal berdasarkan bulan
    final groupedByMonth = groupBy(scheduledUnits, (UnitPembelajaran unit) => unit.bulan!);

    // Dapatkan daftar bulan yang sudah diisi
    List<String> monthsInOrder = (semester == 1) 
      ? controller.bulanSemester1 
      : controller.bulanSemester2;
      
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUnscheduledCard(unscheduledUnits),
          SizedBox(height: 24),
          
          // Render kartu bulan secara dinamis
          ...monthsInOrder.map((bulan) {
            // Ambil daftar item untuk bulan ini, atau list kosong jika tidak ada
            final itemsForMonth = groupedByMonth[bulan] ?? [];
            return _buildMonthCard(
              bulan: bulan,
              items: itemsForMonth,
            );
          }).toList(),
        ],
      ),
    );
  }

  // Kartu untuk materi belum terjadwal (SEKARANG INTERAKTIF)
  Card _buildUnscheduledCard(List<UnitPembelajaran> units) {
    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Materi Belum Terjadwal", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            if (units.isEmpty)
              Text("Semua materi sudah terjadwal. Hebat!", style: TextStyle(color: Colors.grey.shade700))
            else
              ...units.map((unit) => ListTile(
                dense: true,
                leading: Icon(Icons.topic_outlined, size: 20),
                title: Text(unit.lingkupMateri),
                trailing: ElevatedButton(
                  onPressed: () => _showSchedulingDialog(unit), // Panggil dialog penjadwalan
                  child: Text("Jadwalkan"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  // Kartu untuk setiap bulan (SEKARANG DINAMIS)
 Card _buildMonthCard({required String bulan, required List<UnitPembelajaran> items}) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bulan, style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Divider(height: 24),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("Belum ada materi dijadwalkan untuk bulan ini.", style: TextStyle(color: Colors.grey)),
              )
            else
              // Ubah dari Text sederhana menjadi ListTile agar ada tombol di kanan
              ...items.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                title: Text("${item.lingkupMateri} (${item.alokasiWaktu})", style: Get.textTheme.bodyLarge),
                // Tombol Batal Jadwal
                trailing: IconButton(
                  icon: Icon(Icons.undo_rounded, color: Colors.orange.shade800),
                  tooltip: "Batal Jadwal",
                  onPressed: () {
                    // Tampilkan dialog konfirmasi sebelum membatalkan
                    Get.defaultDialog(
                      title: "Konfirmasi",
                      middleText: "Anda yakin ingin membatalkan jadwal untuk materi '${item.lingkupMateri}'?",
                      confirm: TextButton(
                        onPressed: () {
                          Get.back(); // Tutup dialog
                          controller.batalkanJadwalUnit(idUnit: item.idUnit);
                        },
                        child: Text("Ya, Batalkan", style: TextStyle(color: Colors.red)),
                      ),
                      cancel: TextButton(
                        onPressed: () => Get.back(),
                        child: Text("Tidak"),
                      ),
                    );
                  },
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }
  
  // Widget Prota tidak perlu perubahan besar, karena hanya membaca
  Widget _buildProtaView() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text("Rekapitulasi Program Tahunan", style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        SizedBox(height: 24),
        DataTable(
          columnSpacing: 20,
          border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          columns: [
            DataColumn(label: Text("Semester", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Unit Pembelajaran / Materi Pokok", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Alokasi Waktu", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          // --- PERBAIKAN DI SINI ---
          rows: controller.atp.value.unitPembelajaran.map((unit) => DataRow(
            cells: [
              DataCell(Text(unit.semester?.toString() ?? "-")), // Tampilkan semester jika ada
              DataCell(Text(unit.lingkupMateri)),
              DataCell(Text(unit.alokasiWaktu)),
            ]
          )).toList(),
          // --- AKHIR PERBAIKAN ---
        )
      ],
    );
  }

  // --- DIALOG BARU UNTUK PENJADWALAN ---
  void _showSchedulingDialog(UnitPembelajaran unit) {
    final RxInt selectedSemester = 1.obs;
    final RxString selectedMonth = ''.obs;

    Get.defaultDialog(
      title: "Jadwalkan Materi",
      titleStyle: TextStyle(fontWeight: FontWeight.bold),
      content: Obx(() => Column(
        children: [
          Text("Pilih jadwal untuk:\n'${unit.lingkupMateri}'", textAlign: TextAlign.center),
          SizedBox(height: 20),
          // Dropdown Semester
          DropdownButtonFormField<int>(
            value: selectedSemester.value,
            decoration: InputDecoration(labelText: "Semester", border: OutlineInputBorder()),
            items: [
              DropdownMenuItem(child: Text("Semester 1"), value: 1),
              DropdownMenuItem(child: Text("Semester 2"), value: 2),
            ],
            onChanged: (value) {
              if (value != null) {
                selectedSemester.value = value;
                selectedMonth.value = ''; // Reset pilihan bulan
              }
            },
          ),
          SizedBox(height: 12),
          // Dropdown Bulan
          DropdownButtonFormField<String>(
            hint: Text("Pilih Bulan"),
            value: selectedMonth.value.isEmpty ? null : selectedMonth.value,
            decoration: InputDecoration(labelText: "Bulan", border: OutlineInputBorder()),
            items: (selectedSemester.value == 1 ? controller.bulanSemester1 : controller.bulanSemester2)
                .map((bulan) => DropdownMenuItem(child: Text(bulan), value: bulan))
                .toList(),
            onChanged: (value) {
              if (value != null) selectedMonth.value = value;
            },
          ),
        ],
      )),
      confirm: Obx(() => ElevatedButton(
        onPressed: selectedMonth.value.isEmpty ? null : () {
          // Panggil fungsi controller untuk menyimpan
          controller.jadwalkanUnit(
            idUnit: unit.idUnit, 
            semester: selectedSemester.value, 
            bulan: selectedMonth.value
          );
          Get.back(); // Tutup dialog
        },
        child: Text("Simpan Jadwal"),
      )),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text("Batal"),
      ),
    );
  }
}










