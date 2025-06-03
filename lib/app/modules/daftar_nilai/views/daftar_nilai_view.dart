// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';

// import '../../../routes/app_pages.dart';
// import '../controllers/daftar_nilai_controller.dart';

// class DaftarNilaiView extends GetView<DaftarNilaiController> {
//   DaftarNilaiView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     print("DaftarNilaiView: build() method CALLED. Controller instance: ${controller.hashCode}");
//     initializeDateFormatting('id_ID', null);
//     final ThemeData theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Riwayat Nilai Halaqoh'),
//         backgroundColor: theme.colorScheme.primary,
//         foregroundColor: theme.colorScheme.onPrimary,
//         elevation: 2,
//       ),
//       body: Obx(() { // Obx sekarang utama untuk error message atau jika dataSiswaArgs kosong
//         print("DaftarNilaiView: Obx REBUILDING. isLoading (controller): ${controller.isLoading.value}, errorMessage: '${controller.errorMessage.value}', dataSiswaArgs.isEmpty: ${controller.dataSiswaArgs.isEmpty}");

//         // Handle Error Global dari controller (misal argumen tidak valid)
//         if (controller.errorMessage.value.isNotEmpty && !controller.isLoading.value) { // Hanya tampilkan jika tidak sedang loading juga
//           print("DaftarNilaiView - Obx: Displaying GLOBAL ERROR state. Message: ${controller.errorMessage.value}");
//           return _buildErrorStateWidget(theme, controller.errorMessage.value);
//         }

//         // Handle jika data argumen siswa kosong di awal
//         if (controller.dataSiswaArgs.isEmpty && !controller.isLoading.value) {
//            print("DaftarNilaiView - Obx: Displaying ERROR state (dataSiswaArgs is empty).");
//            return _buildErrorStateWidget(theme, "Data siswa tidak ditemukan untuk menampilkan riwayat nilai.");
//         }

//         // Jika tidak ada error global dan dataSiswaArgs ada, TAMPILKAN STREAMBUILDER
//         // StreamBuilder akan menangani loadingnya sendiri.
//         print("DaftarNilaiView - Obx: Proceeding to render Column with StreamBuilder.");
//         return Column(
//           children: [
//             // Tampilkan header siswa meskipun data nilai masih loading, karena data siswa sudah ada
//             if (controller.dataSiswaArgs.isNotEmpty)
//               _buildStudentHeader(theme, controller.dataSiswaArgs),
//             if (controller.dataSiswaArgs.isNotEmpty)
//               const Divider(height: 1, thickness: 1),
//             Expanded(
//               child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                 stream: controller.streamDataNilai(), // Ini akan memanggil fungsi di controller
//                 builder: (context, snapshot) {
//                   print("DaftarNilaiView - StreamBuilder BUILDER CALLED. ConnectionState: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, HasError: ${snapshot.hasError}, Error: ${snapshot.error}");

//                   // 1. Handle Loading dari Stream Firestore (termasuk loading awal saat Future dependensi berjalan)
//                   // Kita bisa menggunakan controller.isLoading.value ATAU snapshot.connectionState == ConnectionState.waiting
//                   // Menggunakan snapshot.connectionState lebih direct untuk state stream itu sendiri.
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                      print("DaftarNilaiView - StreamBuilder: State = WAITING. Displaying loading indicator.");
//                    return Center(
//                      child: Column(
//                        mainAxisAlignment: MainAxisAlignment.center,
//                        children: [
//                          CircularProgressIndicator(color: theme.colorScheme.primary),
//                          const SizedBox(height: 16),
//                          Text("Memuat riwayat nilai...", style: theme.textTheme.bodyMedium),
//                        ],
//                      ),

//                   // 2. Handle Error dari Stream Firestore
//                   if (snapshot.hasError) {
//                     print("DaftarNilaiView - StreamBuilder: State = HAS ERROR. Error: ${snapshot.error}");
//                     return _buildErrorStateWidget(theme, "Gagal memuat data nilai: ${snapshot.error.toString().replaceFirst("Exception: ", "")}");
//                   }

//                   // 3. Handle Tidak Ada Data atau Data Kosong (setelah stream aktif/selesai dan tidak ada error)
//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     print("DaftarNilaiView - StreamBuilder: State = NO DATA or EMPTY DOCS (and connection is ${snapshot.connectionState}).");
//                     return _buildEmptyStateWidget(theme);
//                   }

//                   // 4. Jika ada data, tampilkan ListView
//                   print("DaftarNilaiView - StreamBuilder: State = HAS DATA. Number of docs: ${snapshot.data!.docs.length}. Rendering ListView.");
//                   final nilaiDocs = snapshot.data!.docs;
//                   // Jika sampai sini, controller.isLoading.value seharusnya sudah false karena .map() di stream
//                   return ListView.separated(
//                     // ... (ListView.separated seperti sebelumnya)
//                      padding: const EdgeInsets.all(16.0),
//                     itemCount: nilaiDocs.length,
//                     separatorBuilder: (context, index) => const SizedBox(height: 12),
//                     itemBuilder: (context, index) {
//                       final dataNilai = nilaiDocs[index].data();
//                       final String docId = nilaiDocs[index].id;
//                       return _buildNilaiCard(context, theme, dataNilai, docId);
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }
//     );
//   }

