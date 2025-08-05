// lib/app/modules/atur_pengganti/views/atur_pengganti_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../controllers/atur_pengganti_controller.dart';

class AturPenggantiView extends GetView<AturPenggantiController> {
  const AturPenggantiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Pengganti Halaqoh'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarHalaqohHariIni.isEmpty) {
          return const Center(child: Text("Tidak ada kelompok Halaqoh aktif."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: controller.daftarHalaqohHariIni.length,
          itemBuilder: (context, index) {
            final kelompok = controller.daftarHalaqohHariIni[index];
            final bool adaPengganti = kelompok['adaPengganti'] ?? false;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              // [VISUAL] Beri warna berbeda jika ada pengganti
              color: adaPengganti ? Colors.teal.shade50 : null, 
              child: ListTile(
                leading: CircleAvatar(child: Text(kelompok['fase'].substring(5))),
                title: Text("${kelompok['fase']} - ${kelompok['namaTempat']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                // [INFORMATIF] Tampilkan status pengganti
                subtitle: adaPengganti 
                  ? Text("Digantikan oleh: ${kelompok['namaPengganti']}", style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold))
                  : Text("Pengampu: ${kelompok['namaPengampuAsli']}"),
                // [VISUAL] Ubah ikon dan aksi berdasarkan status
                trailing: adaPengganti 
                  ? const Icon(Icons.person_remove_alt_1_outlined, color: Colors.redAccent)
                  : const Icon(Icons.person_add_alt_1_outlined, color: Colors.teal),
                onTap: () {
                  if (adaPengganti) {
                    controller.batalkanSesiPengganti(kelompok);
                  } else {
                    _showPilihPenggantiDialog(kelompok);
                  }
                },
              ),
            );
          },
        );
      }),
    );
  }

  void _showPilihPenggantiDialog(Map<String, dynamic> kelompok) {
    // [BARU] Buat state lokal untuk menampung guru yang dipilih sementara.
    final Rxn<Map<String, dynamic>> guruTerpilih = Rxn<Map<String, dynamic>>();

    Get.dialog(
      AlertDialog(
        title: Text("Pilih Pengganti untuk ${kelompok['namaPengampuAsli']}"),
        content: SizedBox(
          width: Get.width * 0.8,
          child: DropdownSearch<Map<String, dynamic>>(
            items: (f, cs) => controller.getAvailableGuruPengganti(kelompok['idPengampuAsli']),
            itemAsString: (item) => item['alias']!,
            compareFn: (item1, item2) => item1['uid'] == item2['uid'],
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: const TextFieldProps(decoration: InputDecoration(labelText: "Cari nama guru...")),
              emptyBuilder: (context, searchEntry) => const Center(child: Text("Tidak ada guru tersedia.")),
            ),
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(labelText: "Guru Pengganti"),
            ),
            // [DIUBAH] onChanged sekarang hanya mengisi state lokal.
            onChanged: (selected) {
              guruTerpilih.value = selected;
            },
          ),
        ),
        // [BARU] Tambahkan tombol Aksi untuk Batal dan Simpan.
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Batal"),
          ),
          // Bungkus dengan Obx agar bisa reaktif.
          Obx(() => ElevatedButton(
                // Tombol nonaktif sampai ada guru yang dipilih.
                onPressed: guruTerpilih.value == null
                    ? null
                    : () {
                        // Fungsi simpan dipanggil di sini setelah konfirmasi.
                        controller.simpanSesiPengganti(kelompok, guruTerpilih.value!);
                      },
                child: const Text("Simpan"),
              )),
        ],
      ),
    );
  }
}