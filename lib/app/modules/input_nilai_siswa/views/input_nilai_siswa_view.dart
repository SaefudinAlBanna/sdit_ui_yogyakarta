import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/nilai_harian_model.dart';
import '../../../models/tujuan_pembelajaran_model.dart'; // <-- Pastikan model ini di-import
import '../controllers/input_nilai_siswa_controller.dart';

class InputNilaiSiswaView extends GetView<InputNilaiSiswaController> {
  const InputNilaiSiswaView({super.key});
  @override
  Widget build(BuildContext context) {
    // Pindahkan state selector kategori ke dalam controller jika ingin persisten
    // atau biarkan di sini jika hanya untuk state tampilan sesaat. Di sini sudah cukup.
    final RxString selectedKategori = "Harian/PR".obs;

    // Pemeriksaan inisialisasi awal yang krusial
    if (!controller.isInitSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Gagal memuat data awal. Silakan kembali.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              controller.namaMapel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(controller.namaSiswa, style: const TextStyle(fontSize: 14)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.percent_rounded),
            tooltip: "Atur Bobot Penilaian",
            onPressed: () => _showBobotDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNilaiAkhirCard(),
            const SizedBox(height: 24),

            // --- BAGIAN PENILAIAN ---
            Text("Penilaian Sumatif", style: Get.textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildKategoriSelector(selectedKategori),
            const SizedBox(height: 16),
            Obx(() => _buildKontenNilai(selectedKategori.value)),

            const Divider(height: 48, thickness: 1),

            // --- BAGIAN BARU: KURIKULUM MERDEKA ---
            _buildKurikulumMerdekaSection(),

            // --- BAGIAN KHUSUS WALI KELAS ---
            Obx(() {
              if (controller.isWaliKelas.value) {
                return _buildRekapWaliKelas();
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      }),
    );
  }

  //========================================================================
  // --- WIDGET-WIDGET UTAMA (TIDAK BERUBAH BANYAK) ---
  //========================================================================
  void _showBobotDialog(BuildContext context) {
    controller.harianC.text = (controller.bobotNilai['harian'] ?? 0).toString();
    controller.ulanganC.text =
        (controller.bobotNilai['ulangan'] ?? 0).toString();
    controller.ptsC.text = (controller.bobotNilai['pts'] ?? 0).toString();
    controller.pasC.text = (controller.bobotNilai['pas'] ?? 0).toString();
    controller.tambahanC.text =
        (controller.bobotNilai['tambahan'] ?? 0).toString();

    Get.defaultDialog(
      title: "Atur Bobot Nilai (Total Harus 100%)",
      titleStyle: const TextStyle(fontSize: 16),
      content: Form(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: controller.harianC,
                decoration: const InputDecoration(labelText: "Harian/PR (%)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: controller.ulanganC,
                decoration: const InputDecoration(labelText: "Ulangan (%)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: controller.ptsC,
                decoration: const InputDecoration(labelText: "PTS (%)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: controller.pasC,
                decoration: const InputDecoration(labelText: "PAS (%)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: controller.tambahanC,
                decoration: const InputDecoration(labelText: "Tambahan (%)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      confirm: Obx(
        () => ElevatedButton(
          onPressed:
              controller.isSaving.value ? null : controller.simpanBobotNilai,
          child:
              controller.isSaving.value
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text("Simpan"),
        ),
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  Widget _buildNilaiAkhirCard() {
    return Card(
      elevation: 4,
      color: Get.theme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "NILAI AKHIR RAPOR",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Text(
                controller.nilaiAkhir.value?.toStringAsFixed(1) ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 42,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriSelector(RxString selectedKategori) {
    final kategori = [
      "Harian/PR",
      "Ulangan Harian",
      "PTS",
      "PAS",
      "Nilai Tambahan",
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            kategori
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Obx(
                      () => ChoiceChip(
                        label: Text(item),
                        selectedColor: Get.theme.primaryColor.withOpacity(0.8),
                        labelStyle: TextStyle(
                          color:
                              selectedKategori.value == item
                                  ? Colors.white
                                  : Colors.black,
                        ),
                        selected: selectedKategori.value == item,
                        onSelected: (selected) {
                          if (selected) selectedKategori.value = item;
                        },
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildKontenNilai(String kategori) {
    switch (kategori) {
      case "PTS":
        return _buildNilaiUtamaCard(
          "Penilaian Tengah Semester (PTS)",
          controller.nilaiPTS,
          'nilai_pts',
        );
      case "PAS":
        return _buildNilaiUtamaCard(
          "Penilaian Akhir Semester (PAS)",
          controller.nilaiPAS,
          'nilai_pas',
        );
      case "Harian/PR":
      case "Ulangan Harian":
      case "Nilai Tambahan":
        return _buildNilaiHarianList(kategori);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNilaiUtamaCard(
    String title,
    Rxn<int> nilaiState,
    String fieldName,
  ) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Obx(
          () => Text(
            nilaiState.value?.toString() ?? "Belum Diisi",
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: nilaiState.value == null ? Colors.grey : null,
            ),
          ),
        ),
        onTap:
            () => _showInputDialog(
              title: "Input $title",
              initialValue: nilaiState.value?.toString() ?? '',
              onSave: () => controller.simpanNilaiUtama(fieldName),
            ),
      ),
    );
  }

  // Ganti fungsi lama dengan yang ini
Widget _buildNilaiHarianList(String kategori) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Obx harus membungkus Widget, bukan menjadi nilai variabel List.
      Obx(() {
        // 1. Lakukan pemfilteran di dalam builder Obx.
        //    Hasilnya adalah List biasa, bukan RxList.
        final List<NilaiHarian> listNilai;
        if (kategori == "Harian/PR") {
          listNilai = controller.daftarNilaiHarian
              .where((n) => n.kategori == "Harian/PR" || n.kategori == "PR")
              .toList();
        } else {
          listNilai = controller.daftarNilaiHarian
              .where((n) => n.kategori == kategori)
              .toList();
        }

        // 2. Gunakan List yang sudah difilter untuk membangun UI.
        //    Builder Obx harus me-return sebuah Widget.
        if (listNilai.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                "Belum ada nilai untuk kategori ini.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }
        
        // Return sebuah Column yang berisi daftar Card.
        return Column(
          children: listNilai.map((nilai) {
            // Kita bungkus Card dengan Builder agar context PopupMenu benar
            return Builder(
              builder: (context) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(nilai.nilai.toString())),
                    title: Text(nilai.catatan.isNotEmpty ? nilai.catatan : "Nilai ${nilai.kategori}"),
                    subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(nilai.tanggal)),
                    
                    // --- TAMBAHAN BARU: TOMBOL AKSI ---
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit') {
                          // Panggil dialog input dengan data yang ada
                          _showInputDialog(
                            title: "Edit Nilai ${nilai.kategori}",
                            showCatatan: true,
                            initialValue: nilai.nilai.toString(),
                            initialCatatan: nilai.catatan,
                            onSave: () => controller.updateNilaiHarian(nilai.id),
                          );
                        } else if (value == 'hapus') {
                          // Panggil fungsi hapus dari controller
                          controller.deleteNilaiHarian(nilai.id);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
                        ),
                        const PopupMenuItem<String>(
                          value: 'hapus',
                          child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Hapus', style: TextStyle(color: Colors.red))),
                        ),
                      ],
                    ),
                  ),
                );
              }
            );
          }).toList(),
        );
      }),
      
      const SizedBox(height: 16),
      
      // Tombol ini tidak perlu ada di dalam Obx karena tidak bergantung
      // pada perubahan data nilai.
      ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: Text("Tambah Nilai $kategori"),
        onPressed: () => _showInputDialog(
          title: "Tambah Nilai $kategori",
          showCatatan: true,
          onSave: () => controller.simpanNilaiHarian(kategori),
        ),
      ),
    ],
  );
}

  void _showInputDialog({
    required String title,
    String initialValue = '',
    String initialCatatan = '',
    bool showCatatan = false,
    required VoidCallback onSave,
  }) {
    controller.nilaiC.text = initialValue;
    controller.catatanC.clear();
    Get.defaultDialog(
      title: title,
      content: Column(
        children: [
          TextField(
            controller: controller.nilaiC,
            decoration: const InputDecoration(labelText: 'Nilai (0-100)'),
            keyboardType: TextInputType.number,
          ),
          if (showCatatan) ...[
            const SizedBox(height: 8),
            TextField(
              controller: controller.catatanC,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
              ),
            ),
          ],
        ],
      ),
      confirm: Obx(
        () => ElevatedButton(
          onPressed: controller.isSaving.value ? null : onSave,
          child:
              controller.isSaving.value
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text("Simpan"),
        ),
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
    );
  }

  //========================================================================
  // --- WIDGET-WIDGET BARU (KURIKULUM MERDEKA & WALI KELAS) ---
  //========================================================================
  /// Widget utama yang mengatur tampilan bagian Kurikulum Merdeka.
  Widget _buildKurikulumMerdekaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Capaian Pembelajaran", style: Get.textTheme.titleLarge),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoadingTP.value) {
            return const Center(child: CircularProgressIndicator());
          }
          // Jika daftar TP tidak kosong, tampilkan listnya
          if (controller.daftarTP.isNotEmpty) {
            return _buildTPList();
          }
          // Jika kosong, tampilkan input manual
          return _buildDeskripsiManualCard();
        }),
      ],
    );
  }

  /// Widget untuk menampilkan daftar Tujuan Pembelajaran (TP).
  Widget _buildTPList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pilih capaian siswa berdasarkan Tujuan Pembelajaran yang ada.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...controller.daftarTP.map((tp) => _buildTPItem(tp)).toList(),
      ],
    );
  }

  /// Widget untuk satu item dalam daftar TP.
  Widget _buildTPItem(TujuanPembelajaranModel tp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tp.deskripsi, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilterChip(
                    label: const Text("Tercapai"),
                    selected: controller.capaianSiswa[tp.id] == 'Tercapai',
                    onSelected: (selected) {
                      if (selected)
                        controller.simpanCapaianTP(tp.id, 'Tercapai');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text("Perlu Bimbingan"),
                    selected:
                        controller.capaianSiswa[tp.id] == 'Perlu Bimbingan',
                    onSelected: (selected) {
                      if (selected)
                        controller.simpanCapaianTP(tp.id, 'Perlu Bimbingan');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget yang ditampilkan jika TP tidak ada, sebagai fallback.
  Widget _buildDeskripsiManualCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Deskripsi Manual",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Karena Tujuan Pembelajaran untuk mapel ini belum dibuat, silakan isi deskripsi capaian siswa secara manual.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.deskripsiCapaianC,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Deskripsi Capaian Siswa",
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => ElevatedButton.icon(
                icon:
                    controller.isSaving.value
                        ? const SizedBox()
                        : const Icon(Icons.save),
                label:
                    controller.isSaving.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Simpan Deskripsi"),
                onPressed:
                    controller.isSaving.value
                        ? null
                        : controller.simpanDeskripsiCapaian,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk menampilkan rekap nilai jika user adalah wali kelas.
  Widget _buildRekapWaliKelas() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32),
          Text(
            "Rekap Nilai (Akses Wali Kelas)",
            style: Get.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Obx(
            () => Card(
              child:
                  (controller.rekapNilaiMapelLain.isEmpty)
                      ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("Belum ada nilai dari mapel lain."),
                      )
                      : Column(
                        children:
                            controller.rekapNilaiMapelLain
                                .map(
                                  (rekap) => ListTile(
                                    title: Text(rekap['mapel']),
                                    trailing: Text(
                                      double.tryParse(
                                            rekap['nilai_akhir'].toString(),
                                          )?.toStringAsFixed(1) ??
                                          '-',
                                      style: Get.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}



// // lib/app/modules/input_nilai_siswa/views/input_nilai_siswa_view.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../../models/nilai_harian_model.dart';
// import '../controllers/input_nilai_siswa_controller.dart';

// class InputNilaiSiswaView extends GetView<InputNilaiSiswaController> {
//   const InputNilaiSiswaView({super.key});

//   @override
//   Widget build(BuildContext context) {

      
//     // State untuk mengelola kategori nilai yang dipilih
//     final RxString selectedKategori = "Harian/PR".obs;

//     if (!controller.isInitSuccess) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           children: [
//             Text(controller.namaMapel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             Text(controller.namaSiswa, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
//           ],
//         ),
//         centerTitle: true,

//         actions: [
//           IconButton(
//             icon: const Icon(Icons.percent_rounded),
//             tooltip: "Atur Bobot Penilaian",
//             onPressed: () => _showBobotDialog(context),
//           )
//         ],
//       ),
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         return ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _buildNilaiAkhirCard(),
//             const SizedBox(height: 24),
//             _buildKategoriSelector(selectedKategori),
//             const SizedBox(height: 16),
//             // Tampilkan konten yang sesuai dengan kategori yang dipilih
//             Obx(() => _buildKontenNilai(selectedKategori.value)),
            
//             // --- BAGIAN KHUSUS WALI KELAS ---
//             Obx(() {
//               if (controller.isWaliKelas.value) {
//                 return _buildRekapWaliKelas();
//               }
//               return const SizedBox.shrink(); // Sembunyikan jika bukan wali kelas
//             })
//           ],
//         );
//       }),
//     );
//   }

//   void _showBobotDialog(BuildContext context) {
//     // Isi controller dengan nilai bobot saat ini
//     controller.harianC.text = (controller.bobotNilai['harian'] ?? 20).toString();
//     controller.ulanganC.text = (controller.bobotNilai['ulangan'] ?? 20).toString();
//     controller.ptsC.text = (controller.bobotNilai['pts'] ?? 20).toString();
//     controller.pasC.text = (controller.bobotNilai['pas'] ?? 20).toString();
//     controller.tambahanC.text = (controller.bobotNilai['tambahan'] ?? 20).toString();

//     Get.defaultDialog(
//       title: "Atur Bobot Nilai",
//       content: SingleChildScrollView(
//         child: Column(
//           children: [
//             TextField(controller: controller.harianC, decoration: const InputDecoration(labelText: "Harian/PR (%)"), keyboardType: TextInputType.number),
//             TextField(controller: controller.ulanganC, decoration: const InputDecoration(labelText: "Ulangan Harian (%)"), keyboardType: TextInputType.number),
//             TextField(controller: controller.ptsC, decoration: const InputDecoration(labelText: "PTS (%)"), keyboardType: TextInputType.number),
//             TextField(controller: controller.pasC, decoration: const InputDecoration(labelText: "PAS (%)"), keyboardType: TextInputType.number),
//             TextField(controller: controller.tambahanC, decoration: const InputDecoration(labelText: "Nilai Tambahan (%)"), keyboardType: TextInputType.number),
//           ],
//         ),
//       ),
//       confirm: Obx(() => ElevatedButton(
//         onPressed: controller.isSaving.value ? null : controller.simpanBobotNilai,
//         child: controller.isSaving.value ? const CircularProgressIndicator() : const Text("Simpan"),
//       )),
//       cancel: TextButton(onPressed: Get.back, child: const Text("Batal")),
//     );
//   }

//   Widget _buildNilaiAkhirCard() {
//     return Card(
//       elevation: 4,
//       color: Get.theme.primaryColor,
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             Text("NILAI AKHIR RAPOR", style: Get.textTheme.titleMedium?.copyWith(color: Colors.white70)),
//             const SizedBox(height: 8),
//             Obx(() => Text(
//               controller.nilaiAkhir.value?.toStringAsFixed(2) ?? '-',
//               style: Get.textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildKategoriSelector(RxString selectedKategori) {
//     final kategori = ["Harian/PR", "Ulangan Harian", "PTS", "PAS", "Nilai Tambahan"];
//     return SizedBox(
//       height: 40,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         itemCount: kategori.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 8),
//         itemBuilder: (context, index) {
//           return Obx(() => ChoiceChip(
//             label: Text(kategori[index]),
//             selected: selectedKategori.value == kategori[index],
//             onSelected: (selected) {
//               if (selected) selectedKategori.value = kategori[index];
//             },
//           ));
//         },
//       ),
//     );
//   }

//   Widget _buildKontenNilai(String kategori) {
//     switch (kategori) {
//       case "PTS":
//         return _buildNilaiUtamaCard("Penilaian Tengah Semester (PTS)", controller.nilaiPTS, 'nilai_pts');
//       case "PAS":
//         return _buildNilaiUtamaCard("Penilaian Akhir Semester (PAS)", controller.nilaiPAS, 'nilai_pas');
//       case "Harian/PR":
//       case "Ulangan Harian":
//       case "Nilai Tambahan":
//         return _buildNilaiHarianList(kategori);
//       default:
//         return const SizedBox.shrink();
//     }
//   }

//   // Widget _buildNilaiUtamaCard(String title, Rxn<int> nilaiState, String fieldName) {
//   //   return Card(
//   //     child: ListTile(
//   //       title: Text(title),
//   //       // trailing: Text(nilaiState.value?.toString() ?? "Belum Diisi", style: Get.textTheme.titleLarge),
//   //       trailing: Text(nilaiState.value?.toString() ?? "Belum Diisi", style: Get.textTheme.titleLarge),
//   //       onTap: () => _showInputDialog(
//   //         title: "Input $title",
//   //         initialValue: nilaiState.value?.toString() ?? '',
//   //         onSave: () => controller.simpanNilaiUtama(fieldName),
//   //       ),
//   //     ),
//   //   );
//   // }

//   Widget _buildNilaiUtamaCard(String title, Rxn<int> nilaiState, String fieldName) {
//     return Card(
//       child: ListTile(
//         title: Text(title),
//         trailing: Obx(() => Text(
//           nilaiState.value?.toString() ?? "...", // Tampilkan "..."
//           style: Get.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: nilaiState.value == null ? Colors.grey.shade400 : null
//           )
//         )),
//         onTap: () => _showInputDialog(
//           title: "Input $title",
//           // Ambil nilai saat ini untuk ditampilkan di dialog
//           initialValue: nilaiState.value?.toString() ?? '',
//           // Beritahu controller untuk menyimpan ke field yang benar ('nilai_pts' atau 'nilai_pas')
//           onSave: () => controller.simpanNilaiUtama(fieldName),
//         ),
//       ),
//     );
//   }

//   // Widget _buildNilaiHarianList(String kategori) {
//   //   final listNilai = controller.daftarNilaiHarian.where((n) => n.kategori == kategori).toList();
//   Widget _buildNilaiHarianList(String kategori) {
//     List<NilaiHarian> listNilai;
//     if (kategori == "Harian/PR") {
//       listNilai = controller.daftarNilaiHarian.where((n) => n.kategori == "Harian/PR" || n.kategori == "PR").toList();
//     } else {
//       listNilai = controller.daftarNilaiHarian.where((n) => n.kategori == kategori).toList();
//     }
//     return Column(
//       children: [
//         if (listNilai.isEmpty)
//           const Padding(padding: EdgeInsets.all(32.0), child: Text("Belum ada nilai.")),
//         ...listNilai.map((nilai) => Card(
//           child: ListTile(
//             leading: CircleAvatar(child: Text(nilai.nilai.toString())),
//             title: Text(nilai.catatan.isNotEmpty ? nilai.catatan : "Nilai ${kategori}"),
//             subtitle: Text(DateFormat('dd MMM yyyy').format(nilai.tanggal)),
//             // Di sini bisa ditambahkan tombol edit/hapus per item jika perlu
//           ),
//         )),
//         const SizedBox(height: 16),
//         ElevatedButton.icon(
//           icon: const Icon(Icons.add),
//           label: Text("Tambah Nilai $kategori"),
//           onPressed: () => _showInputDialog(
//             title: "Tambah Nilai $kategori",
//             onSave: () => controller.simpanNilaiHarian(kategori),
//           ),
//         )
//       ],
//     );
//   }

//   Widget _buildRekapWaliKelas() {
//     return Padding(
//       padding: const EdgeInsets.only(top: 24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Divider(height: 32),
//           Text("Rekap Nilai (sebagai Wali Kelas)", style: Get.textTheme.titleLarge),
//           const SizedBox(height: 8),
//           Obx(() => Card(
//             child: Column(
//               children: controller.rekapNilaiMapelLain.map((rekap) => ListTile(
//                 title: Text(rekap['mapel']),
//                 trailing: Text(rekap['nilai_akhir'].toString(), style: Get.textTheme.titleMedium),
//               )).toList(),
//             ),
//           )),
//         ],
//       ),
//     );
//   }

//   void _showInputDialog({required String title, String initialValue = '', required VoidCallback onSave}) {
//     controller.nilaiC.text = initialValue;
//     controller.catatanC.clear(); // Selalu bersihkan catatan
//     Get.defaultDialog(
//       title: title,
//       content: Column(
//         children: [
//           TextField(controller: controller.nilaiC, decoration: const InputDecoration(labelText: 'Nilai (0-100)'), keyboardType: TextInputType.number),
//           const SizedBox(height: 8),
//           TextField(controller: controller.catatanC, decoration: const InputDecoration(labelText: 'Catatan (Opsional)')),
//         ],
//       ),
//       confirm: Obx(() => ElevatedButton(
//         onPressed: controller.isSaving.value ? null : onSave,
//         child: controller.isSaving.value ? const CircularProgressIndicator() : const Text("Simpan"),
//       )),
//       cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
//     );
//   }
// }