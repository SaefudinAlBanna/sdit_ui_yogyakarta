// lib/app/modules/jurnal_ajar_harian/views/jurnal_ajar_harian_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/jurnal_ajar_harian_controller.dart';

class JurnalAjarHarianView extends GetView<JurnalAjarHarianController> {
  const JurnalAjarHarianView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dasbor Jurnal Harian'),
        actions: [
          // Tambahkan tombol Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadTugasHarian(),
          ),
        ],
      ),
      // Tombol aksi massal akan muncul di bawah saat ada item terpilih
      bottomNavigationBar: Obx(() => controller.tugasTerpilih.isNotEmpty
          ? _buildAksiMassalBottomBar(context)
          : const SizedBox.shrink()),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarTugasHariIni.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text("Tidak ada tugas mengajar untuk Anda hari ini.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: controller.daftarTugasHariIni.length,
          itemBuilder: (context, index) {
            final tugas = controller.daftarTugasHariIni[index];
            return _buildTugasCard(tugas);
          },
        );
      }),
    );
  }

  Widget _buildAksiMassalBottomBar(BuildContext context) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.library_books),
          label: Obx(() => Text("Isi Jurnal untuk ${controller.tugasTerpilih.length} Tugas Terpilih")),
          onPressed: () => controller.openJurnalDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTugasCard(JadwalTugasItem tugas) {
    final theme = Get.theme;
    Color cardColor = Colors.white;
    IconData statusIcon = Icons.hourglass_empty;
    String statusText = "Belum Diisi";

    switch (tugas.status) {
      case StatusTugas.SudahDiisi:
        cardColor = Colors.green.shade50;
        statusIcon = Icons.check_circle;
        statusText = "Sudah Diisi";
        break;
      case StatusTugas.TugasPengganti:
        cardColor = Colors.amber.shade50;
        statusIcon = Icons.people_alt;
        statusText = "Tugas Pengganti";
        break;
      default:
        break;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (tugas.status == StatusTugas.BelumDiisi || tugas.status == StatusTugas.TugasPengganti)
                  Obx(() => Checkbox(
                    value: controller.tugasTerpilih.contains(tugas),
                    onChanged: (val) => controller.toggleTugasSelection(tugas),
                  )),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${tugas.idKelas} - ${tugas.jam}", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(tugas.namaMapel, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => controller.openJurnalDialog(targetTugas: [tugas]),
                  child: Text(tugas.status == StatusTugas.SudahDiisi ? "Edit" : "Isi"),
                ),
              ],
            ),
            if (tugas.status == StatusTugas.SudahDiisi) ...[
              const Divider(height: 16),
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Materi: ", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: tugas.materiDiisi ?? '-'),
              ])),
              if (tugas.catatanDiisi != null && tugas.catatanDiisi!.isNotEmpty)
                Text.rich(TextSpan(children: [
                  const TextSpan(text: "Catatan: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: tugas.catatanDiisi!),
                ])),
            ],
            const Divider(height: 16),
            Row(
              children: [
                Icon(statusIcon, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(statusText, style: theme.textTheme.bodySmall),
                const Spacer(),
                Text("Guru: ${tugas.listNamaGuruAsli.join(', ')}", style: theme.textTheme.bodySmall),
              ],
            )
          ],
        ),
      ),
    );
  }
}



// // lib/app/modules/jurnal_ajar_harian/views/jurnal_ajar_harian_view.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// import '../../../routes/app_pages.dart';
// import '../controllers/jurnal_ajar_harian_controller.dart';

// class JurnalAjarHarianView extends GetView<JurnalAjarHarianController> {
//   const JurnalAjarHarianView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Input Jurnal Harian'),
//         backgroundColor: theme.colorScheme.primary,
//         foregroundColor: theme.colorScheme.onPrimary,
//         actions: [
//           if(controller.homeController.isAdminKepsek || controller.homeController.kapten || controller.homeController.isDalang)
//           IconButton(onPressed: ()=>Get.toNamed(Routes.MANAJEMEN_JAM), icon: Icon(Icons.access_time_outlined))
//         ],
//       ),
//       // Gunakan floatingActionButton untuk tombol simpan agar selalu terlihat
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       floatingActionButton: _buildSimpanButton(theme),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildTanggalHariIni(theme),
//             const SizedBox(height: 24),
    
//             // --- BAGIAN FORM UMUM ---
//             _buildSectionHeader(theme, "1. Isi Detail Umum"),
//             _buildJurnalForm(theme), // Ini sekarang hanya berisi Mapel & Materi
//             const SizedBox(height: 24),
    
//             // --- BAGIAN BARU: PEMILIHAN KELAS & JADWAL ---
//             _buildSectionHeader(theme, "2. Atur Jadwal & Catatan per Kelas"),
//             _buildKelasDanJadwalList(), // Widget baru kita
//             const SizedBox(height: 32),

