import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../controllers/jurnal_ajar_harian_controller.dart';

class JurnalAjarHarianView extends GetView<JurnalAjarHarianController> {
  JurnalAjarHarianView({super.key});

  // final dataArgument = Get.arguments; // Tidak terpakai di view ini, bisa dihapus jika memang tidak

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('id_ID', null);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Jurnal Ajar Harian'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Expanded(
        child: SingleChildScrollView(
          child: Column(
            // padding: const EdgeInsets.all(16.0),
            children: [
              _buildTanggalHariIni(theme),
              const SizedBox(height: 20),
              Text(
                "Pilih Jam Pelajaran untuk Mengisi Jurnal:",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildDaftarJamPelajaran(context, theme),
              const SizedBox(height: 24),
              const Divider(thickness: 1),
              const SizedBox(height: 16),
              Text(
                "Jurnal yang Sudah Diinput Hari Ini:",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildRiwayatJurnalHariIni(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTanggalHariIni(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.withOpacity(0.3),
        //     spreadRadius: 1,
        //     blurRadius: 3,
        //     offset: const Offset(0, 2),
        //   )
        // ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 22, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Text(
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaftarJamPelajaran(BuildContext context, ThemeData theme) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: controller.tampilkanJamPelajaran(),
      builder: (context, snapPilihJurnal) {
        if (snapPilihJurnal.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapPilihJurnal.hasError) {
          return Center(child: Text("Error: ${snapPilihJurnal.error}", style: TextStyle(color: theme.colorScheme.error)));
        }
        if (!snapPilihJurnal.hasData || snapPilihJurnal.data!.docs.isEmpty) {
          return const Center(child: Text("Belum ada data jam pelajaran."));
        }

        // GridView lebih menarik untuk pilihan seperti ini
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 atau 3 kolom, sesuaikan
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 2.5, // Sesuaikan rasio aspek
          ),
          itemCount: snapPilihJurnal.data!.docs.length,
          itemBuilder: (context, index) {
            var dataJam = snapPilihJurnal.data!.docs[index].data();
            String jamPelajaran = dataJam['jampelajaran'] ?? 'Jam Ke-${index + 1}';

            return Card(
              elevation: 2.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: theme.colorScheme.surfaceVariant, // Warna card yang berbeda
              child: InkWell(
                onTap: () {
                  // Reset field controller sebelum bottom sheet dibuka
                  controller.kelasSiswaC.clear();
                  controller.mapelC.clear();
                  controller.materimapelC.clear();
                  controller.catatanjurnalC.clear();
                  _showInputJurnalBottomSheet(context, theme, jamPelajaran);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Padding di dalam card
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 28, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        jamPelajaran,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecorator(ThemeData theme, String label, {IconData? prefixIcon}) {
     return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: theme.colorScheme.onSurfaceVariant) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.dividerColor)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.7))
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)
      ),
      filled: true,
      fillColor: theme.colorScheme.surface.withOpacity(0.5), // Warna fill yang lebih lembut
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  void _showInputJurnalBottomSheet(BuildContext context, ThemeData theme, String jamPelajaranDipilih) {
    Get.bottomSheet(
      isScrollControlled: true, // Penting agar bisa scroll jika konten panjang
      backgroundColor: Colors.transparent, // Buat transparan agar bisa pakai Container dengan border radius
      Container(
        // height: MediaQuery.of(context).size.height * 0.75, // Tinggi maksimal
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85, // Batas tinggi maksimal
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor, // Warna background sheet
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView( // Bungkus dengan SingleChildScrollView
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Agar tinggi sesuai konten
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle sheet (garis di atas)
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Input Jurnal untuk: $jamPelajaranDipilih',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Dropdown Kelas
                DropdownSearch<String>(
                  decoratorProps: DropDownDecoratorProps(
                    decoration: _inputDecorator(theme, 'Pilih Kelas', prefixIcon: Icons.class_outlined),
                  ),
                  selectedItem: controller.kelasSiswaC.text.isEmpty ? null : controller.kelasSiswaC.text,
                  items: (f, cs) => controller.getDataKelas(),
                  onChanged: controller.onKelasChanged, // Panggil method controller
                  // onChanged: (String? value) {
                  //   if (value != null) {
                  //     controller.kelasSiswaC.text = value;
                  //     controller.mapelC.clear(); // Kosongkan mapel jika kelas berubah
                  //     // Anda mungkin perlu cara untuk me-refresh DropdownSearch Mapel
                  //   }
                  // },
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: _inputDecorator(theme, "Cari Kelas").copyWith(hintText: "Ketik nama kelas..."),
                    ),
                    menuProps: MenuProps(borderRadius: BorderRadius.circular(12)),
                    fit: FlexFit.loose,
                  ),
                  // validator: (value) => value == null || value.isEmpty ? "Kelas wajib diisi" : null, // Tambahkan validasi jika perlu
                ),
                const SizedBox(height: 16),

                // Dropdown Mata Pelajaran (perlu direbuild jika kelasSiswaC berubah)
                // Kita bisa bungkus dengan Obx atau GetBuilder untuk ini
                Obx(() => DropdownSearch<String>(
                      // key: ValueKey(controller.kelasSiswaC.text), // Ganti key saat kelas berubah untuk rebuild
                      key: ValueKey(controller.selectedKelasObs.value),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _inputDecorator(theme, 'Pilih Mata Pelajaran', prefixIcon: Icons.book_outlined)
                            .copyWith(
                              enabled: controller.selectedKelasObs.value.isNotEmpty, // Disable jika kelas belum dipilih
                            ),
                      ),
                      selectedItem: controller.mapelC.text.isEmpty ? null : controller.mapelC.text,
                      items: (f, cs) => controller.getDataMapel(),
                      // enabled: controller.kelasSiswaC.text.isNotEmpty, // Disable jika kelas belum dipilih
                      enabled: controller.selectedKelasObs.value.isNotEmpty,
                      onChanged: controller.onMapelChanged, // Panggil method controller
                      // onChanged: (String? value) {
                      //   if (value != null) {
                      //     controller.mapelC.text = value;
                      //   }
                      // },
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                         searchFieldProps: TextFieldProps(
                          decoration: _inputDecorator(theme, "Cari Mata Pelajaran").copyWith(hintText: "Ketik nama mapel..."),
                        ),
                        menuProps: MenuProps(borderRadius: BorderRadius.circular(12)),
                        fit: FlexFit.loose,
                      ),
                      // validator: (value) => value == null || value.isEmpty ? "Mapel wajib diisi" : null,
                    )),
                const SizedBox(height: 16),

                TextField(
                  controller: controller.materimapelC,
                  decoration: _inputDecorator(theme, 'Materi Pelajaran', prefixIcon: Icons.subject_outlined),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: controller.catatanjurnalC,
                  decoration: _inputDecorator(theme, 'Catatan Jurnal (Opsional)', prefixIcon: Icons.notes_outlined),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_outlined),
                  label: const Text("Simpan Jurnal"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (controller.kelasSiswaC.text.isEmpty) {
                      Get.snackbar("Peringatan", "Kelas wajib dipilih.", backgroundColor: Colors.orange[700], colorText: Colors.white);
                    } else if (controller.mapelC.text.isEmpty) {
                      Get.snackbar("Peringatan", "Mata pelajaran wajib dipilih.", backgroundColor: Colors.orange[700], colorText: Colors.white);
                    } else if (controller.materimapelC.text.trim().isEmpty) {
                      Get.snackbar("Peringatan", "Materi pelajaran wajib diisi.", backgroundColor: Colors.orange[700], colorText: Colors.white);
                    } else {
                      // Tampilkan dialog konfirmasi sebelum menyimpan
                      Get.defaultDialog(
                        title: "Konfirmasi Simpan",
                        middleText: "Apakah Anda yakin ingin menyimpan jurnal ini?",
                        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                        confirm: ElevatedButton(
                          onPressed: () {
                            Get.back(); // Tutup dialog konfirmasi
                            controller.simpanDataJurnal(jamPelajaranDipilih);
                            // Get.back() akan menutup bottom sheet setelah simpanDataJurnal selesai (karena ada Get.back() di sana)
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                          child: Text("Ya, Simpan", style: TextStyle(color: theme.colorScheme.onPrimary)),
                        ),
                        cancel: TextButton(
                          onPressed: () => Get.back(), // Tutup dialog konfirmasi
                          child: Text("Batal", style: TextStyle(color: theme.colorScheme.secondary)),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10), // Spasi di bawah tombol
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatJurnalHariIni(ThemeData theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: controller.tampilkanjurnal(),
      builder: (context, snapshotTampil) {
        if (snapshotTampil.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshotTampil.hasError) {
          return Center(child: Text("Error: ${snapshotTampil.error}", style: TextStyle(color: theme.colorScheme.error)));
        }
        if (!snapshotTampil.hasData || snapshotTampil.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text("Belum ada jurnal yang diinput hari ini.", style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: snapshotTampil.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            Map<String, dynamic> data = snapshotTampil.data!.docs[index].data();
            Timestamp? ts = data['tanggalinput'] is Timestamp ? data['tanggalinput'] as Timestamp : null;
            DateTime tanggalInput = ts?.toDate() ?? DateTime.now();

            return Card(
              elevation: 1.5,
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
                          DateFormat('HH:mm', 'id_ID').format(tanggalInput), // Hanya jam & menit
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
    );
  }
}

// ====================== KODE LAMA ====================

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';

// import 'package:get/get.dart';

// import '../controllers/jurnal_ajar_harian_controller.dart';

// class JurnalAjarHarianView extends GetView<JurnalAjarHarianController> {
//   JurnalAjarHarianView({super.key});

//   final dataArgument = Get.arguments;

//   @override
//   Widget build(BuildContext context) {
//     // print("dataArgument = $dataArgument");
//     return Scaffold(
//       appBar: AppBar(
//         // title: const Text('JurnalAjarHarianView'),
//         centerTitle: true,
//       ),
//       body: ListView(
//         children: [
//           Column(
//             children: [
//               FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                 future: controller.tampilkanJamPelajaran(),
//                 builder: (context, snapPilihJurnal) {
//                   return ListView.builder(
//                     physics: NeverScrollableScrollPhysics(),
//                     shrinkWrap: true,
//                     itemCount: snapPilihJurnal.data?.docs.length ?? 0,
//                     itemBuilder: (context, index) {
//                       if (snapPilihJurnal.connectionState ==
//                           ConnectionState.waiting) {
//                         return Center(child: CircularProgressIndicator());
//                       }
//                       if (snapPilihJurnal.hasData) {
//                         var data = snapPilihJurnal.data!.docs[index].data();
//                         // return ListTile(
//                         //   onTap: () {
//                         //     print("yang ke ${index + 1}");
//                         //   },
//                         //   title: Text(data['namamatapelajaran']),
//                         //   subtitle: Text(dataKelas),
//                         // );

//                         return Padding(
//                           padding: const EdgeInsets.only(top: 10),
//                           child: Material(
//                             color: Colors.grey[200],
//                             borderRadius: BorderRadius.circular(15),
//                             child: InkWell(
//                               onTap: () {
//                                 print(
//                                   "data['jampelajaran'] = ${data['jampelajaran']}",
//                                 );
//                                 Get.bottomSheet(
//                                   Container(
//                                     height: 400,
//                                     color: Colors.white,
//                                     child: Padding(
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 10,
//                                         horizontal: 10,
//                                       ),
//                                       child: Column(
//                                         children: [
//                                           Container(
//                                             height: 50,
//                                             decoration: BoxDecoration(
//                                               color: Colors.grey[50],
//                                               borderRadius:
//                                                   BorderRadius.circular(10),
//                                             ),
//                                             child: Text(
//                                               data['jampelajaran'],
//                                               style: TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ),

//                                           DropdownSearch<String>(
//                                             decoratorProps:
//                                                 DropDownDecoratorProps(
//                                                   decoration: InputDecoration(
//                                                     border:
//                                                         OutlineInputBorder(),
//                                                     filled: true,
//                                                     prefixText: 'kelas : ',
//                                                   ),
//                                                 ),
//                                             selectedItem:
//                                                 controller.kelasSiswaC.text,
//                                             items:
//                                                 (f, cs) =>
//                                                     controller.getDataKelas(),
//                                             onChanged: (String? value) {
//                                               controller.kelasSiswaC.text =
//                                                   value!;
//                                             },
//                                             popupProps: PopupProps.menu(
//                                               // disabledItemFn: (item) => item == '1A',
//                                               fit: FlexFit.tight,
//                                             ),
//                                           ),
//                                           SizedBox(height: 15),

//                                           DropdownSearch<String>(
//                                             decoratorProps:
//                                                 DropDownDecoratorProps(
//                                                   decoration: InputDecoration(
//                                                     border:
//                                                         OutlineInputBorder(),
//                                                     filled: true,
//                                                     prefixText: 'mapel : ',
//                                                   ),
//                                                 ),
//                                             selectedItem:
//                                                 controller.mapelC.text,
//                                             items:
//                                                 (f, cs) =>
//                                                     controller.getDataMapel(),
//                                             onChanged: (String? value) {
//                                               controller.mapelC.text = value!;
//                                             },
//                                             popupProps: PopupProps.menu(
//                                               // disabledItemFn: (item) => item == '1A',
//                                               fit: FlexFit.tight,
//                                             ),
//                                           ),
//                                           SizedBox(height: 15),

//                                           TextField(
//                                             controller: controller.materimapelC,
//                                             decoration: InputDecoration(
//                                               labelText: 'Materi Pelajaran',
//                                               labelStyle: TextStyle(
//                                                 fontSize: 12,
//                                               ),
//                                               border: OutlineInputBorder(),
//                                               enabledBorder: OutlineInputBorder(
//                                                 borderSide: BorderSide(
//                                                   color: Colors.grey,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(height: 15),

//                                           TextField(
//                                             controller:
//                                                 controller.catatanjurnalC,
//                                             decoration: InputDecoration(
//                                               labelText: 'Catatan',
//                                               labelStyle: TextStyle(
//                                                 fontSize: 12,
//                                               ),
//                                               border: OutlineInputBorder(),
//                                               enabledBorder: OutlineInputBorder(
//                                                 borderSide: BorderSide(
//                                                   color: Colors.grey,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(height: 15),

//                                           ElevatedButton(
//                                             onPressed: () {
//                                               // ignore: unnecessary_null_comparison
//                                               if (controller.kelasSiswaC.text ==
//                                                       null ||
//                                                   controller
//                                                       .kelasSiswaC
//                                                       .text
//                                                       .isEmpty) {
//                                                 Get.snackbar(
//                                                   "Error",
//                                                   "Kelas masih kosong",
//                                                 );
//                                               } else if (controller
//                                                           .mapelC
//                                                           // ignore: unnecessary_null_comparison
//                                                           .text ==
//                                                       null ||
//                                                   controller
//                                                       .mapelC
//                                                       .text
//                                                       .isEmpty) {
//                                                 Get.snackbar(
//                                                   "Error",
//                                                   "Mapel masih kosong",
//                                                 );
//                                               } else if (controller
//                                                           .materimapelC
//                                                           // ignore: unnecessary_null_comparison
//                                                           .text ==
//                                                       null ||
//                                                   controller
//                                                       .materimapelC
//                                                       .text
//                                                       .isEmpty) {
//                                                 Get.snackbar(
//                                                   "Error",
//                                                   "Materi Mapel masih kosong",
//                                                 );
//                                               } else {
//                                                 controller.simpanDataJurnal(
//                                                   data['jampelajaran'],
//                                                 );
//                                               }
//                                             },
//                                             child: Text("Simpan"),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                               child: Container(
//                                 margin: EdgeInsets.fromLTRB(20, 10, 10, 0),
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(15),
//                                 ),
//                                 child: Text(data['jampelajaran']),
//                               ),
//                             ),
//                           ),
//                         );
//                       }
//                       // Add a default return for other cases
//                       return Text(
//                         "Tidak bisa memuat data, silahkan ulangi lagi",
//                       );
//                     },
//                   );
//                 },
//               ),
//               SizedBox(height: 3),
//               Divider(height: 3),
//               // Container(height: 2, color: Colors.grey),

//               // ElevatedButton(onPressed: ()=>controller.refreshTampilan(), child: Text("test")),
//               StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                 stream: controller.tampilkanjurnal(),
//                 // stream: null,
//                 builder: (context, snapshotTampil) {
//                   if (snapshotTampil.connectionState ==
//                       ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   }
//                   // ignore: prefer_is_empty
//                   if (snapshotTampil.data == null ||
//                       snapshotTampil.data?.docs.length == 0) {
//                     return Center(child: Text('belum ada data'));
//                   }
//                   if (snapshotTampil.hasData) {
//                     return ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: snapshotTampil.data!.docs.length,
//                       itemBuilder: (context, index) {
//                         Map<String, dynamic> data =
//                             snapshotTampil.data!.docs[index].data() as Map<String, dynamic>;

//                         // Format tanggal Jurnal
//                         String formattedTglJurnal = '';
//                         if (data['tanggalinput'] != null) {
//                           // ignore: non_constant_identifier_names
//                           DateTime? TglJurnal;
//                           if (data['tanggalinput'] is Timestamp) {
//                             TglJurnal =
//                                 (data['tanggalinput'] as Timestamp).toDate();
//                           } else if (data['tanggalinput'] is String) {
//                             TglJurnal = DateTime.tryParse(data['tanggalinput']);
//                           }
//                           if (TglJurnal != null) {
//                             formattedTglJurnal =
//                                 "${TglJurnal.day.toString().padLeft(2, '0')}-${TglJurnal.month.toString().padLeft(2, '0')}-${TglJurnal.year}";
//                           }
//                         }

//                         // return ListTile(
//                         //   title: Text(data['namamapel']),
//                         //   subtitle: Text(data['jampelajaran']),
//                         // );
//                         return Container(
//                           margin: EdgeInsets.fromLTRB(20, 10, 10, 0),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Text("Tanggal Jurnal : ${data['uidtanggal']}"),
//                               Text("Tanggal : $formattedTglJurnal"),
//                               Text("Jam Pelajaran : ${data['jampelajaran']}"),
//                               Text("Mapel : ${data['namamapel']}"),
//                               Text("Materi : ${data['materipelajaran']}"),
//                               Text("Catatan : ${data['catatanjurnal']}"),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   }
//                   // Default return to satisfy non-nullable return type
//                   return SizedBox.shrink();
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