//   // Mengganti nama menjadi _buildErrorStateWidget dan _buildEmptyStateWidget untuk konsistensi
//   Widget _buildStudentHeader(ThemeData theme, Map<String, dynamic> dataSiswa) {
//     String namaSiswa = dataSiswa['namasiswa'] ?? 'Siswa';
//     String kelasSiswa = dataSiswa['kelas'] ?? 'Kelas Tidak Diketahui';
//     String nisnSiswa = dataSiswa['nisn'] ?? '';

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 35,
//             backgroundColor: theme.colorScheme.secondaryContainer,
//             backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=${Uri.encodeComponent(namaSiswa)}&background=random&color=fff&size=128"),
//             child: Text(
//               namaSiswa.isNotEmpty ? namaSiswa[0].toUpperCase() : 'S',
//               style: TextStyle(fontSize: 30, color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   namaSiswa,
//                   style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Kelas: $kelasSiswa',
//                   style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
//                 ),
//                  if (nisnSiswa.isNotEmpty)
//                   Text(
//                     'NISN: $nisnSiswa',
//                     style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNilaiCard(BuildContext context, ThemeData theme, Map<String, dynamic> data, String docId) {
//     // Ambil timestamp dan konversi dengan aman
//     Timestamp? ts = data['tanggalinput'] is Timestamp ? data['tanggalinput'] as Timestamp : null;
//     DateTime tanggalInput = ts?.toDate() ?? DateTime.now(); // Fallback jika parsing gagal atau null

//     String nilaiAngka = data['nilai']?.toString() ?? '-';
//     String nilaiHuruf = data['nilaihuruf'] ?? '-';