//             // --- BAGIAN RIWAYAT (TETAP SAMA) ---
//             const Divider(thickness: 1),
//             const SizedBox(height: 16),
//             Text(
//               "Jurnal Tercatat Hari Ini",
//               style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             _buildRiwayatJurnalHariIni(theme),
//           ],
//         ),
//       ),
//     );
//   }

//   //========================================================================
//   // --- WIDGET-WIDGET BARU UNTUK UI DINAMIS ---
//   //========================================================================

//   /// Widget untuk form input (mapel, materi, catatan).
//   Widget _buildJurnalForm(ThemeData theme) {
//     return Column(
//       children: [
//         const SizedBox(height: 16),
        
//         // GetBuilder ini penting! Ia akan memaksa dropdown untuk
//         // membangun ulang item-nya setiap kali pilihan kelas berubah.
//         GetBuilder<JurnalAjarHarianController>(
//           id: 'mapel-dropdown', // ID harus cocok dengan yang di controller
//           builder: (_) {
//             return Obx(() => DropdownSearch<String>(
//               onChanged: controller.onMapelChanged,
//               items: (f, cs) => controller.getDataMapel(),
//               popupProps: _popupProps(theme, "Cari Mata Pelajaran"),
//               decoratorProps: _dropdownDecorator(theme, 'Pilih Mata Pelajaran', Icons.book_outlined),
//               enabled: controller.daftarKelasUntukJurnal.any((item) => item.isSelected.value),
//               selectedItem: controller.selectedMapel.value,
//             ));
//           }
//         ),
//         const SizedBox(height: 16),
//         TextField(
//           controller: controller.materimapelC,
//           decoration: _inputDecorator(theme, 'Materi yang Diajarkan (Umum)', Icons.subject_outlined),
//           textCapitalization: TextCapitalization.sentences,
//           minLines: 2, maxLines: 4,
//         ),
//       ],
//     );
//   }

  

//   /// Widget untuk tombol simpan yang reaktif.
//   Widget _buildSimpanButton(ThemeData theme) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//       child: Obx(() => ElevatedButton.icon(
//         icon: controller.isSaving.value
//             ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
//             : const Icon(Icons.save_as_outlined),
//         label: Text(controller.isSaving.value ? "Menyimpan..." : "Simpan Jurnal"),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: theme.colorScheme.primary,
//           foregroundColor: theme.colorScheme.onPrimary,
//           minimumSize: const Size(double.infinity, 50), // Tombol lebar penuh
//           textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         onPressed: controller.isSaving.value ? null : controller.simpanJurnal,
//       )),
//     );
//   }

//   //========================================================================
//   // --- WIDGET-WIDGET LAMA YANG MASIH DIGUNAKAN (HELPER) ---
//   //========================================================================
  
//   // Widget _buildDaftarJamPelajaran dan _showInputJurnalBottomSheet sudah tidak diperlukan lagi.

//   Widget _buildTanggalHariIni(ThemeData theme) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.calendar_today_outlined, size: 22, color: theme.colorScheme.onPrimaryContainer),
//           const SizedBox(width: 10),
//           Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionHeader(ThemeData theme, String title) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
//       child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
//     );
//   }
  
//   Widget _buildRiwayatJurnalHariIni(ThemeData theme) {
//     return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//       stream: controller.getJurnalHariIni(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())); }
//         if (snapshot.hasError) { return _buildErrorWidget(theme, "Gagal memuat riwayat jurnal. ${snapshot.error}"); }
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { return _buildEmptyStateWidget(theme, "Belum ada jurnal yang Anda input hari ini."); }

//         return ListView.separated(
//           physics: const NeverScrollableScrollPhysics(),
//           shrinkWrap: true,
//           itemCount: snapshot.data!.docs.length,
//           separatorBuilder: (_, __) => const SizedBox(height: 12),
//           itemBuilder: (context, index) {
//             Map<String, dynamic> data = snapshot.data!.docs[index].data();
//             DateTime tanggalInput = (data['tanggalinput'] as String?) != null ? DateTime.parse(data['tanggalinput'] as String) : DateTime.now();

