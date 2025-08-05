// lib/app/widgets/tandai_siap_ujian_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/siswa_halaqoh.dart';

// Interface sederhana untuk dependency injection
abstract class ITandaiSiapUjianController {
  RxBool get isDialogLoading;
  RxList<SiswaHalaqoh> get daftarSiswa;
  RxList<String> get santriTerpilihUntukUjian;
  Future<void> tandaiSiapUjianMassal();
  void toggleSantriSelectionForUjian(String nisn);
}

class TandaiSiapUjianSheet extends StatelessWidget {
  final ITandaiSiapUjianController controller;

  const TandaiSiapUjianSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    controller.santriTerpilihUntukUjian.clear();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 50, height: 5,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    "Pilih siswa untuk ditandai SIAP UJIAN. Level dan capaian akan diambil secara otomatis dari data terakhir mereka.",
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Obx(() => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.daftarSiswa.length,
                  itemBuilder: (ctx, index) {
                    final siswa = controller.daftarSiswa[index];
                    final status = siswa.statusUjian;
                    return Obx(() {
                      final isSelected = controller.santriTerpilihUntukUjian.contains(siswa.nisn);
                      return CheckboxListTile(
                        title: Text(siswa.namaSiswa),
                        subtitle: Text("Level: ${siswa.ummi} | Capaian: ${siswa.capaian.isEmpty ? '-' : siswa.capaian}"),
                        value: isSelected,
                        onChanged: (status == 'siap_ujian')
                            ? null
                            : (val) {
                                controller.toggleSantriSelectionForUjian(siswa.nisn);
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: theme.colorScheme.primary,
                      );
                    });
                  },
                )),
              ],
            ),
          ),
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isDialogLoading.value ? null : controller.tandaiSiapUjianMassal,
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(controller.isDialogLoading.value ? "Menyimpan..." : "Tandai Siap Ujian"),
            ),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}