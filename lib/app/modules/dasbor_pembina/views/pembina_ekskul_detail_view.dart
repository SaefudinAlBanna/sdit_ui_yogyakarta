import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/pengumuman_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/pembina_ekskul_controller.dart';

class PembinaEkskulDetailView extends GetView<PembinaEkskulController> {
  final String namaEkskul;
  const PembinaEkskulDetailView({super.key, required this.namaEkskul});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Jumlah Tab
      child: Scaffold(
        appBar: AppBar(
          title: Text(namaEkskul),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.campaign), text: "Pengumuman"),
              Tab(icon: Icon(Icons.groups), text: "Anggota"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: PENGUMUMAN ---
            _buildPengumumanTab(),
            
            // --- TAB 2: ANGGOTA (DALAM PENGEMBANGAN) ---
            // const Center(child: Text("Fitur Manajemen Anggota akan dikembangkan.")),
            _buildAnggotaTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showPengumumanForm(),
          child: const Icon(Icons.add),
          tooltip: 'Buat Pengumuman Baru',
        ),
      ),
    );
  }

  // Widget _buildAnggotaTab() {
  //   return Column(
  //     children: [
  //       // 1. Tombol untuk Aksi Massal
  //       Container(
  //         width: double.infinity,
  //         padding: const EdgeInsets.all(12.0),
  //         child: ElevatedButton.icon(
  //           icon: const Icon(Icons.note_add_outlined),
  //           label: const Text("Tambah Catatan untuk Semua Anggota"),
  //           onPressed: () => _showCatatanMassalForm(),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.teal, // Warna berbeda untuk menandakan aksi massal
  //             foregroundColor: Colors.white,
  //           ),
  //         ),
  //       ),
  //       const Divider(height: 1),
  //       // 2. Expanded untuk menampung daftar yang bisa di-scroll
  //       Expanded(
  //         child: Obx(() {
  //           if (controller.isLoading.value) {
  //             return const Center(child: CircularProgressIndicator());
  //           }
  //           if (controller.daftarAnggota.isEmpty) {
  //             return const Center(child: Text("Belum ada anggota di ekskul ini."));
  //           }
  //           // 3. ListView untuk menampilkan setiap anggota
  //           return ListView.builder(
  //             padding: const EdgeInsets.all(8),
  //             itemCount: controller.daftarAnggota.length,
  //             itemBuilder: (context, index) {
  //               final anggota = controller.daftarAnggota[index];
  //               return Card(
  //                 elevation: 2,
  //                 child: ListTile(
  //                   leading: CircleAvatar(child: Text(anggota.nama.substring(0, 1))),
  //                   title: Text(anggota.nama),
  //                   subtitle: Text("Kelas: ${anggota.namaKelas}"),
  //                   trailing: const Icon(Icons.chevron_right),
  //                   onTap: () {
  //                     // 4. Navigasi ke Halaman Log Aktivitas Siswa dengan rute yang unik
  //                     Get.toNamed(
  //                       Routes.LOG_EKSKUL_SISWA, // Gunakan rute yang sudah di-rename
  //                       arguments: {
  //                         'instanceEkskulId': controller.instanceEkskulId,
  //                         'siswa': anggota,
  //                       },
  //                     );
  //                   },
  //                 ),
  //               );
  //             },
  //           );
  //         }),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildAnggotaTab() {
    return Column(
      children: [
        ElevatedButton.icon(
                icon: const Icon(Icons.assessment),
                label: const Text("Kelola Nilai Rapor Semester Ini"),
                onPressed: () {
                  // Navigasi ke halaman penilaian
                  Get.toNamed(
                    Routes.PENILAIAN_RAPOR_EKSKUL, // <-- Rute yang dibuat CLI
                    arguments: controller.instanceEkskulId, // Kirim ID ekskul
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
        // --- Panel Kontrol untuk Mode Input Cepat ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              const Text("Mode Input Cepat", style: TextStyle(fontSize: 16)),
              Switch(
                value: controller.isModeInputCepatAktif.value,
                onChanged: (value) => controller.toggleInputCepat(value),
              ),
            ],
          )),
        ),

        // --- Panel Form Input Cepat (Hanya muncul jika mode aktif) ---
        Obx(() {
          if (!controller.isModeInputCepatAktif.value) {
            return const SizedBox.shrink(); // Sembunyikan jika mode tidak aktif
          }
          // Tampilkan panel form jika mode aktif
          return _buildInputCepatPanel();
        }),

        const Divider(height: 1),

        // --- Daftar Anggota (Sekarang dengan Checkbox dinamis) ---
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
            if (controller.daftarAnggota.isEmpty) return const Center(child: Text("Belum ada anggota."));

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: controller.daftarAnggota.length,
              itemBuilder: (context, index) {
                final anggota = controller.daftarAnggota[index];
                return Obx(() {
                  final isInputCepat = controller.isModeInputCepatAktif.value;
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      // Tampilkan checkbox hanya jika mode input cepat aktif
                      leading: isInputCepat
                          ? Checkbox(
                              value: controller.siswaTerpilihUntukCatatan.any((s) => s.nisn == anggota.nisn),
                              onChanged: (isSelected) => controller.toggleSiswaTerpilih(anggota, isSelected!),
                            )
                          : CircleAvatar(child: Text(anggota.nama.substring(0, 1))),
                      title: Text(anggota.nama),
                      subtitle: Text("Kelas: ${anggota.namaKelas}"),
                      // Non-aktifkan `onTap` jika dalam mode input cepat
                      onTap: isInputCepat
                          ? null // Tidak bisa diklik untuk melihat detail saat mode input cepat
                          : () {
                            // Navigasi ke Halaman Log Aktivitas per siswa
                            Get.toNamed(Routes.LOG_EKSKUL_SISWA, arguments: {
                              'instanceEkskulId': controller.instanceEkskulId,
                              'siswa': anggota,
                            });
                          },
                      trailing: isInputCepat ? null : const Icon(Icons.chevron_right),
                    ),
                  );
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInputCepatPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        children: [
          // Dropdown Kategori
          Obx(() => DropdownButtonFormField<String>(
            value: controller.kategoriMassal.value,
            hint: const Text("Pilih Kategori Catatan"),
            items: controller.kategoriOptions.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
            onChanged: (value) => controller.kategoriMassal.value = value,
          )),
          const SizedBox(height: 8),
          // TextField Deskripsi
          TextFormField(
            controller: controller.catatanMassalC,
            decoration: const InputDecoration(labelText: "Deskripsi Catatan", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          // Tombol Simpan
          ElevatedButton(
            onPressed: () => controller.saveCatatanUntukTerpilih(),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
            child: Obx(() => Text("Simpan untuk ${controller.siswaTerpilihUntukCatatan.length} Siswa Terpilih")),
          )
        ],
      ),
    );
  }

  // void _showCatatanMassalForm() {
  //   // Selalu reset state form sebelum dialog ditampilkan
  //   controller.catatanMassalC.clear();
  //   controller.kategoriMassal.value = null;
  //   controller.tanggalMassal.value = DateTime.now();

  //   Get.defaultDialog(
  //     title: "Tambah Catatan Massal",
  //     content: SingleChildScrollView(
  //       child: Form(
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // 1. Dropdown untuk memilih kategori catatan
  //               Obx(() => DropdownButtonFormField<String>(
  //                 value: controller.kategoriMassal.value,
  //                 hint: const Text("Pilih Kategori"),
  //                 isExpanded: true,
  //                 items: controller.kategoriOptions.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
  //                 onChanged: (value) => controller.kategoriMassal.value = value,
  //                 validator: (value) => value == null ? "Kategori wajib diisi" : null,
  //               )),
  //               const SizedBox(height: 16),
  //               // 2. Text field untuk deskripsi catatan
  //               TextFormField(
  //                 controller: controller.catatanMassalC,
  //                 decoration: const InputDecoration(
  //                   labelText: "Deskripsi Catatan",
  //                   hintText: "cth: Mengikuti latihan dengan baik.",
  //                   border: OutlineInputBorder(),
  //                 ),
  //                 maxLines: 3,
  //                 validator: (value) => (value?.isEmpty ?? true) ? "Deskripsi wajib diisi" : null,
  //               ),
  //               const SizedBox(height: 16),
  //               // 3. Tombol untuk memilih tanggal
  //               Obx(() => TextButton.icon(
  //                 icon: const Icon(Icons.calendar_today),
  //                 label: Text("Tanggal: ${DateFormat.yMMMMEEEEd('id_ID').format(controller.tanggalMassal.value!)}"),
  //                 onPressed: () async {
  //                   final pickedDate = await showDatePicker(
  //                     context: Get.context!,
  //                     initialDate: controller.tanggalMassal.value!,
  //                     firstDate: DateTime(2020),
  //                     lastDate: DateTime.now(),
  //                   );
  //                   if (pickedDate != null) {
  //                     controller.tanggalMassal.value = pickedDate;
  //                   }
  //                 },
  //               )),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //     actions: [
  //       TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
  //       ElevatedButton(
  //         onPressed: () => controller.saveCatatanMassal(),
  //         child: const Text("Simpan untuk Semua"),
  //       ),
  //     ],
  //   );
  // }


  Widget _buildPengumumanTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.daftarPengumuman.isEmpty) {
        return const Center(child: Text("Belum ada pengumuman."));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: controller.daftarPengumuman.length,
        itemBuilder: (context, index) {
          final pengumuman = controller.daftarPengumuman[index];
          return Card(
            child: ListTile(
              title: Text(pengumuman.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pengumuman.isi),
                  const SizedBox(height: 4),
                  Text(
                    "Oleh: ${pengumuman.dibuatOlehNama} - ${DateFormat.yMMMMEEEEd('id_ID').format(pengumuman.tanggalDibuat.toDate())}",
                    style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit")),
                  const PopupMenuItem(value: 'delete', child: Text("Hapus")),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showPengumumanForm(pengumuman: pengumuman);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(pengumuman.id);
                  }
                },
              ),
            ),
          );
        },
      );
    });
  }

  void _showPengumumanForm({PengumumanModel? pengumuman}) {
    final isUpdate = pengumuman != null;
    if (isUpdate) {
      controller.judulC.text = pengumuman.judul;
      controller.isiC.text = pengumuman.isi;
    } else {
      controller.judulC.clear();
      controller.isiC.clear();
    }

    Get.defaultDialog(
      title: isUpdate ? "Edit Pengumuman" : "Buat Pengumuman Baru",
      content: Form(
        child: Column(
          children: [
            TextFormField(controller: controller.judulC, decoration: const InputDecoration(labelText: "Judul")),
            TextFormField(controller: controller.isiC, decoration: const InputDecoration(labelText: "Isi Pengumuman"), maxLines: 4),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () => controller.savePengumuman(pengumumanId: pengumuman?.id),
          child: const Text("Simpan"),
        ),
      ],
    );
  }

   void _showDeleteConfirmation(String id) {
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      middleText: 'Apakah Anda yakin ingin menghapus pengumuman ini?',
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            controller.deletePengumuman(id);
            Get.back();
          },
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}