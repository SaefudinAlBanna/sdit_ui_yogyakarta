// lib/app/modules/pemberian_kelas_siswa/views/pemberian_kelas_siswa_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pemberian_kelas_siswa_controller.dart';

class PemberianKelasSiswaView extends GetView<PemberianKelasSiswaController> {
  const PemberianKelasSiswaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Obx(() {
          final kelas = controller.kelasTerpilih.value;
          return Text(kelas == null ? 'Pemberian Kelas Siswa' : 'Atur Kelas $kelas');
        }),
        centerTitle: true,
        // --- BAGIAN PENTING 1: TOMBOL PEMICU DI APPBAR ---
        actions: [
          Obx(() {
            // Tombol ini hanya akan muncul jika sebuah kelas sudah dipilih.
            if (controller.kelasTerpilih.value != null) {
              return IconButton(
                icon: const Icon(Icons.people_outline),
                tooltip: "Lihat Siswa di Kelas Ini",
                // Saat ditekan, panggil fungsi untuk menampilkan bottom sheet.
                onPressed: () { 
                  // Future.delayed(const Duration(seconds: 2), () {
                    _showDaftarSiswaBottomSheet(context);
                  });
                // },
              // );
            }
            // Jika belum ada kelas dipilih, jangan tampilkan apa-apa.
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildKelasSelector(),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: Obx(() {
                if (controller.kelasTerpilih.value == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text("Silakan pilih kelas di atas untuk memulai.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center),
                    ),
                  );
                }
                if (controller.isLoadingDetails.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildMainContent();
              }),
            ),
          ],
        );
      }),
    );
  }

  // --- BAGIAN PENTING 2: FUNGSI YANG DIPANGGIL ---
  // Ini adalah fungsi yang Anda buat, yang akan dieksekusi saat tombol di AppBar ditekan.
  void _showDaftarSiswaBottomSheet(BuildContext context) {
    Get.bottomSheet(
      // Widget yang menjadi isi bottom sheet
      DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 50, height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Judul & Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        "Siswa di Kelas ${controller.kelasTerpilih.value}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => controller.searchQuery.value = value,
                        decoration: const InputDecoration(
                          labelText: "Cari Nama Siswa...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25.0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20),
                // Daftar Siswa
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: controller.getSiswaDiKelasStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("Belum ada siswa di kelas ini."));
                      }
                      
                      return Obx(() {
                        final allSiswa = snapshot.data!.docs;
                        final query = controller.searchQuery.value.toLowerCase();
                        final filteredSiswa = allSiswa.where((doc) {
                          final nama = (doc.data()['namasiswa'] as String? ?? '').toLowerCase();
                          return nama.contains(query);
                        }).toList();

                        if (filteredSiswa.isEmpty) {
                          return const Center(child: Text("Siswa tidak ditemukan."));
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: filteredSiswa.length,
                          itemBuilder: (context, index) {
                            final siswa = filteredSiswa[index].data();
                            final nama = siswa['namasiswa'] ?? 'No Name';
                            final nisn = siswa['nisn'] ?? 'No NISN';

                            return ListTile(
                              leading: CircleAvatar(child: Text(nama.isNotEmpty ? nama[0] : 'S')),
                              title: Text(nama),
                              subtitle: Text("NISN: $nisn"),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                tooltip: "Keluarkan dari kelas",
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: "Konfirmasi",
                                    middleText: "Anda yakin ingin mengeluarkan $nama dari kelas ini?",
                                    textConfirm: "Ya, Keluarkan",
                                    textCancel: "Batal",
                                    confirmTextColor: Colors.white,
                                    onConfirm: () {
                                      Get.back(); // tutup dialog konfirmasi
                                      controller.removeSiswaFromKelas(nisn);
                                    }
                                  );
                                },
                              ),
                            );
                          },
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      backgroundColor: Colors.transparent, // Agar sudut rounded terlihat
      isScrollControlled: true, // Agar bisa set tinggi sheet
    );
  }

  // --- Sisa kode view tidak ada perubahan ---
  Widget _buildKelasSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.white,
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.daftarKelas.length,
          itemBuilder: (context, index) {
            final namaKelas = controller.daftarKelas[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Obx(() {
                final isSelected = controller.kelasTerpilih.value == namaKelas;
                return ChoiceChip(
                  label: Text(namaKelas),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.gantiKelasTerpilih(namaKelas);
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildWaliKelasSection(Get.context!),
        const Divider(height: 24, thickness: 4, indent: 16, endIndent: 16),
        _buildSiswaSection(),
      ],
    );
  }

  Widget _buildWaliKelasSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "1. Tentukan Wali Kelas",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final info = controller.kelasInfo.value;
            if (info == null) return const Center(child: Text("Memuat detail wali kelas..."));
            return info.isSet
                ? _buildWaliKelasInfo(info.namaWaliKelas!)
                : _buildPilihWaliKelas();
          }),
        ],
      ),
    );
  }

  Widget _buildWaliKelasInfo(String namaWaliKelas) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.person_pin_rounded, color: Colors.green),
        title: const Text("Wali Kelas"),
        subtitle: Text(namaWaliKelas, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildPilihWaliKelas() {
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wali kelas belum ditentukan. Silakan pilih:",
              style: TextStyle(color: Colors.orange),
            ),
            const SizedBox(height: 16),
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(showSearchBox: true, fit: FlexFit.loose),
              items: (f, cs) => controller.getDataWaliKelasBaru(),
              onChanged: (value) {
                // Beri jeda mikroskopis agar DropdownSearch sempat menutup
                // pop-up nya sebelum widget ini dihancurkan oleh rebuild.
                // Duration.zero sudah cukup untuk mendaftarkannya di event loop berikutnya.
                Future.delayed(const Duration(seconds: 2), () {
                  controller.onWaliKelasSelected(value);
                });
              },
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: "Pilih Wali Kelas",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiswaSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "2. Pilih Siswa untuk Ditambahkan",
                style: Theme.of(Get.context!).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 15),
              // Tombol untuk menambah semua siswa
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.playlist_add_check, size: 20),
                  label: const Text("Pilih Semua"),
                  onPressed: () {
                    // Konfirmasi sebelum menjalankan aksi massal
                    Get.defaultDialog(
                      title: "Konfirmasi",
                      middleText: "Anda yakin ingin menambahkan SEMUA siswa yang belum memiliki kelas ke ${controller.kelasTerpilih.value}?",
                      textConfirm: "Ya, Tambahkan Semua",
                      confirmTextColor: Colors.white,
                      onConfirm: () {
                        Get.back(); // Tutup dialog konfirmasi
                        controller.inisialisasiSemuaSiswaKeKelas();
                      },
                      textCancel: "Batal"
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() {
            final info = controller.kelasInfo.value;
            if (info == null || !info.isSet) {
              return _buildDisabledSiswaList();
            }
            return _buildSiswaList();
          })
        ],
      ),
    );
  }

  Widget _buildSiswaList() {
    return SizedBox(
      height: 400,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: controller.streamSiswa.value,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Semua siswa sudah memiliki kelas.', textAlign: TextAlign.center),
              ));
            }
            final data = snapshot.data!.docs;
            return Obx(() => controller.isLoadingTambahKelas.value
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      var siswaData = data[index].data();
                      String namaSiswa = siswaData['nama'] ?? 'No Name';
                      String nisnSiswa = siswaData['nisn'] ?? 'No NISN';
                      return ListTile(
                        leading: CircleAvatar(child: Text(namaSiswa.isNotEmpty ? namaSiswa[0] : 'S')),
                        title: Text(namaSiswa),
                        subtitle: Text("NISN: $nisnSiswa"),
                        trailing: IconButton(
                          icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                          onPressed: () => controller.inisialisasiSiswaDiKelas(namaSiswa, nisnSiswa),
                        ),
                      );
                    },
                  ));
          },
        ),
      ),
    );
  }

  Widget _buildDisabledSiswaList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 200,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                "Tentukan wali kelas terlebih dahulu untuk dapat menambahkan siswa.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}