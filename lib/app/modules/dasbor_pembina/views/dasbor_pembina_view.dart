// File: lib/app/modules/pembina_area/views/dasbor_pembina_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/dasbor_pembina_controller.dart';

class DasborPembinaView extends GetView<DasborPembinaController> {
  const DasborPembinaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dasbor Pembina Ekskul'),
        centerTitle: true,
      ),
      body: Obx(() {
        // Kita langsung memantau list yang ada di HomeController
        final ekskulList = controller.homeC.ekskulDiampuPengguna;

        if (ekskulList.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Anda tidak tercatat sebagai pembina di ekskul manapun pada tahun ajaran ini.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: ekskulList.length,
          itemBuilder: (context, index) {
            final ekskul = ekskulList[index];
            final String namaTampilan = ekskul['namaTampilan'] ?? 'Tanpa Nama';
            final String tahunAjaran = ekskul['idTahunAjaran'] ?? 'N/A';
            
            return Card(
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.stars)),
                title: Text(
                  namaTampilan,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Tahun Ajaran: $tahunAjaran"),
                trailing: const Icon(Icons.chevron_right),
                // onTap: () {
                //   // Aksi selanjutnya: Navigasi ke Halaman Detail Ekskul Pembina
                //   // Di sini kita akan masuk ke tugas Misi Delta berikutnya
                //   final String instanceEkskulId = ekskul['instanceEkskulId'];
                //   Get.snackbar(
                //     'Dalam Pengembangan',
                //     'Akan membuka detail untuk ekskul dengan ID: $instanceEkskulId',
                //   );
                // },

                onTap: () {
                    final String instanceEkskulId = ekskul['instanceEkskulId'];
                    final String namaEkskul = ekskul['namaTampilan'];
                    
                    // Navigasi ke halaman detail dengan mengirim argumen
                    Get.toNamed(
                      Routes.PEMBINA_EKSKUL_DETAIL,
                      arguments: {
                        'instanceEkskulId': instanceEkskulId,
                        'namaEkskul': namaEkskul,
                      },
                    );
                  },

              ),
            );
          },
        );
      }),
    );
  }
}