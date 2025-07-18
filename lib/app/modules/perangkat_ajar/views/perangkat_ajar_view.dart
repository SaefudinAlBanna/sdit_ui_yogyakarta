// app/modules/perangkat_ajar/views/perangkat_ajar_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/perangkat_ajar_controller.dart';
import '../../../models/atp_model.dart';
import '../../../models/modul_ajar_model.dart';
import '../../../routes/app_pages.dart';
import '../widgets/dialog_salin_data.dart';

class PerangkatAjarView extends GetView<PerangkatAjarController> {
  const PerangkatAjarView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Perangkat Ajar'),
          actions: [
            Obx(() {
              // --- PERBAIKAN 1: Logika yang lebih aman ---
              // Buat daftar dari Set untuk otomatis menghapus duplikat
              final Set<String> tahunSet = {
                controller.tahunAjaranAktif.value, 
                ...controller.daftarTahunAjaranLama
              };
              // Filter string kosong dan ubah kembali ke List
              final List<String> semuaTahun = tahunSet.where((th) => th.isNotEmpty).toList();
              
              // Ambil nilai filter saat ini
              final String filterValue = controller.tahunAjaranFilter.value;

              // --- PERBAIKAN 2: Cek validitas sebelum build ---
              // Jangan build Dropdown jika datanya belum siap atau tidak valid
              if (semuaTahun.isEmpty || !semuaTahun.contains(filterValue)) {
                // Tampilkan loading atau text sementara jika value belum valid
                if (controller.isLoading.value) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                  );
                }
                // Jika sudah tidak loading tapi tetap tidak valid (kasus langka)
                return SizedBox.shrink(); 
              }
              // --- AKHIR PERBAIKAN 2 ---

              if (semuaTahun.length <= 1) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(child: Text(filterValue.replaceAll('-', '/'))),
                );
              }
              
              // --- PERBAIKAN 3: Bungkus Dropdown agar tidak overflow ---
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                alignment: Alignment.center,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filterValue,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        controller.gantiTahunAjaranFilter(newValue);
                      }
                    },
                    items: semuaTahun.map<DropdownMenuItem<String>>((String idTahun) {
                      return DropdownMenuItem<String>(
                        value: idTahun,
                        child: Text(idTahun.replaceAll('-', '/')),
                      );
                    }).toList(),
                  ),
                ),
              );
              // --- AKHIR PERBAIKAN 3 ---
            }),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'ATP'),
              Tab(text: 'Modul Ajar'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            children: [
              _buildAtpListView(),
              _buildModulAjarListView(),
            ],
          );
        }),
        floatingActionButton: Builder(
          builder: (BuildContext newContext) {
            return FloatingActionButton(
              onPressed: () {
                int currentIndex = DefaultTabController.of(newContext).index;
                if (currentIndex == 0) {
                  Get.toNamed(Routes.ATP_FORM);
                } else {
                  Get.toNamed(Routes.MODUL_AJAR_FORM);
                }
              },
              child: Icon(Icons.add_rounded),
              tooltip: 'Tambah Perangkat Ajar Baru',
            );
          },
        ),
      ),
    );
  }

  // Widget untuk menampilkan daftar ATP
  Widget _buildAtpListView() {
    // Obx ini sekarang hanya bereaksi pada perubahan daftarAtp (tambah/hapus)
    return Obx(() {
      if (controller.daftarAtp.isEmpty) {
        return _buildEmptyState('ATP');
      }
      return ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: controller.daftarAtp.length,
        itemBuilder: (context, index) {
          final AtpModel atp = controller.daftarAtp[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: ListTile(
              
              leading: Icon(Icons.route_rounded, color: Colors.blue.shade700),
              title: Text(atp.namaMapel, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Kelas ${atp.kelas} (${atp.fase}) - ${atp.unitPembelajaran.length} Unit"),
              // trailing: IconButton(
              //   icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              //   onPressed: () => _showDeleteConfirmation('ATP', atp.idAtp),
              // ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(child: Text("Edit"), onTap: () => Get.toNamed(Routes.ATP_FORM, arguments: atp)),
                  PopupMenuItem(child: Text("Jadwal (Prosem)"), onTap: () {
                    // Beri jeda sedikit agar menu tertutup dulu sebelum navigasi
                    Future.delayed(Duration(milliseconds: 100), () {
                       Get.toNamed(Routes.PROTA_PROSEM, arguments: atp);
                    });
                  }),
                  PopupMenuItem(child: Text("Hapus", style: TextStyle(color: Colors.red)), onTap: () {
                     Future.delayed(Duration(milliseconds: 100), () {
                       _showDeleteConfirmation('ATP', atp.idAtp);
                    });
                  }),
                ],
                icon: Icon(Icons.more_vert),
              ),
              onTap: () => Get.toNamed(Routes.ATP_FORM, arguments: atp),
            ),
          );
        },
      );
    });
  }

  // Widget untuk menampilkan daftar Modul Ajar
  Widget _buildModulAjarListView() {
    // Obx ini sekarang hanya bereaksi pada perubahan daftarModulAjar
    return Obx(() {
      if (controller.daftarModulAjar.isEmpty) {
        return _buildEmptyState('Modul Ajar');
      }
      return ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: controller.daftarModulAjar.length,
        itemBuilder: (context, index) {
          final ModulAjarModel modul = controller.daftarModulAjar[index];
          return Card(
             margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: ListTile(
              leading: Icon(Icons.article_outlined, color: Colors.green.shade700),
              title: Text(modul.mapel, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Kelas ${modul.kelas} - ${modul.alokasiWaktu}"),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: () => _showDeleteConfirmation('Modul Ajar', modul.idModul),
              ),
              onTap: () => Get.toNamed(Routes.MODUL_AJAR_FORM, arguments: modul),
            ),
          );
        },
      );
    });
  }

  // Helper widget untuk tampilan kosong, sekarang tidak butuh callback lagi
  Widget _buildEmptyState(String jenis) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined, size: 60, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text('Belum ada $jenis untuk tahun ajaran ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.copy_all_outlined),
              label: Text('Salin dari Tahun Lalu'),
              onPressed: () {
                 Get.dialog(DialogSalinData(jenisPerangkat: jenis));
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk dialog konfirmasi hapus
  void _showDeleteConfirmation(String jenis, String id) {
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Apakah Anda yakin ingin menghapus $jenis ini? Tindakan ini tidak dapat dibatalkan.",
      confirm: TextButton(
        onPressed: () {
          if (jenis == 'ATP') {
            controller.deleteAtp(id);
          } else {
            controller.deleteModulAjar(id);
          }
          Get.back();
        },
        child: Text("Ya, Hapus", style: TextStyle(color: Colors.red)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text("Batal"),
      ),
    );
  }
}