//     return Card(
//       elevation: 2, // Sedikit kurangi elevation agar lebih subtle
//       margin: EdgeInsets.zero,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Border radius lebih kecil
//       color: theme.cardColor, // Gunakan theme.cardColor untuk konsistensi
//       child: InkWell(
//         onTap: () {
//           Get.toNamed(Routes.DETAIL_NILAI_HALAQOH, arguments: {...data, 'docId': docId});
//         },
//         borderRadius: BorderRadius.circular(10.0),
//         child: Padding(
//           padding: const EdgeInsets.all(12.0), // Kurangi padding sedikit
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Pengampu: Ust. ${data['namapengampu'] ?? 'N/A'}',
//                       style: theme.textTheme.titleSmall?.copyWith(
//                         fontWeight: FontWeight.w600, // Sedikit lebih tebal
//                         color: theme.colorScheme.primary, // Gunakan primary color
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                    Container( // Ganti Chip dengan Container untuk styling lebih bebas jika perlu
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                     decoration: BoxDecoration(
//                       color: theme.colorScheme.primaryContainer.withOpacity(0.6),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onPrimaryContainer),
//                         const SizedBox(width: 4),
//                         Text(
//                           DateFormat('dd MMM yy', 'id_ID').format(tanggalInput), // Format tanggal lebih pendek
//                           style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w500),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               Padding( // Tambahkan padding untuk Divider
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Divider(height: 1, thickness: 0.5, color: theme.dividerColor.withOpacity(0.5)),
//               ),
//               _buildInfoRow(theme, Icons.menu_book_outlined, 'Surat Hafalan', data['hafalansurat'] ?? '-'),
//               _buildInfoRow(theme, Icons.bookmark_border_outlined, 'Ayat', data['ayathafalansurat'] ?? '-'),
//               _buildInfoRow(theme, Icons.library_books_outlined, 'UMMI/Qur\'an', data['ummijilidatausurat'] ?? '-'),
//               _buildInfoRow(theme, Icons.article_outlined, 'Hal/Ayat UMMI', data['ummihalatauayat'] ?? '-'),
//               _buildInfoRow(theme, Icons.lightbulb_outline, 'Materi', data['materi'] ?? '-'),
//               const SizedBox(height: 10),
//               Align( // Align nilai ke kanan
//                 alignment: Alignment.centerRight,
//                 child: Chip(
//                   label: Text('$nilaiAngka ($nilaiHuruf)', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: _getNilaiColor(theme, nilaiHuruf))),
//                   backgroundColor: _getNilaiColor(theme, nilaiHuruf).withOpacity(0.1),
//                   side: BorderSide.none, // Hilangkan border default Chip jika mau
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   labelPadding: EdgeInsets.zero, // Atur padding label jika perlu
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 3.0), // Kurangi padding vertikal
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center, // Pusatkan ikon dan teks secara vertikal
//         children: [
//           Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.9)), // Ukuran ikon lebih kecil
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text.rich( // Gunakan Text.rich untuk styling yang lebih mudah dibaca
//               TextSpan(
//                 style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
//                 children: [
//                   TextSpan(text: '$label: '),
//                   TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
//                 ],
//               ),
//                maxLines: 2, // Batasi jumlah baris jika teks panjang
//                overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getNilaiColor(ThemeData theme, String nilaiHuruf) {
//     switch (nilaiHuruf.toUpperCase()) {
//       case 'A': return Colors.green.shade600;
//       case 'B': return Colors.blue.shade600;
//       case 'C': return Colors.orange.shade600; // Sedikit lebih terang
//       case 'D': return Colors.red.shade500;   // Sedikit lebih terang
//       case 'E': return Colors.red.shade700;
//       default: return theme.colorScheme.onSurfaceVariant; // Warna default yang lebih netral
//     }
//   }

//   Widget _buildEmptyStateWidget(ThemeData theme) {
//     // ... (implementasi sama seperti _buildEmptyState sebelumnya)
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.inbox_outlined, size: 70, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'Belum Ada Riwayat Nilai',
//               style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 6),
//             Text(
//               'Nilai yang diinput akan muncul di sini.',
//               style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorStateWidget(ThemeData theme, String message) {
//     // ... (implementasi sama seperti _buildErrorState sebelumnya, tapi tambahkan tombol refresh jika belum ada)
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.cloud_off_outlined, size: 70, color: theme.colorScheme.error),
//             const SizedBox(height: 16),
//             Text(
//               'Oops! Gagal Memuat',
//               style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 6),
//             Text(
//               message,
//               style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.refresh, size: 20),
//               label: const Text("Coba Lagi"),
//               onPressed: () {
//                  print("DaftarNilaiView: Tombol 'Coba Lagi' ditekan.");
//                  // Panggil method untuk refresh data di controller
//                  // controller.refreshDataNilai(); // Contoh jika Anda membuat method ini
//                  // Atau jika update() cukup untuk memicu re-fetch:
//                  controller.update(); // Ini akan memicu rebuild Obx, yang kemudian memanggil StreamBuilder lagi
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: theme.colorScheme.errorContainer,
//                 foregroundColor: theme.colorScheme.onErrorContainer,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// ============= KODE LAMA ==========================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../routes/app_pages.dart';
import '../controllers/daftar_nilai_controller.dart';

class DaftarNilaiView extends GetView<DaftarNilaiController> {
  DaftarNilaiView({super.key});

  final dataxx = Get.arguments;

  @override
  Widget build(BuildContext context) {
    print("dataxx = $dataxx");
    return Scaffold(
      // appBar: _buildAppBar(),
      appBar: AppBar(title: Text('Daftar Nilai'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Column(
              children: [
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 30, bottom: 10),
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(40),
                      image: DecorationImage(
                        image: NetworkImage(
                          "https://ui-avatars.com/api/?name=${dataxx['namasiswa']}",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Text(dataxx['namasiswa']),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: controller.getDataNilai(),
                builder: (context, snapshot) {
                  print("snapshot length = ${snapshot.data?.docs.length}");
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('Belum ada data nilai'));
                  }
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data = snapshot.data!.docs[index].data();
                        return GestureDetector(
                          onTap: () {
                            Get.toNamed(
                              Routes.DETAIL_NILAI_HALAQOH,
                              arguments: data,
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: 10,
                              left: 10,
                              right: 10,
                            ),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.grey[300],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  // scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Ust.${data['namapengampu']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        DateFormat.yMMMEd().format(
                                          DateTime.parse(data['tanggalinput']),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 7),
                                Divider(height: 2, color: Colors.black),
                                SizedBox(height: 7),
                                Text('Hafalan Surat : ${data['hafalansurat']}'),
                                SizedBox(height: 7),
                                Text(
                                  'UMMI Jld/ Surat : ${data['ummijilidatausurat']}',
                                ),
                                SizedBox(height: 7),
                                Text('Materi : ${data['materi']}'),
                                // SizedBox(height: 7),
                                // Text('Nilai Angka : ${data['nilai']}'),
                                // SizedBox(height: 7),
                                // Text('Nilai Huruf : ${data['nilaihuruf']}'),
                                // SizedBox(height: 15),
                                // Text(
                                //   'Catatan',
                                //   style: TextStyle(
                                //       fontSize: 14,
                                //       fontWeight: FontWeight.bold),
                                // ),
                                // Divider(),
                                // // SizedBox(height: 3),
                                // Text(
                                //     'pengampu : ${data['keteranganpengampu']}'),
                                // SizedBox(height: 7),
                                // // Text('orangtua : ${data['keteranganorangtua']}'),
                                // // Text( "orangtua : ${data == 0 ? (data['keteranganorangtua'] ?? '-') : '-'}"),
                                // if (data['keteranganorangtua'] != "0")
                                //       Text('orangtua : ${data['keteranganorangtua']}')
                                // else Text("orangtua : -")
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(child: Text('No data available'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