//             return Card(
//               elevation: 1.5,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(data['jampelajaran'] ?? 'Jam Pelajaran', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
//                         Text(DateFormat('HH:mm', 'id_ID').format(tanggalInput), style: theme.textTheme.bodySmall),
//                       ],
//                     ),
//                     const Divider(height: 16),
//                     _buildRichTextInfo("Kelas", data['kelas'] ?? '-'),
//                     const SizedBox(height: 6),
//                     _buildRichTextInfo("Mapel", data['namamapel'] ?? '-'),
//                     const SizedBox(height: 6),
//                     _buildRichTextInfo("Materi", data['materipelajaran'] ?? '-'),
//                     if (data['catatanjurnal'] != null && (data['catatanjurnal'] as String).isNotEmpty) ...[
//                       const SizedBox(height: 6),
//                       _buildRichTextInfo("Catatan", data['catatanjurnal'], isItalic: true),
//                     ]
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildRichTextInfo(String label, String value, {bool isItalic = false}) {
//     final theme = Get.theme;
//     return Text.rich(TextSpan(children: [
//       TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
//       TextSpan(text: value, style: TextStyle(fontStyle: isItalic ? FontStyle.italic : FontStyle.normal, color: theme.textTheme.bodySmall?.color)),
//     ]), style: theme.textTheme.bodyMedium);
//   }

//   Widget _buildEmptyStateWidget(ThemeData theme, String message) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
//         child: Column(
//           children: [
//             Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget(ThemeData theme, String message) {
//      return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
//         child: Column(
//           children: [
//             Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
//             const SizedBox(height: 16),
//             Text("Terjadi Kesalahan", style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error)),
//             const SizedBox(height: 8),
//             Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
//           ],
//         ),
//       ),
//     );
//   }

//   InputDecoration _inputDecorator(ThemeData theme, String label, IconData icon) {
//      return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, size: 22),
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       filled: true,
//       fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
//     );
//   }

//   DropDownDecoratorProps _dropdownDecorator(ThemeData theme, String label, IconData icon) {
//     return DropDownDecoratorProps(
//       decoration: _inputDecorator(theme, label, icon).copyWith(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
//       ),
//     );
//   }

//   PopupProps<String> _popupProps(ThemeData theme, String searchHint) {
//     return PopupProps.menu(
//       showSearchBox: true,
//       searchFieldProps: TextFieldProps(decoration: _inputDecorator(theme, searchHint, Icons.search), style: theme.textTheme.bodyLarge),
//       menuProps: MenuProps(borderRadius: BorderRadius.circular(12)),
//       fit: FlexFit.loose,
//       containerBuilder: (ctx, popupWidget) { return Material(elevation: 8, borderRadius: BorderRadius.circular(12), child: popupWidget); },
//     );
//   }

//   // [BARU] Widget utama untuk daftar kelas yang interaktif
//   Widget _buildKelasDanJadwalList() {
//     return Obx(() {
//       if (controller.isLoading.value) {
//         return const Center(child: CircularProgressIndicator());
//       }
//       if (controller.daftarKelasUntukJurnal.isEmpty) {
//         return _buildEmptyStateWidget(Get.theme, "Anda tidak terdaftar mengajar di kelas manapun.");
//       }

//       return ListView.builder(
//         physics: const NeverScrollableScrollPhysics(),
//         shrinkWrap: true,
//         itemCount: controller.daftarKelasUntukJurnal.length,
//         itemBuilder: (context, index) {
//           final item = controller.daftarKelasUntukJurnal[index];
//           return _buildJurnalItemCard(item);
//         },
//       );
//     });
//   }

//   // [BARU] Widget untuk satu baris kartu interaktif
//   Widget _buildJurnalItemCard(JurnalKelasItem item) {
//     final theme = Get.theme;
//     // Kita pakai Obx lagi di level kartu agar hanya kartu ini yang di-rebuild saat state-nya berubah
//     return Obx(() => Card(
//       elevation: item.isSelected.value ? 4 : 1,
//       color: item.isSelected.value ? Colors.green.shade50 : Colors.white,
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 // Checkbox untuk memilih
//                 Checkbox(
//                   value: item.isSelected.value,
//                   onChanged: (val) {
//                     item.isSelected.value = val ?? false;
//                     // Reset pilihan mapel jika tidak ada kelas terpilih
//                     controller.update(['mapel-dropdown']);
//                   },
//                 ),
//                 Text(item.namaKelas, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
//                 const Spacer(),
//                 // Dropdown jam pelajaran
//                 SizedBox(
//                   width: 150,
//                   child: DropdownSearch<String>(
//                     enabled: item.isSelected.value,
//                     selectedItem: item.selectedJam.value,
//                     items: (f, cs) async {
//                       // Ini bisa dioptimalkan, tapi untuk sekarang kita fetch tiap kali
//                       final docs = await controller.getJamPelajaran();
//                       return docs.docs.map((d) => d.data()['jampelajaran']?.toString() ?? d.id).toList();
//                     },
//                     onChanged: (jam) => item.selectedJam.value = jam,
//                     decoratorProps: DropDownDecoratorProps(
//                       baseStyle: theme.textTheme.bodySmall,
//                       // [FIX] Buat InputDecoration baru di sini
//                       decoration: InputDecoration(
//                         labelText: "Pilih Jam",
//                         prefixIcon: const Icon(Icons.schedule, size: 22),
//                         isDense: true,
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                     ),
//                     popupProps: _popupProps(theme, "Cari Jam"),
//                   ),
//                 ),
//               ],
//             ),
//             // Kolom catatan hanya muncul jika dicentang
//             if (item.isSelected.value) ...[
//               const SizedBox(height: 12),
//               TextField(
//                 controller: item.catatanController,
//                 decoration: _inputDecorator(theme, "Catatan Khusus untuk Kelas ${item.namaKelas}", Icons.notes).copyWith(
//                   isDense: true,
//                 ),
//                 style: theme.textTheme.bodyMedium,
//                 maxLines: 2,
//               )
//             ]
//           ],
//         ),
//       ),
//     ));
//   }
// }
