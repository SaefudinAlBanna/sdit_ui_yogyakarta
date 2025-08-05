import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_pages.dart';
import '../controllers/log_ekskul_siswa_controller.dart';
// import '../models/catatan_prestasi_model.dart';
import '../../../models/catatan_prestasi_model.dart';

class LogEkskulSiswaView extends GetView<LogEkskulSiswaController> {
  const LogEkskulSiswaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Log: ${controller.siswa.nama}"),
        actions: [
          // --- KOREKSI DI SINI ---
          IconButton(
            tooltip: 'Lihat Pratinjau Rapor Ekskul',
            onPressed: () {
              // 1. Ambil objek 'siswa' dari controller
              final siswaUntukRapor = controller.siswa;
              
              // 2. Navigasi ke halaman rapor dan kirim objek tersebut
              Get.toNamed(
                Routes.RAPOR_EKSKUL_SISWA, // Pastikan nama rute ini benar
                arguments: siswaUntukRapor,
              );
            }, 
            icon: const Icon(Icons.library_books_outlined)
          )
          // ------------------------
        ],
      ),
      
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarCatatan.isEmpty) {
          return const Center(child: Text("Belum ada catatan untuk siswa ini."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.daftarCatatan.length,
          itemBuilder: (context, index) {
            final catatan = controller.daftarCatatan[index];
            final bool canEditOrDelete = catatan.dibuatOlehUid == controller.homeC.idUser;
            return Card(
              child: ListTile(
                leading: _buildCategoryIcon(catatan.kategoriCatatan),
                title: Text(catatan.deskripsiCatatan),
                subtitle: Text(
                  "${catatan.kategoriCatatan} - ${DateFormat.yMd('id_ID').format(catatan.tanggal.toDate())}\nDicatat oleh: ${catatan.dibuatOlehNama}"
                ),
                isThreeLine: true,
                    trailing: canEditOrDelete
                    ? PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            // Panggil dialog form dalam mode edit
                            _showCatatanForm(catatanToEdit: catatan);
                          } else if (value == 'delete') {
                            // Panggil dialog konfirmasi hapus
                            _showDeleteConfirmation(catatan.id);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Hapus'),
                          ),
                        ],
                      )
                    : null, // Sembunyikan tombol jika bukan pembuatnya
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCatatanForm(),
        child: const Icon(Icons.add_comment),
        tooltip: 'Tambah Catatan Baru',
      ),
    );
  }

  Widget _buildCategoryIcon(String kategori) {
    IconData iconData;
    Color color;
    switch (kategori) {
      case 'Prestasi':
        iconData = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 'Sikap':
        iconData = Icons.psychology;
        color = Colors.blue;
        break;
      case 'Pelanggaran':
        iconData = Icons.warning;
        color = Colors.red;
        break;
      default:
        iconData = Icons.notes;
        color = Colors.grey;
    }
    return Icon(iconData, color: color, size: 40);
  }

  void _showCatatanForm({CatatanPrestasiModel? catatanToEdit}) {

    final bool isUpdate = catatanToEdit != null;

    if (isUpdate) {
        controller.fillFormForEdit(catatanToEdit);
      } else {
        // Reset form untuk mode tambah baru
        controller.deskripsiC.clear();
        controller.selectedKategori.value = null;
        controller.selectedTanggal.value = DateTime.now();
      }

      Get.defaultDialog(
      title: isUpdate ? "Edit Catatan" : "Tambah Catatan Baru",
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              Obx(() => DropdownButtonFormField<String>(
                value: controller.selectedKategori.value,
                hint: const Text("Pilih Kategori"),
                items: controller.kategoriOptions.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (value) => controller.selectedKategori.value = value,
              )),
              TextFormField(
                controller: controller.deskripsiC,
                decoration: const InputDecoration(labelText: "Deskripsi Catatan"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Obx(() => TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text("Tanggal: ${DateFormat.yMd('id_ID').format(controller.selectedTanggal.value!)}"),
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: Get.context!,
                    initialDate: controller.selectedTanggal.value!,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    controller.selectedTanggal.value = pickedDate;
                  }
                },
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          // Panggil saveCatatan dengan atau tanpa ID
          onPressed: () => controller.saveCatatan(catatanId: catatanToEdit?.id),
          child: const Text("Simpan"),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String catatanId) {
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Anda yakin ingin menghapus catatan ini secara permanen?",
      actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
          controller.deleteCatatan(catatanId);
          Get.back(); // Tutup dialog konfirmasi
        },
       child: const Text("Ya, Hapus"),
       ),
      ],
    );
  }
}
